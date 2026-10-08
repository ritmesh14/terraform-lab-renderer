#!/usr/bin/env python3
"""Scene schema validation (instruction §30): writing/scenes.json must be
structurally sound BEFORE any TTS money/time is spent. Schema errors fail the
pipeline before TTS.

Per-visual-type rules (TITLE/CONCEPT/CODE/TERMINAL/DIAGRAM/RECAP/NEXT/PORTAL
plus the asset-less transform types ITERATION_EXPANSION/STATE_ADDRESS):
  - every scene: id, type, narration (or steps with narrations), audio
  - CODE: source_file/start_line/end_line (1 <= start <= end), asset, optional
    steps with active_lines within [start_line, end_line] and active_tokens
    that must each appear on one of the step's active_lines (token existence
    gate — a token that is not in the source must fail BEFORE TTS); tokens
    that are strict substrings of a sibling token in the same step produce a
    warning (highlight-ordering ambiguity)
  - ITERATION_EXPANSION / STATE_ADDRESS: stages with unique ids (items keyed),
    steps referencing existing stage/item keys, no `asset` (asset-less type)
  - DIAGRAM: asset + spec file on disk + steps referencing existing nodes/edges
  - TERMINAL: asset + spec fixture on disk; illustrative fixtures must be
    marked (terminal honesty, instruction §20)
  - NEXT: the fixed transition line, VERBATIM (instruction §41)
  - RECAP/CONCEPT: points list
  - every educational episode: RECAP + NEXT present; demo scenes must follow
    NEXT when demo content is promised (same-video demo gate — enforced for
    FINAL in validate_episode, WARNING here)

Writes validation/scene-schema.json; exit 1 on schema errors.

Usage: validate_scene_schema.py <episode-dir> [--sources <lab-dir>]
"""
import argparse
import json
import os
import re
import sys

VIDEO_COURSE_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FIXED_NEXT = ("Now that we understand how this Terraform configuration works, "
              "in the next part of this video, we'll move to a real-world demo "
              "and deploy it in Microsoft Azure.")
TYPES = {"TITLE", "CONCEPT", "CODE", "TERMINAL", "DIAGRAM", "RECAP", "NEXT",
         "PORTAL", "ITERATION_EXPANSION", "STATE_ADDRESS", "FOR_EACH_MAP",
         "DYNAMIC_BLOCK"}
