#!/usr/bin/env python3
"""Build an Azure-architecture diagram as SVG.

Two input modes:
  --mermaid file.mmd   -> rendered via mermaid-cli (npx @mermaid-js/mermaid-cli)
  --json spec.json     -> built-in layered boxes+arrows SVG
                          { "nodes": [{"id","label","group"}...],
                            "edges": [{"from","to","label"?}...],
                            "layers": [["id"...], ...] }  # optional explicit columns

Diagram rules (course-wide; §20B global connector routing + endpoint validation):
  - Every node/edge gets a stable id (`node-<id>`, `edge-<from>-<to>`) PLUS
    stable identity attributes `data-from` / `data-to` on every edge group —
    Remotion resolves highlights from attributes, never by splitting ids.
  - NODE ANCHORS: every edge connects real anchor points.  Same-column edges
    use bottom->top centers; same-row edges use right->left centers; edges
    whose source and destination rows differ are routed as orthogonal elbows
    (H-V-H) instead of a horizontal line at an averaged Y (the historical
    floating-arrow defect).  Elbow branch x is staggered per edge so sibling
    verticals never overlap.
  - ARROW TIPS END EXACTLY ON the destination node border (marker refX puts
    the tip at the line end), never short of it and never inside the box.
  - EDGE LABELS are positioned from the FINAL routed geometry using a
    candidate ladder (above first segment / below or above final segment /
    beside the vertical segment); labels never default blindly to the middle.
  - NO diagram is written while any collision remains: the tool iterates a
    deterministic repair loop (widen gaps -> shift labels -> reroute) before
    failing. If unresolved it prints the offending boxes and exits 3 (gate).
  - Collision checks cover: label vs node, label vs label, label vs connector
    line, label vs arrowhead, node vs node, and viewBox overflow.  Connector
    vs connector overlaps are permitted (shared bus / perpendicular crossing
    are valid technical-diagram patterns).
  - ENDPOINT QC (hard gate): after layout, the generated SVG is re-parsed and
    every edge is verified geometrically — start touches the source border,
    end touches the DECLARED destination border, arrowhead attached, final
    segment points into the destination, no segment crosses an unrelated
    node, and every coordinate stays inside the canvas.  Any failure exits 3.
"""
import argparse
import html
import json
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
VIDEO_COURSE_ROOT = os.path.dirname(HERE)  # tools/ -> video-course/
THEME_CFG = os.path.join(VIDEO_COURSE_ROOT, "config", "theme.json")

FONT_SIZE = 26
CHAR_W = 15          # conservative px per char at FONT_SIZE (label width estimate)
LABEL_H = 34         # label bounding-box height
BOX_H = 110
MIN_GAP = 200        # minimum horizontal gap between columns (room for arrows)
LABEL_PAD = 24       # min px between a label and anything else
LINE_LABEL_LIFT = 18  # label baseline above the connector line
MAX_ATTEMPTS = 5      # bounded repair attempts before FAIL
TIP_CLEAR = 0        # arrow tip sits exactly ON the destination border
BRANCH_BASE = 48     # first elbow branch x offset from the source right edge
BRANCH_STEP = 26     # stagger between sibling elbows (keeps verticals apart)
ENDPOINT_TOL = 2     # geometric endpoint tolerance (px); marker geometry only


def est_w(text):
    return max(len(line) for line in text.split("\n")) * CHAR_W


def rects_overlap(a, b):
    return not (a[0] + a[2] <= b[0] or b[0] + b[2] <= a[0] or
                a[1] + a[3] <= b[1] or b[1] + b[3] <= a[1])


def mermaid_to_svg(mmd, out):
    subprocess.run(["npx", "-y", "@mermaid-js/mermaid-cli", "-i", mmd,
                    "-o", out, "-b", "transparent"], check=True)
    print(f"-> {out} (mermaid-cli)")


def need_gap(label):
    """Horizontal gap required between two columns for this edge label."""
    if not label:
        return MIN_GAP
    return max(MIN_GAP, est_w(label) + 2 * LABEL_PAD + 32)


