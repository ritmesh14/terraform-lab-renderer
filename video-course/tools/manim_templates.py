#!/usr/bin/env python3
"""Reusable Manim Community Edition templates for the course animation layer.

Rendered ONLY through generate_manim.py (which bakes measured narration
timing into the render plan). Every template is SPEC-DRIVEN: mobjects are
built from the validated spec data (which itself must trace to the lab
inventory / source manifest) â€” no free-form animation code, no invented
infrastructure relationships, addresses, or resources.

Timing authority: the plan carries per-step windows derived from measured
step audio (timed-scenes.json step_frames). Visual MOVEMENT is timed to the
narration; narration speed is never changed to fit an animation. The clip
always fills exactly plan.total_sec so the Remotion sequence (which is the
real clock) stays in sync.

Templates (validate_scene_schema.py MANIM_TEMPLATES must stay in sync):
  resource_flow  nodes+edges dependency/flow build-up with per-step
                 highlighting (same step semantics as DIAGRAM scenes)
  packet_path    a request/packet dot travelling hop-to-hop per step
  cidr_subnets   an address-space bar subdivided into subnets, one per step

Style: restrained motion, static camera, dark course background, high-
contrast labels, gentle easing (default rate functions). Readable at normal
playback speed.
"""
import json
import os

from manim import (Scene, Text, RoundedRectangle, Arrow, Circle, Rectangle,
                   VGroup, SurroundingRectangle, Line, RIGHT, UP, DOWN, ORIGIN,
                   Create, Write, FadeOut)

PALETTE = {
    "bg": "#0B1120",       # course background (matches Remotion AbsoluteFill)
    "fg": "#E8EDF6",       # primary text
    "accent": "#4EC9B0",   # highlight (teal)
    "accent2": "#569CD6",  # secondary highlight (blue)
    "edge": "#7FA3C8",     # connectors
    "dim": "#3A4B66",      # dimmed elements
    "panel": "#141D2F",    # box fill
}


def _load_plan():
    path = os.environ.get("MANIM_PLAN")
    if not path:
        raise SystemExit("MANIM_PLAN env not set â€” render via generate_manim.py")
    with open(path, encoding="utf-8") as f:
        return json.load(f)