# fragments assembled at runtime: the scanner must never trip on
# its own source when it scans the synced production source
LEAK_RE = re.compile("|".join((
    "E:" + chr(92) * 2, "C:" + chr(92) * 2,
    "/home/" + "runner/",
    chr(92) + chr(36) + "GITHUB_" + "WORKSPACE")))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("episode_dir")
    ap.add_argument("--sources", help="lab dir (for CODE asset existence checks)")
    args = ap.parse_args()
    ep = args.episode_dir
    result, fails = validate_scene_scenes(ep, sources=args.sources)
    print(json.dumps(result, indent=2))
    out = os.path.join(ep, "validation", "scene-schema.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump(result, open(out, "w", encoding="utf-8"), indent=2)
    print(f"-> {out}")
    sys.exit(1 if result["status"] == "fail" else 0)


def validate_scene_scenes(ep, sources=None):
    """Validate writing/scenes.json. Returns (result, fails) where result
    carries status/demo_gate/fails. DEMO-GATE entries are non-blocking
    pre-demo (demo capture needs a real Azure run); every other fail marks
    the episode unfit for TTS. Testable without CLI."""
    scenes_path = os.path.join(ep, "writing", "scenes.json")
    if not os.path.isfile(scenes_path):
        raise SystemExit(f"no writing/scenes.json at {ep}")
    doc = json.load(open(scenes_path, encoding="utf-8"))
    scenes = doc.get("scenes", [])
    result = _validate(scenes, ep, sources)
    return result, result["fails"]


def _validate(scenes, ep, sources=None):
    fails = []
    warns = []

    def check(cond, msg):
        if not cond:
            fails.append(msg)

    lab_dir = sources or os.path.join(ep, "..", "..", "..")
    ids = [s.get("id", "") for s in scenes]
    check(ids == [f"S{i:03d}" for i in range(1, len(scenes) + 1)],
          "scene ids must be sequential S001..S%03d" % len(scenes))

    demo_after_next = False
    seen_next = False
    for s in scenes:
        sid, typ = s.get("id"), str(s.get("type", "")).upper()
        check(typ in TYPES, f"{sid}: unknown visual_type '{typ}'")
        steps = s.get("steps") or []
        if steps:
            for i, st in enumerate(steps, 1):
                check(bool((st.get("narration") or "").strip()),
                      f"{sid}.step{i}: empty step narration")
        else:
            check(bool((s.get("narration") or "").strip()),
                  f"{sid}: empty narration")
        if typ == "CODE":
            check(bool(s.get("source_file")), f"{sid}: CODE missing source_file")
            st_, en = s.get("start_line", 0), s.get("end_line", 0)
            check(1 <= st_ <= en, f"{sid}: CODE line range {st_}-{en} invalid")
            check(bool(s.get("asset")), f"{sid}: CODE missing asset")
            for i, st in enumerate(steps, 1):
                for ln in st.get("active_lines", []):
                    check(st_ <= ln <= en,
                          f"{sid}.step{i}: active_lines {ln} outside "
                          f"[{st_},{en}]")
                check(isinstance(st.get("active_tokens", []), list),
                      f"{sid}.step{i}: active_tokens must be a list")
                # token existence gate: every token must occur on one of the
                # step's active lines (checked against the real source file)
                toks = [t for t in (st.get("active_tokens") or [])
                        if isinstance(t, str) and t]
                lns = [ln for ln in st.get("active_lines", [])
                       if isinstance(ln, int)]
                if toks and sources and s.get("source_file") and lns:
                    src_path = os.path.join(sources, s["source_file"])
                    if os.path.isfile(src_path):
                        src_lines = open(src_path, encoding="utf-8",
                                         errors="replace").read().splitlines()
                        blob = "\n".join(src_lines[ln - 1] for ln in lns
                                         if 1 <= ln <= len(src_lines))
                        for t in toks:
                            check(t in blob,
                                  f"{sid}.step{i}: active token '{t}' not found "
                                  f"on active line(s) {lns} of {s['source_file']}")
                        for t in toks:
                            for u in toks:
                                if t != u and t in u:
                                    warns.append(
                                        f"{sid}.step{i}: token '{t}' is a substring "
                                        f"of '{u}' — longer token wins the highlight")
        elif typ == "DIAGRAM":
            check(bool(s.get("asset")), f"{sid}: DIAGRAM missing asset")
            spec = os.path.join(ep, *(os.path.splitext(
                s.get("asset", ""))[0].split("/"))) + ".spec.json"
            node_ids, edge_ids = set(), set()
            if os.path.isfile(spec):
                specdoc = json.load(open(spec, encoding="utf-8"))
                node_ids = {n["id"] for n in specdoc.get("nodes", [])}
                edge_ids = {f"{e['from']}-{e['to']}"
                            for e in specdoc.get("edges", [])}
            else:
                fails.append(f"{sid}: DIAGRAM spec missing: {spec}")
            for i, st in enumerate(steps, 1):
                for n in st.get("nodes", []):
                    check(n in node_ids,
                          f"{sid}.step{i}: node '{n}' not in diagram spec")
                for e in st.get("edges", []):
                    check(any(e == f"{a}-{b}" for a in node_ids for b in node_ids),
                          f"{sid}.step{i}: edge '{e}' not in diagram spec")
        elif typ == "TERMINAL":
            check(bool(s.get("asset")), f"{sid}: TERMINAL missing asset")
            spec = os.path.join(ep, *(os.path.splitext(
                s.get("asset", ""))[0].split("/"))) + ".spec.json"
            check(os.path.isfile(spec),
                  f"{sid}: TERMINAL spec missing: {spec}")
            txt = spec.replace(".spec.json", ".txt")
            if os.path.isfile(txt):
                body = open(txt, encoding="utf-8", errors="replace").read()
                looks_real = not re.search(r"<guid>|<base64-key>|<redacted>|ILLUSTRATIVE",
                                           body)
                if looks_real and not spec.endswith("real"):
                    # honest-terminal rule: fixture output is illustrative and
                    # must say so (render_terminal_svg stamps the banner from
                    # the spec's "mode": "illustrative")
                    specdoc = json.load(open(spec, encoding="utf-8"))
                    check(specdoc.get("mode", "illustrative") == "illustrative",
                          f"{sid}: terminal fixture must declare "
                          f"'mode': 'illustrative' (never fabricate real output)")
                # TERMINAL_INTEGRITY_QC (§33.14): never fabricate unpredictable
                # runtime values — deterministic mock output must omit invented
                # creation durations ("Creation complete after 14s" etc.)
                invented = re.findall(
                    r"(?:after|in) \d+(?:\.\d+)?\s*(?:s\b|sec|seconds)", body)
                if invented:
                    fails.append(
                        f"{sid}: TERMINAL_INTEGRITY_QC — invented duration(s) "
                        f"{invented[:3]} in fixture; deterministic mocks must "
                        f"omit unpredictable timings (plan §33.14)")
        elif typ in ("ITERATION_EXPANSION", "STATE_ADDRESS", "FOR_EACH_MAP",
                 "DYNAMIC_BLOCK"):
            # asset-less transform types: the component renders the stages,
            # narration drives per-step focus (never a pre-rendered image)
            check(not s.get("asset"), f"{sid}: {typ} is asset-less — remove 'asset'")
            check(bool(steps), f"{sid}: {typ} requires steps (progression)")
            stages = s.get("stages") or []
            check(bool(stages), f"{sid}: {typ} missing stages")
            stage_ids = [st_.get("id") for st_ in stages]
            check(all(stage_ids) and len(set(stage_ids)) == len(stage_ids),
                  f"{sid}: {typ} stages need unique non-empty ids")
            item_ids = {it.get("key") for st_ in stages
                        for it in (st_.get("items") or []) if it.get("key")}
            # STATE_TERMINOLOGY_QC (§33.9/33.10): a splat `[*]` is an
            # EXPRESSION over the instances — it must never be listed inside
            # an address lane (kind 'addresses') or labeled as a state address
            for st_ in stages:
                if st_.get("kind") == "addresses":
                    for it in (st_.get("items") or []):
                        if "[*]" in str(it.get("text", "")):
                            fails.append(
                                f"{sid}: STATE_TERMINOLOGY_QC — splat "
                                f"'{it.get('text')}' listed under kind "
                                f"'addresses' (stage '{st_.get('id')}'); a splat "
                                f"is an expression, not a resource instance "
                                f"address (plan §33.9/33.10)")
            for i, st in enumerate(steps, 1):
                focus = st.get("focus") or {}
                for sg in focus.get("stages", []):
                    check(sg in stage_ids,
                          f"{sid}.step{i}: focus stage '{sg}' not in stages")
                for it in focus.get("items", []):
                    check(it in item_ids,
                          f"{sid}.step{i}: focus item '{it}' not in stage items")
        elif typ == "RECAP":
            check(bool(s.get("points")), f"{sid}: RECAP missing points")
        elif typ == "NEXT":
            check((s.get("narration") or "").strip() == FIXED_NEXT,
                  f"{sid}: NEXT must use the fixed transition line verbatim")
            seen_next = True
        if s.get("demo") and seen_next:
            demo_after_next = True
        # no internal paths anywhere in the scene definition (viewer-facing)
        blob = json.dumps(s, ensure_ascii=False)
        if LEAK_RE.search(blob):
            fails.append(f"{sid}: internal path leaked into scene definition")
        # GITHUB_URL_QC (§33.16): any github.com link on screen must be the
        # public course repo — never a foreign or internal URL
        for m in re.findall(r"https?://github\.com/[^\"'\s\\]+", blob):
            if not m.startswith(
                    "https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies"):
                fails.append(
                    f"{sid}: GITHUB_URL_QC — non-public-repo GitHub URL '{m}'")

    check(seen_next, "no NEXT scene — the real-world demo transition is missing")
    check(any(str(s.get("type")).upper() == "RECAP" for s in scenes),
          "no RECAP scene — every educational episode must end with one")
    if seen_next and not demo_after_next:
        # not a FAIL pre-demo (demo capture is a user Azure run), but every
        # downstream stage must know this episode cannot become FINAL yet
        fails.append("DEMO-GATE: NEXT transition present but no demo scenes "
                     "follow it — this episode cannot reach FINAL until demo "
                     "scenes (demo: true) are authored from real captured output")

    result = {"status": "fail" if [f for f in fails if not f.startswith("DEMO-GATE")]
              else "pass",
              "demo_gate": "pending" if any(f.startswith("DEMO-GATE") for f in fails)
              else ("pass" if seen_next else "n/a"),
              "warns": warns,
              "fails": fails}
    return result


if __name__ == "__main__":
    main()