def render_layout(spec, theme, scale=1.0, label_dy=None):
    """One deterministic layout attempt. Returns (parts, boxes, edges_meta,
    size) or raises CollisionError. label_dy: {edge-id: vertical offset}."""
    label_dy = label_dy or {}
    nodes = {n["id"]: n for n in spec["nodes"]}
    pos = naive_layout(spec)
    cols = max(c for c, r in pos.values()) + 1
    rows = max(r for c, r in pos.values()) + 1
    azure, tf_blue = theme["azure"]["primary"], theme["azure"]["secondary"]

    gap_y = 100
    col_w = [MIN_GAP] * cols
    for n in spec["nodes"]:
        c, _ = pos[n["id"]]
        col_w[c] = max(col_w[c], est_w(n["label"]) + 56)
    # per-pair column gaps scaled by the repair loop
    pair_gap = {}
    for e in spec.get("edges", []):
        (c1, _), (c2, _) = pos[e["from"]], pos[e["to"]]
        if c2 - c1 != 1:
            continue
        pair_gap[c1] = max(pair_gap.get(c1, MIN_GAP), need_gap(e.get("label", "")))
    col_x = []
    x = 80
    for c in range(cols):
        col_x.append(x)
        x += col_w[c] + pair_gap.get(c, MIN_GAP) * scale
    w = x - pair_gap.get(cols - 1, 0) + 40
    h = 60 + rows * (BOX_H + gap_y) + 20

    def xy(nid):
        c, r = pos[nid]
        return (col_x[c], 60 + r * (BOX_H + gap_y))

    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}">',
             f'<rect width="{w}" height="{h}" fill="{theme["background"]}"/>',
             '<defs><marker id="arr" markerWidth="10" markerHeight="10" refX="9" refY="3" '
             'orient="auto"><path d="M0,0 L9,3 L0,6 z" fill="#50E6FF"/></marker></defs>',
             f'<g font-family="{theme["body"]["font"]}, sans-serif" font-size="{FONT_SIZE}">']

    boxes = []          # (x, y, w, h, kind, name)
    for n in spec["nodes"]:
        nx, ny = xy(n["id"])
        boxes.append((nx, ny, col_w[pos[n["id"]][0]], BOX_H, "node", n["id"]))

    # §20B routing: stagger elbow branch x per edge within a column pair so
    # sibling vertical segments never overlap (separate routed connectors)
    elbow_seen = {}
    # §20B distributed anchors: every cross-column edge terminates on the
    # destination's LEFT border; when several edges share that border their
    # endpoints spread along it so arrowheads never overlap and final
    # approach segments never run collinear on top of each other
    left_groups = {}
    for i, e in enumerate(spec.get("edges", [])):
        (c1, _), (c2, _) = pos[e["from"]], pos[e["to"]]
        if c1 != c2:
            left_groups.setdefault(e["to"], []).append(i)

    def anchor_ty(i, e, sy_default):
        """Distributed left-border anchor y for a cross-column edge."""
        (c1, _), (c2, r2) = pos[e["from"]], pos[e["to"]]
        ty = 60 + r2 * (BOX_H + gap_y) + BOX_H // 2
        grp = left_groups.get(e["to"], [])
        if c1 != c2 and len(grp) > 1:
            spacing = BOX_H / (len(grp) + 1)
            ty = ty + (grp.index(i) - (len(grp) - 1) / 2) * spacing
        return ty

    # §20B branch budget: every elbow in a column pair gets its OWN branch x
    # (never reused) so a sibling's vertical can never seal the corridor a
    # label needs; the step compresses adaptively when a pair has many elbows
    elbow_counts = {}
    for i, e in enumerate(spec.get("edges", [])):
        (c1, _), (c2, _) = pos[e["from"]], pos[e["to"]]
        if c1 != c2:
            sy0 = xy(e["from"])[1] + BOX_H // 2
            if abs(anchor_ty(i, e, sy0) - sy0) >= 0.5:
                elbow_counts[(c1, c2)] = elbow_counts.get((c1, c2), 0) + 1
    branch_step = {}
    for (c1, c2), n in elbow_counts.items():
        avail = (col_x[c2] - 24) - (col_x[c1] + col_w[c1] + BRANCH_BASE)
        branch_step[(c1, c2)] = min(BRANCH_STEP, max(12, avail / max(n - 1, 1)))
    edges_geo = []      # per-edge routing geometry + rendered connector svg

    for i, e in enumerate(spec.get("edges", [])):
        (c1, r1), (c2, r2) = pos[e["from"]], pos[e["to"]]
        x1, y1 = xy(e["from"]); x2, y2 = xy(e["to"])
        w1 = col_w[c1]
        eid = f"{e['from']}-{e['to']}"
        sy = y1 + BOX_H // 2                    # source right-anchor center y
        ty = anchor_ty(i, e, sy)                # destination left-anchor y
        seg, line_boxes = [], []
        if c1 == c2:
            # same column: vertical arrow between the anchors. Downward flow
            # leaves the source's bottom border and enters the destination's
            # top; upward flow (serpentine columns) mirrors it — source top
            # border, destination bottom border — so the arrowhead always
            # ENTERS the box interior (§20B direction QC).
            lx = x1 + w1 // 2
            if r2 >= r1:
                y_start, y_end = y1 + BOX_H, y2 + TIP_CLEAR
            else:
                y_start, y_end = y1, y2 + BOX_H - TIP_CLEAR
            seg.append(f'<line x1="{lx}" y1="{y_start}" '
                       f'x2="{lx}" y2="{y_end}" '
                       f'stroke="#50E6FF" stroke-width="3" marker-end="url(#arr)"/>')
            line_boxes.append((lx - 2, min(y_start, y_end), 4,
                               abs(y_end - y_start), f"line:{eid}"))
            geo = dict(eid=eid, e=e, kind="v", lx=lx, v0=y_start, v1=y_end)
        elif abs(ty - sy) < 0.5:
            # same row / single left-anchor user: straight horizontal arrow,
            # right anchor -> left anchor, tip exactly on the border
            sx, ex = x1 + w1, x2 + TIP_CLEAR
            seg.append(f'<line x1="{sx}" y1="{sy}" x2="{ex}" y2="{sy}" '
                       f'stroke="#50E6FF" stroke-width="3" marker-end="url(#arr)"/>')
            line_boxes.append((sx, sy - 2, max(ex - sx, 4), 4, f"line:{eid}"))
            geo = dict(eid=eid, e=e, kind="h", sx=sx, ex=ex, ly=sy)
        else:
            # different rows (or distributed anchor): orthogonal elbow — out
            # of the source's right anchor, branch, vertical to the assigned
            # destination anchor y, into the destination's left border
            sx = x1 + w1
            ex = x2 + TIP_CLEAR
            idx = elbow_seen.get((c1, c2), 0)
            elbow_seen[(c1, c2)] = idx + 1
            bx = sx + BRANCH_BASE + branch_step[(c1, c2)] * idx
            bx = min(bx, ex - 24)
            seg.append(f'<path d="M{sx},{sy} L{bx},{sy} L{bx},{ty} L{ex},{ty}" '
                       f'fill="none" stroke="#50E6FF" stroke-width="3" '
                       f'marker-end="url(#arr)"/>')
            line_boxes.append((sx, sy - 2, max(bx - sx, 4), 4, f"line:{eid}"))
            line_boxes.append((bx - 2, min(sy, ty), 4, max(abs(ty - sy), 4), f"line:{eid}"))
            line_boxes.append((bx, ty - 2, max(ex - bx, 4), 4, f"line:{eid}"))
            geo = dict(eid=eid, e=e, kind="elbow", hseg1=(sx, bx, sy),
                       hseg2=(bx, ex, ty), vseg=(bx, sy, ty))
        geo["seg"] = seg
        geo["line_boxes"] = line_boxes
        edges_geo.append(geo)

    # §20B edge-label placement (pass 2): every label picks the FIRST
    # collision-free candidate from the FINAL routed geometry, tested against
    # every node box, every connector segment and every earlier label.
    # Edges sharing a destination stack their slots (alternating below/above)
    # so fan-in labels never fight for the same approach position.
    all_line_boxes = [lb for g in edges_geo for lb in g["line_boxes"]]
    dest_idx = {}
    label_parts = {g["eid"]: "" for g in edges_geo}
    placed_label_boxes = []
    for g in edges_geo:
        e, eid = g["e"], g["eid"]
        if not e.get("label"):
            continue
        lw = est_w(e["label"])
        # distributed destination anchors already give fan-in edges distinct
        # approach heights, so labels only need the repair ladder's dy here
        dy = label_dy.get(eid, 0)
        cands = []          # (tx, baseline_y, anchor)
        if g["kind"] == "h":
            mid = (g["sx"] + g["ex"]) // 2
            cands += [(mid, g["ly"] - LINE_LABEL_LIFT + dy, "middle"),
                      (mid, g["ly"] + LABEL_H + 10 + dy, "middle")]
        elif g["kind"] == "v":
            vy = (g["v0"] + g["v1"]) // 2 + 8 + dy
            cands += [(g["lx"] + 18, vy, "start"), (g["lx"] - 18, vy, "end")]
        else:
            s1, s2, vv = g["hseg1"], g["hseg2"], g["vseg"]
            if s2[1] - s2[0] >= lw + 2 * LABEL_PAD:
                cands += [((s2[0] + s2[1]) // 2, s2[2] - LINE_LABEL_LIFT + dy, "middle"),
                          ((s2[0] + s2[1]) // 2, s2[2] + LABEL_H + 10 + dy, "middle")]
            if s1[1] - s1[0] >= lw + 2 * LABEL_PAD:
                cands.append(((s1[0] + s1[1]) // 2, s1[2] - LINE_LABEL_LIFT + dy, "middle"))
            # right-aligned slots on both horizontal segments: parallel
            # fan-in elbows leave only a narrow corridor around the vertical,
            # so a label often only fits tucked against the branch point
            cands += [(s1[1] - 6, s1[2] - LINE_LABEL_LIFT + dy, "end"),
                      (s1[1] - 6, s1[2] + LABEL_H + 10 + dy, "end"),
                      (s2[1] - 6, s2[2] - LINE_LABEL_LIFT + dy, "end"),
                      (s2[1] - 6, s2[2] + LABEL_H + 10 + dy, "end")]
            vy = (vv[1] + vv[2]) // 2 + 8 + dy
            cands += [(vv[0] + 18, vy, "start"), (vv[0] - 18, vy, "end")]

        def label_box(tx, tyy, anchor):
            bxx = tx if anchor == "start" else (tx - lw if anchor == "end"
                                                else tx - lw // 2)
            return (bxx, tyy - LABEL_H + 10, lw, LABEL_H, "label", f"edge:{eid}")

        obstacles = boxes + all_line_boxes + placed_label_boxes
        chosen = None
        for tx, tyy, anchor in cands:
            lb = label_box(tx, tyy, anchor)
            if not any(rects_overlap(lb[:4], o[:4]) for o in obstacles):
                chosen = lb
                label_parts[eid] = (
                    f'<text x="{tx}" y="{tyy}" fill="#9BD1FF" '
                    f'text-anchor="{anchor}">{html.escape(e["label"])}</text>')
                break
        if chosen is None and cands:
            # nothing fits: park on the first candidate so the collision
            # detector reports it and the repair ladder widens the gaps
            tx, tyy, anchor = cands[0]
            chosen = label_box(tx, tyy, anchor)
            label_parts[eid] = (
                f'<text x="{tx}" y="{tyy}" fill="#9BD1FF" '
                f'text-anchor="{anchor}">{html.escape(e["label"])}</text>')
        if chosen:
            boxes.append(chosen)
            placed_label_boxes.append(chosen)

    for g in edges_geo:
        boxes.extend((lb[0], lb[1], lb[2], lb[3], "line", lb[4])
                     for lb in g["line_boxes"])
    edge_parts = [
        f'<g id="edge-{g["eid"]}" data-from="{g["e"]["from"]}" '
        f'data-to="{g["e"]["to"]}">' + "".join(g["seg"]) + label_parts[g["eid"]]
        + "</g>" for g in edges_geo]
    edges_meta = [g["eid"] for g in edges_geo]

    node_parts = []
    for n in spec["nodes"]:
        nx, ny = xy(n["id"])
        cw = col_w[pos[n["id"]][0]]
        color = azure if n.get("group") != "terraform" else theme["terraform"]["primary"]
        lines = n["label"].split("\n")
        lh = 34
        y0 = ny + BOX_H // 2 - (len(lines) - 1) * lh // 2 + 9
        tspans = "".join(
            f'<tspan x="{nx + cw // 2}" y="{y0 + i * lh}">{html.escape(ln)}</tspan>'
            for i, ln in enumerate(lines))
        node_parts.append(
            f'<g id="node-{n["id"]}" data-id="{n["id"]}">'
            f'<rect x="{nx}" y="{ny}" width="{cw}" height="{BOX_H}" rx="14" '
            f'fill="{color}" fill-opacity="0.15" stroke="{color}" stroke-width="2.5"/>'
            f'<text fill="#E8EEFA" text-anchor="middle">{tspans}</text></g>')

    return (parts[:4] + edge_parts + node_parts + ["</g></svg>"], boxes,
            edges_meta, (w, h))


def naive_layout(spec):
    """Assign (col, row) positions from explicit layers or simple BFS order."""
    spec = serpentine_rebalance(spec)
    if spec.get("layers"):
        return {nid: (c, r) for c, col in enumerate(spec["layers"])
                for r, nid in enumerate(col)}
    return {n["id"]: (0, i) for i, n in enumerate(spec["nodes"])}


# 16:9 frame budget (test-render finding 2026-09-26, S014): a single column of
# more than MAX_ROWS_PER_COL nodes makes the canvas tall+narrow, and DiagramScene's
# contain-fit then shrinks every label below readability (a 6-node chain rendered
# at 0.58x). Long linear chains auto-flow into serpentine columns — col 1
# top->bottom, col 2 bottom->top, ... — so consecutive nodes stay adjacent:
# chain edges become same-column verticals (adjacent rows, nothing crossed) or
# same-row horizontals between neighboring columns. Multi-layer specs already
# spread horizontally and are left untouched.
MAX_ROWS_PER_COL = 3


def serpentine_rebalance(spec):
    layers = spec.get("layers")
    if not layers or len(layers) != 1 or len(layers[0]) <= MAX_ROWS_PER_COL:
        return spec
    chain = list(layers[0])
    cols, i, forward = [], 0, True
    while i < len(chain):
        chunk = chain[i:i + MAX_ROWS_PER_COL]
        cols.append(chunk if forward else list(reversed(chunk)))
        forward = not forward
        i += MAX_ROWS_PER_COL
    spec = dict(spec)
    spec["layers"] = cols
    return spec


def collisions_of(boxes, w, h):
    """All current collisions: box vs box (nodes/labels/lines/arrowheads) +
    viewBox overflow.  Connector-vs-connector overlaps are NOT collisions
    (shared merge buses and perpendicular crossings are valid patterns) —
    every other pair still is.  Arrowheads sit at line ends (inside the line
    bbox)."""
    bad = []
    for i in range(len(boxes)):
        for j in range(i + 1, len(boxes)):
            bi, bj = boxes[i], boxes[j]
            if bi[4] == "line" and bj[4] == "line":
                continue
            if rects_overlap(bi[:4], bj[:4]):
                bad.append(f"{bi[4]}:{bi[5]}  <->  {bj[4]}:{bj[5]}")
    for b in boxes:
        if b[0] < 0 or b[1] < 0 or b[0] + b[2] > w or b[1] + b[3] > h:
            bad.append(f"overflow: {b[4]}:{b[5]} beyond {w}x{h}")
    return bad


# ---------------------------------------------------------------------------
# §20B endpoint QC: re-parse the generated SVG and verify the RENDERED graph
# against the DECLARED graph geometrically.
# ---------------------------------------------------------------------------

def _on_border(px, py, rect, tol):
    x, y, w, h = rect
    if (abs(px - x) <= tol or abs(px - (x + w)) <= tol) and y - tol <= py <= y + h + tol:
        return True
    if (abs(py - y) <= tol or abs(py - (y + h)) <= tol) and x - tol <= px <= x + w + tol:
        return True
    return False


def _seg_rect_hit(p, q, rect, pad=2):
    """True if segment p-q intersects rect (inflated by pad)."""
    x, y, w, h = rect[0] - pad, rect[1] - pad, rect[2] + 2 * pad, rect[3] + 2 * pad
    # endpoints strictly inside?
    for px, py in (p, q):
        if x < px < x + w and y < py < y + h:
            return True
    def seg_hit(a, b, c, d):
        def ccw(A, B, C):
            return (C[1] - A[1]) * (B[0] - A[0]) > (B[1] - A[1]) * (C[0] - A[0])
        return ccw(a, c, d) != ccw(b, c, d) and ccw(a, b, c) != ccw(a, b, d)
    corners = [(x, y), (x + w, y), (x + w, y + h), (x, y + h)]
    for i in range(4):
        if seg_hit(p, q, corners[i], corners[(i + 1) % 4]):
            return True
    return False


def qc_svg(svg_text, spec):
    """Geometric endpoint/direction/identity/obstruction/boundary QC.
    Returns a list of failure strings (empty = PASS)."""
    fails = []
    nodes = {n["id"] for n in spec["nodes"]}
    rects = {}
    for m in re.finditer(
            r'<g id="node-([^"]+)" data-id="[^"]+">'
            r'<rect x="([-\d.]+)" y="([-\d.]+)" width="([\d.]+)" height="([\d.]+)"',
            svg_text):
        rects[m.group(1)] = (float(m.group(2)), float(m.group(3)),
                             float(m.group(4)), float(m.group(5)))
    canvas = re.search(r'<svg[^>]*width="([\d.]+)" height="([\d.]+)"', svg_text)
    cw, ch = (float(canvas.group(1)), float(canvas.group(2))) if canvas else (0, 0)

    for m in re.finditer(r'<g id="edge-([^"]+)" data-from="([^"]+)" data-to="([^"]+)">'
                         r'(.*?)</g>', svg_text, re.S):
        eid, src, dst, body = m.groups()
        pts = []
        for lm in re.finditer(r'<line x1="([-\d.]+)" y1="([-\d.]+)" '
                              r'x2="([-\d.]+)" y2="([-\d.]+)"', body):
            pts = [(float(lm.group(1)), float(lm.group(2))),
                   (float(lm.group(3)), float(lm.group(4)))]
        pm = re.search(r'<path d="M([-\d.,]+)((?:\s*L[-\d.,]+)+)"', body)
        if pm:
            raw = "M" + pm.group(1) + pm.group(2)
            pairs = re.findall(r'([-\d.]+),([-\d.]+)', raw)
            pts = [(float(a), float(b)) for a, b in pairs]
        if len(pts) < 2:
            fails.append(f"{eid}: no rendered connector geometry")
            continue
        if 'marker-end="url(#arr)"' not in body:
            fails.append(f"{eid}: connector has no arrowhead")
        for name, pt in (("source", pts[0]), ("destination", pts[-1])):
            if name == "source" and src not in rects:
                fails.append(f"{eid}: source node {src} missing"); continue
            if name == "destination" and dst not in rects:
                fails.append(f"{eid}: destination node {dst} missing"); continue
        if src in rects and not _on_border(pts[0][0], pts[0][1], rects[src], ENDPOINT_TOL):
            fails.append(f"{eid}: start {pts[0]} not on source {src} border")
        if dst in rects and not _on_border(pts[-1][0], pts[-1][1], rects[dst], ENDPOINT_TOL):
            fails.append(f"{eid}: FLOATING END — end {pts[-1]} not on destination "
                         f"{dst} border")
        # final segment must point INTO the destination
        if dst in rects and len(pts) >= 2:
            (ax, ay), (bx_, by_) = pts[-2], pts[-1]
            dx, dyv = bx_ - ax, by_ - ay
            rx, ry, rw, rh = rects[dst]
            if abs(bx_ - rx) <= ENDPOINT_TOL and dx <= 0:
                fails.append(f"{eid}: arrowhead on left border but not entering "
                             f"(dx={dx})")
            elif abs(bx_ - (rx + rw)) <= ENDPOINT_TOL and dx >= 0:
                fails.append(f"{eid}: arrowhead on right border but not entering "
                             f"(dx={dx})")
            elif abs(by_ - ry) <= ENDPOINT_TOL and dyv <= 0:
                fails.append(f"{eid}: arrowhead on top border but not entering "
                             f"(dy={dyv})")
            elif abs(by_ - (ry + rh)) <= ENDPOINT_TOL and dyv >= 0:
                fails.append(f"{eid}: arrowhead on bottom border but not entering "
                             f"(dy={dyv})")
        # no segment may cross an unrelated node
        for i in range(len(pts) - 1):
            for nid, rect in rects.items():
                if nid in (src, dst):
                    continue
                if _seg_rect_hit(pts[i], pts[i + 1], rect):
                    fails.append(f"{eid}: segment {i} crosses unrelated node {nid}")
        # canvas boundary
        for px, py in pts:
            if px < 0 or py < 0 or px > cw or py > ch:
                fails.append(f"{eid}: point ({px},{py}) outside canvas {cw}x{ch}")
    return fails


def json_to_svg(spec_path, out, theme):
    """Layout -> measure -> repair (bounded attempts) -> endpoint QC -> write;
    exit 3 only if unresolved (§15/§20B)."""
    spec = json.load(open(spec_path, encoding="utf-8"))

    scale = 1.0
    label_dy = {}
    for attempt in range(MAX_ATTEMPTS):
        parts, boxes, edges_meta, (w, h) = render_layout(spec, theme, scale, label_dy)
        bad = collisions_of(boxes, w, h)
        if not bad:
            break
        # deterministic repair ladder: 1) shift colliding edge labels, 2) widen
        # column gaps; retry until clean or attempts exhausted
        collided = [c for c in bad if c.split(":")[0].split(" ")[0] == "label"]
        if collided and attempt < MAX_ATTEMPTS - 2:
            for c in collided:
                eid = c.split("edge:")[1].split()[0]
                label_dy[eid] = label_dy.get(eid, 0) + (LABEL_H + 12) * \
                    (1 if attempt % 2 == 0 else -1)
        else:
            scale = round(scale + 0.2, 2)  # widen every pair gap
            label_dy = {}
        print(f"  [diagram] collision repair attempt {attempt + 1}: "
              f"{len(bad)} conflict(s) — adjusting")
    else:
        print("DIAGRAM QC FAILED — unresolved collision after repair attempts:")
        for c in bad:
            print("   ", c)
        sys.exit(3)

    svg_text = "".join(parts)
    endpoint_fails = qc_svg(svg_text, spec)
    if endpoint_fails:
        print("DIAGRAM QC FAILED — connector endpoint validation (§20B):")
        for f in endpoint_fails:
            print("   ", f)
        sys.exit(3)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    open(out, "w", encoding="utf-8").write(svg_text)
    print(f"-> {out} (collision + endpoint QC passed after {attempt + 1} attempt(s))")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mermaid"); ap.add_argument("--json")
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--theme", default=THEME_CFG)
    args = ap.parse_args()
    if args.mermaid:
        mermaid_to_svg(args.mermaid, args.out)
    elif args.json:
        json_to_svg(args.json, args.out, json.load(open(args.theme, encoding="utf-8")))
    else:
        sys.exit("pass --mermaid or --json")


if __name__ == "__main__":
    main()