class SpecScene(Scene):
    """Dispatcher scene: one render = one plan = one template."""

    def construct(self):
        self.camera.background_color = PALETTE["bg"]
        plan = _load_plan()
        getattr(self, "tmpl_" + plan["spec"]["template"])(plan)

    # ------------------------------------------------------------- helpers
    def _title(self, text, scale=0.9):
        if not text:
            return None
        t = Text(str(text), font_size=44, color=PALETTE["fg"])
        t.scale_to_fit_width(16 * scale) if t.width > 16 * scale else None
        t.to_edge(UP, buff=0.55)
        return t

    def _clock_fill(self, plan, t):
        """Wait out whatever remains of the scene's measured duration."""
        tail = max(0.0, plan["total_sec"] - t)
        if tail > 0:
            self.wait(tail)
        return t + tail

    def _beats(self, plan):
        """Measured per-step windows (seconds) with their step payloads."""
        return plan.get("beats") or []

    # ------------------------------------------------------- resource_flow
    def tmpl_resource_flow(self, plan):
        spec, data = plan["spec"], plan["spec"].get("data", {})
        nodes, edges = data.get("nodes", []), data.get("edges", [])
        title = self._title(spec.get("title"))
        if title:
            self.play(Write(title), run_time=min(0.8, plan["lead_in_sec"]))
        t = title and min(0.8, plan["lead_in_sec"]) or 0.0

        # single-column chain for <=6 nodes (matches the canonical diagram
        # layout rule: chains read top-to-bottom); two columns beyond that
        n = len(nodes)
        cols = 1 if n <= 6 else 2
        rows = (n + cols - 1) // cols
        boxes = {}
        for i, nd in enumerate(nodes):
            col_i, row_i = (i % cols), (i // cols)
            body = RoundedRectangle(corner_radius=0.12, width=4.6, height=1.1,
                                   stroke_color=PALETTE["edge"],
                                   fill_color=PALETTE["panel"], fill_opacity=1.0)
            label = Text(str(nd.get("label", nd.get("id", ""))), font_size=26,
                         color=PALETTE["fg"])
            label.width = min(label.width, 4.0)
            grp = VGroup(body, label)
            grp.move_to(ORIGIN).shift(
                RIGHT * (col_i - (cols - 1) / 2.0) * 5.6
                + DOWN * (row_i - (rows - 1) / 2.0) * 1.85)
            boxes[nd["id"]] = grp
        arrows = {}
        for e in edges:
            key = f"{e['from']}-{e['to']}"
            if e["from"] in boxes and e["to"] in boxes:
                arrows[key] = Arrow(boxes[e["from"]].get_center(),
                                     boxes[e["to"]].get_center(), buff=0.95,
                                     stroke_color=PALETTE["edge"],
                                     stroke_width=3, max_tip_length_to_length_ratio=0.15)

        intro_rt = min(1.4, max(0.4, plan["lead_in_sec"] - t + 0.4))
        anims = ([Create(m) for m in boxes.values()]
                 + [Create(a) for a in arrows.values()])
        self.play(*anims, run_time=intro_rt)
        t += intro_rt

        for beat in self._beats(plan):
            wait = max(0.0, beat["start"] - t)
            if wait:
                self.wait(wait)
                t += wait
            hl, reset = [], []
            for nid in beat.get("nodes", []):
                if nid in boxes:
                    hl.append(boxes[nid])
            for eid in beat.get("edges", []):
                if eid in arrows:
                    hl.append(arrows[eid])
            if hl:
                glows = VGroup(*[SurroundingRectangle(m, color=PALETTE["accent"],
                                                       buff=0.12, corner_radius=0.12)
                                 for m in hl])
                self.play(Create(glows), run_time=0.45)
                t += 0.45
                hold = max(0.0, beat["end"] - t - 0.45)
                if hold:
                    self.wait(hold)
                    t += hold
                self.play(FadeOut(glows), run_time=0.3)
                t += 0.3
        self._clock_fill(plan, t)

    # -------------------------------------------------------- packet_path
    def tmpl_packet_path(self, plan):
        spec, data = plan["spec"], plan["spec"].get("data", {})
        hops = data.get("hops", [])
        title = self._title(spec.get("title"))
        if title:
            self.play(Write(title), run_time=min(0.8, plan["lead_in_sec"]))
        t = title and min(0.8, plan["lead_in_sec"]) or 0.0

        pads = {}
        m = len(hops)
        for i, h in enumerate(hops):
            pad = RoundedRectangle(corner_radius=0.6, width=2.9, height=2.9,
                                   stroke_color=PALETTE["edge"],
                                   fill_color=PALETTE["panel"], fill_opacity=1.0)
            label = Text(str(h.get("label", h.get("id", ""))), font_size=22,
                         color=PALETTE["fg"])
            label.width = min(label.width, 2.5)
            VGroup(pad, label).move_to(ORIGIN).shift(
                RIGHT * (i - (m - 1) / 2.0) * 3.9)
            pads[h["id"]] = VGroup(pad, label)
        links = [Line(pads[hops[i]["id"]].get_right(),
                      pads[hops[i + 1]["id"]].get_left(),
                      stroke_color=PALETTE["edge"], stroke_width=3)
                 for i in range(m - 1)]
        packet = Circle(radius=0.22, color=PALETTE["accent"],
                        fill_color=PALETTE["accent"], fill_opacity=1.0)
        if hops:
            packet.move_to(pads[hops[0]["id"]].get_center() + UP * 1.6)

        intro_rt = min(1.4, max(0.4, plan["lead_in_sec"] - t + 0.4))
        self.play(*[Create(p) for p in pads.values()]
                  + [Create(l) for l in links]
                  + [Create(packet)], run_time=intro_rt)
        t += intro_rt

        prev = hops[0]["id"] if hops else None
        for beat in self._beats(plan):
            wait = max(0.0, beat["start"] - t)
            if wait:
                self.wait(wait)
                t += wait
            targets = [n for n in beat.get("nodes", []) if n in pads]
            for target in targets:
                dur = max(0.4, min(1.6, beat["end"] - beat["start"]))
                path = Line(pads[prev].get_center() + UP * 1.6,
                             pads[target].get_center() + UP * 1.6) if prev else None
                if path:
                    self.play(packet.animate.move_to(
                        pads[target].get_center() + UP * 1.6), run_time=dur)
                    t += dur
                glow = SurroundingRectangle(pads[target], color=PALETTE["accent"],
                                            buff=0.14, corner_radius=0.14)
                self.play(Create(glow), run_time=0.3)
                t += 0.3
                prev = target
        self._clock_fill(plan, t)

    # ------------------------------------------------------- cidr_subnets
    def tmpl_cidr_subnets(self, plan):
        spec, data = plan["spec"], plan["spec"].get("data", {})
        subnets = data.get("subnets", [])
        title = self._title(spec.get("title"))
        if title:
            self.play(Write(title), run_time=min(0.8, plan["lead_in_sec"]))
        t = title and min(0.8, plan["lead_in_sec"]) or 0.0

        bar_w, m = 15.0, max(len(subnets), 1)
        block_w = bar_w / m
        blocks, labels = [], []
        for i, sn in enumerate(subnets):
            blk = Rectangle(width=block_w - 0.08, height=1.5,
                            stroke_color=PALETTE["edge"],
                            fill_color=PALETTE["panel"], fill_opacity=1.0)
            blk.move_to(ORIGIN).shift(RIGHT * (i - (m - 1) / 2.0) * block_w)
            name = Text(str(sn.get("name", "")), font_size=24, color=PALETTE["fg"])
            cidr = Text(str(sn.get("cidr", "")), font_size=22, color=PALETTE["accent2"])
            name.next_to(blk, UP, buff=0.18)
            cidr.next_to(blk, DOWN, buff=0.18)
            blocks.append(blk)
            labels += [name, cidr]

        intro_rt = min(1.2, max(0.4, plan["lead_in_sec"] - t + 0.4))
        self.play(*[Create(b) for b in blocks] + [Create(l) for l in labels],
                  run_time=intro_rt)
        t += intro_rt

        for beat in self._beats(plan):
            wait = max(0.0, beat["start"] - t)
            if wait:
                self.wait(wait)
                t += wait
            for n_ in beat.get("nodes", []):
                for i, sn in enumerate(subnets):
                    if sn.get("name") == n_:
                        glow = SurroundingRectangle(blocks[i],
                                                    color=PALETTE["accent"],
                                                    buff=0.1, corner_radius=0.1)
                        self.play(Create(glow),
                                  blocks[i].animate.set_fill(PALETTE["accent"],
                                                             opacity=0.25),
                                  run_time=0.4)
                        t += 0.4
                        hold = max(0.0, beat["end"] - t)
                        if hold:
                            self.wait(hold)
                            t += hold
                        self.play(FadeOut(glow),
                                  blocks[i].animate.set_fill(PALETTE["panel"],
                                                             opacity=1.0),
                                  run_time=0.3)
                        t += 0.3
        self._clock_fill(plan, t)