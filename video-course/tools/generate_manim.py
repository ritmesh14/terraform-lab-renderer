#!/usr/bin/env python3
"""Render one MANIM scene asset from its authored spec (optional animation
layer — VIDEO-MAKING-PROCESS.md section 6).

Deterministic, spec-driven: the animation template and its data come from
<asset>.spec.json; the step beats come from MEASURED narration timing
(timing/timed-scenes.json step_frames — the audio is the timing authority).
The rendered clip fills exactly the scene's measured duration so the
Remotion sequence (the real clock) stays in sync.

Production usage (called by generate_assets.py):
  generate_manim.py <episode_dir> --scene S014

Standalone smoke test (no episode timing; even beat distribution — NEVER
use for publishing, the measured path is the only valid timing):
  generate_manim.py --spec assets/manim/x.spec.json --out assets/manim/x.mp4 \
      [--duration 12] [--fps 30] [--width 1920] [--height 1080]

Exit codes: 0 = rendered; 2 = manim/plan failure (caller engages the
validated non-Manim fallback — never silent, recorded in quality-check.json).
"""
import argparse
import glob
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
VC = os.path.dirname(HERE)
RENDER_CFG = os.path.join(VC, "config", "render.json")


def _manim_cfg():
    cfg = {}
    if os.path.isfile(RENDER_CFG):
        cfg = json.load(open(RENDER_CFG, encoding="utf-8")).get("manim", {})
    return {"fps": cfg.get("fps", 30),
            "width": cfg.get("resolution", {}).get("width", 1920),
            "height": cfg.get("resolution", {}).get("height", 1080)}


def build_plan(episode_dir, scene_id, spec=None, out=None, duration=None,
               fps=None, width=None, height=None):
    """Assemble the render plan: spec data + scene steps + measured timing."""
    mc = _manim_cfg()
    plan = {"scene_id": scene_id or "standalone", "fps": fps or mc["fps"],
            "width": width or mc["width"], "height": height or mc["height"],
            "total_sec": 0.0, "lead_in_sec": 0.4, "lead_out_sec": 0.6,
            "beats": [], "spec": {}}
    steps = []
    if episode_dir:
        ep = os.path.abspath(episode_dir)
        scenes = json.load(open(os.path.join(ep, "writing", "scenes.json"),
                                encoding="utf-8"))["scenes"]
        sc = next((s for s in scenes if s.get("id") == scene_id), None)
        if sc is None:
            raise SystemExit(f"scene {scene_id} not found in {ep}/writing/scenes.json")
        spec = spec or os.path.join(
            ep, *(os.path.splitext(sc.get("asset", ""))[0].split("/"))) + ".spec.json"
        out = out or os.path.join(ep, *sc.get("asset", "").split("/"))
        steps = sc.get("steps") or []
        timed_path = os.path.join(ep, "timing", "timed-scenes.json")
        if os.path.isfile(timed_path):
            ts = json.load(open(timed_path, encoding="utf-8"))
            plan["fps"] = ts.get("fps", plan["fps"])
            tsc = next((t for t in ts.get("scenes", [])
                        if t.get("id") == scene_id), None)
            if tsc is None:
                raise SystemExit(f"scene {scene_id} missing from timed-scenes.json "
                                 "— run the voice/measure stages first (audio is "
                                 "the timing authority)")
            plan["total_sec"] = tsc["total_frames"] / ts["fps"]
            sf = tsc.get("step_frames") or []
            for i, st in enumerate(steps):
                if i < len(sf):
                    plan["beats"].append({
                        "key": sf[i].get("key", f"{scene_id}.step{i+1}"),
                        "start": sf[i]["start"] / ts["fps"],
                        "end": sf[i]["end"] / ts["fps"],
                        "nodes": st.get("nodes", []),
                        "edges": st.get("edges", [])})
    else:
        steps = (spec and json.load(open(spec, encoding="utf-8")).get("steps")) or []
        plan["total_sec"] = duration or (2.0 + 4.0 * len(steps))

    if not plan["total_sec"]:
        raise SystemExit(f"scene {plan['scene_id']}: no measured duration — "
                         "run the voice/measure stages first")
    if not plan["beats"] and steps:
        # even distribution fallback (standalone smoke tests only)
        span = plan["total_sec"] - 1.0
        w = span / len(steps)
        for i, st in enumerate(steps):
            plan["beats"].append({"key": f"{plan['scene_id']}.step{i+1}",
                                   "start": 0.5 + i * w,
                                   "end": 0.5 + (i + 1) * w,
                                   "nodes": st.get("nodes", []),
                                   "edges": st.get("edges", [])})
    plan["spec"] = json.load(open(spec, encoding="utf-8"))
    plan["spec"].setdefault("steps", steps)
    return plan, os.path.abspath(spec), os.path.abspath(out or "manim-out.mp4")


def render(plan, spec, out):
    """Invoke the manim CLI on manim_templates.py:SpecScene with the plan."""
    for mod in ("manim",):
        if shutil.which(mod) is None and not importable(mod):
            raise RuntimeError(f"{mod} is not installed — fallback required")
    fd, plan_file = tempfile.mkstemp(suffix=".json",
                                     prefix="manim_plan_")
    os.close(fd)
    json.dump(plan, open(plan_file, "w", encoding="utf-8"), indent=1)
    media_dir = tempfile.mkdtemp(prefix="manim_media_")
    env = dict(os.environ, MANIM_PLAN=plan_file)
    cmd = [sys.executable, "-m", "manim", "render",
           "--fps", str(plan["fps"]),
           "-r", f"{plan['width']},{plan['height']}",
           "--format", "mp4", "--disable_caching", "--verbosity", "WARNING",
           "--progress_bar", "none",
           "-o", os.path.basename(out),
           "--media_dir", media_dir,
           os.path.join(HERE, "manim_templates.py"), "SpecScene"]
    try:
        # encoding pinned: manim emits UTF-8 (progress bars, box-drawing) and
        # the Windows default cp1252 reader crashes on it
        p = subprocess.run(cmd, env=env, capture_output=True,
                           encoding="utf-8", errors="replace")
        if p.returncode != 0:
            sys.stderr.write((p.stdout or "")[-4000:] + "\n"
                             + (p.stderr or "")[-4000:])
            raise RuntimeError(f"manim render failed (exit {p.returncode})")
        # manim also drops per-animation segments under partial_movie_files/
        # (0.4s each); sorted() puts them FIRST whenever the output basename
        # sorts after "partial..." (t*/v*/w*... — silently copied a 0.4s clip
        # instead of the full one). The deliverable never lives there.
        produced = [p for p in glob.glob(os.path.join(media_dir, "**", "*.mp4"),
                                         recursive=True)
                    if os.sep + "partial_movie_files" + os.sep not in p]
        if not produced:
            raise RuntimeError("manim reported success but produced no mp4")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        shutil.copyfile(produced[0], out)
        print(f"[manim] rendered {os.path.basename(out)} "
              f"({os.path.getsize(out)} bytes, "
              f"{plan['width']}x{plan['height']}@{plan['fps']}, "
              f"{plan['total_sec']:.2f}s, {len(plan['beats'])} beat(s))")
        return out
    finally:
        shutil.rmtree(media_dir, ignore_errors=True)
        try:
            os.remove(plan_file)
        except OSError:
            pass


def importable(mod):
    try:
        __import__(mod)
        return True
    except ImportError:
        return False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("episode_dir", nargs="?",
                    help="episode folder (production mode)")
    ap.add_argument("--scene", help="scene id, e.g. S014")
    ap.add_argument("--spec", help="spec json (standalone mode)")
    ap.add_argument("--out", help="output mp4 path (standalone mode)")
    ap.add_argument("--duration", type=float,
                    help="standalone smoke-test duration (seconds)")
    ap.add_argument("--fps", type=int)
    ap.add_argument("--width", type=int)
    ap.add_argument("--height", type=int)
    args = ap.parse_args()
    if args.episode_dir and not args.scene:
        sys.exit("production mode needs --scene Sxxx")
    if not args.episode_dir and not args.spec:
        sys.exit("standalone mode needs --spec")
    plan, spec, out = build_plan(args.episode_dir, args.scene, spec=args.spec,
                                 out=args.out, duration=args.duration,
                                 fps=args.fps, width=args.width,
                                 height=args.height)
    try:
        render(plan, spec, out)
    except RuntimeError as e:
        print(f"[manim] {e}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()