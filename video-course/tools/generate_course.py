#!/usr/bin/env python3
"""Course orchestrator CLI (batch + per-episode driver).

    generate_course.py --source-root <source-root> --mode scripts [--lab 01]
    generate_course.py --lab 05 --mode voice|subtitles|render|validate
    generate_course.py --lab 01 --mode all
    generate_course.py --lab 01 --mode render --renderer local   # fallback only

Modes
  scripts    PASS A only: resolve lab -> manifest -> inventory -> episode dirs +
             progress skeleton. Script writing itself is agent work;
             this stage prepares each episode and REPORTS what remains.
  validate   scene schema + terraform sandbox gate (fmt/init/validate, never
             deploys) + the four content gates on episodes with writing/
  voice      PASS B: generate_voice.py (Edge TTS canonical default; MiniMax
             optional only) -> audio/ + timing/word-timing/
  subtitles  SRT for VOICE_COMPLETE episodes: normalize -> measure -> frames ->
             multi-cue SRT -> coverage gate (>= 99.5%)
  render     Remotion render + quality_check for RENDERED-pending episodes
             (--renderer local is the fallback path; production is cloud).
             Produces the TWO-PART publishing deliverables: part1-main and
             part2-thankyou MP4s (+ separate SRTs), lab-number+name filenames;
             episode.mp4/episode.srt stay as the archive full cut.
  all        every deterministic stage for one lab, in order, stopping at gates
  ci         deterministic media pipeline for GitHub Actions: assumes approved
             writing/ + demo inputs already exist (synced from the authoring
             PC); runs every stage from manifest/inventory rebuild through
             render + QC. No LLM call. Exits nonzero if any stage fails.

Status machine (one-way): DRAFT -> VALIDATED -> APPROVED -> VOICE_COMPLETE ->
MEDIA_READY -> RENDERED -> FINAL. FINAL requires all four gates + same-video
demo scenes; legacy episodes are tagged legacy_pipeline/needs_revalidation.
Every render produces the two-part publishing deliverables via render_parts.py
inside stage_render (part1-main + part2-thankyou, each with its own SRT);
episode.mp4 stays as the archive full cut. The real-world demo recording is
inserted manually between the parts before publishing.

Lab resolution: shared tools/course_index.py (prefix -> manifest -> ordered
discovery; never guesses). Every stage is restartable; FINAL episodes are
skipped unless --force.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from course_index import episode_dir, load_course_manifest, resolve_lab  # noqa: E402
from status_machine import (get_status, load_progress, save_progress,  # noqa: E402
                            set_status, max_of)

# Portable roots: this file lives in <video-course>/tools, so derive the
# video-course root from __file__ (works on Windows AND the CI runner, where
# the source root is the CI workspace/labs — a different tree from tools).
TOOLS = os.path.dirname(os.path.abspath(__file__))
VC = os.path.dirname(TOOLS)
PROGRESS = os.path.join(VC, "course-progress.json")
COURSE_CFG = os.path.join(VC, "config", "course.json")
REMO_DIR = os.path.join(VC, "remotion")

STATUSES = ["DRAFT", "VALIDATED", "APPROVED", "VOICE_COMPLETE",
            "MEDIA_READY", "RENDERED", "FINAL"]


def run(script, *script_args):
    p = subprocess.run([sys.executable, os.path.join(TOOLS, script), *script_args])
    if p.returncode != 0:
        raise SystemExit(f"stage failed: {script} {' '.join(str(a) for a in script_args)}")


def npx_cmd(*npx_args):
    """Cross-platform npx invocation. Windows: npx is a .cmd shim CreateProcess
    can't exec directly; on Linux (GitHub Actions runner) plain npx works."""
    npx = shutil.which("npx")
    if npx and os.name == "nt":
        return ["cmd", "/c", os.path.abspath(npx), *npx_args]
    return ["npx", *npx_args]


def stage_scripts(ep, out_dir):
    os.makedirs(os.path.join(out_dir, "source"), exist_ok=True)
    for sub in ("writing", "audio", "timing", "validation", "captions",
                "final", "preview", "demo"):
        os.makedirs(os.path.join(out_dir, sub), exist_ok=True)
    for sub in ("diagrams", "code", "terminal", "portal", "screenshots"):
        os.makedirs(os.path.join(out_dir, "assets", sub), exist_ok=True)
    manifest_out = os.path.join(out_dir, "source", "source-manifest.json")
    if not os.path.isfile(manifest_out):
        run("build_manifest.py", ep["abs_path"], "--out", manifest_out)
    else:
        with open(manifest_out, encoding="utf-8") as f:
            stale = "files" not in json.load(f)  # legacy pre-refactor schema
        if stale:
            run("build_manifest.py", ep["abs_path"], "--out", manifest_out)
    inv_out = os.path.join(out_dir, "source", "terraform-inventory.json")
    if not os.path.isfile(inv_out):
        run("parse_terraform.py", ep["abs_path"], "--out", inv_out)
    print(f"[scripts] prepared {ep['path']}; AGENT STEP: write script.md / "
          f"scenes.json / narration.json (+ scene steps + demo scenes) in "
          f"{out_dir}\\writing from manifest + inventory, then run mode=validate")


def refresh_manifest(ep, out_dir):
    """Rebuild source-manifest.json when it predates the current schema
    (legacy episodes lack the 'files' list) — validation depends on it."""
    manifest_out = os.path.join(out_dir, "source", "source-manifest.json")
    if not os.path.isfile(manifest_out):
        run("build_manifest.py", ep["abs_path"], "--out", manifest_out)
        return
    with open(manifest_out, encoding="utf-8") as f:
        if "files" not in json.load(f):
            run("build_manifest.py", ep["abs_path"], "--out", manifest_out)


def stage_validate(ep, out_dir):
    # 0. manifest freshness (legacy episodes carry the old schema)
    refresh_manifest(ep, out_dir)
    # 1. scene schema gate — fails BEFORE any TTS (instruction §30)
    run("validate_scene_schema.py", out_dir, "--sources", ep["abs_path"])
    # 2. deterministic terraform gate (outranks LLM judgment): sandbox
    #    fmt/init/validate — never deployed, never mutates the real lab
    tfv_out = os.path.join(out_dir, "validation", "terraform-validate.json")
    sandbox = os.path.join(out_dir, "validation", "sandbox")
    if os.path.isdir(sandbox):
        shutil.rmtree(sandbox)
    shutil.copytree(ep["abs_path"], sandbox,
                    ignore=shutil.ignore_patterns(".terraform*", "*.tfstate*"))
    p = subprocess.run([sys.executable, os.path.join(TOOLS, "validate_terraform.py"),
                        sandbox, "--out", tfv_out])
    if p.returncode == 1:
        raise SystemExit(f"{ep['path']}: terraform validation FAILED in sandbox "
                         "(see validation/terraform-validate.json)")
    if p.returncode == 2:
        print(f"WARNING: {ep['path']}: terraform binary unavailable — "
              "deterministic terraform validation skipped")
    # 3. the four content gates
    p = subprocess.run([sys.executable, os.path.join(TOOLS, "validate_episode.py"),
                        out_dir, "--sources", ep["abs_path"]])
    if p.returncode != 0:
        raise SystemExit(f"{ep['path']}: content validation FAILED — repair script first")


def stage_voice(ep, out_dir, provider="config"):
    voice = json.load(open(os.path.join(VC, "config", "voice.json"), encoding="utf-8"))
    if provider == "minimax" and voice["voice_id"].startswith("TODO"):
        raise SystemExit("Set the male voice_id in video-course/config/voice.json "
                         "first (one-time manual selection).")
    run("generate_voice.py", out_dir, "--provider", provider)
    run("normalize_audio.py", out_dir)  # normalized audio is the timing authority


def stage_subtitles(ep, out_dir):
    run("measure_audio.py", out_dir)
    run("align_audio.py", out_dir)  # degrades to scene-level without whisperx
    run("calculate_scene_frames.py", out_dir)
    run("generate_srt.py", out_dir)  # includes the SRT coverage gate


def stage_render(ep, out_dir, force=False):
    cur = get_status_global(ep)
    if cur in ("RENDERED", "FINAL") and not force:
        raise SystemExit(f"{ep['path']}: already {cur} — FINAL/RENDERED episodes "
                         "are never auto-regenerated (use --force explicitly)")
    # regenerate every scene asset from its spec (Shiki code, diagrams,
    # terminal SVGs) — assets are not synced/committed
    run("generate_assets.py", out_dir, ep["abs_path"])
    out_mp4 = os.path.join(out_dir, "final", "episode.mp4")
    timed_scene_path = os.path.join(out_dir, "timing", "timed-scenes.json")
    timed_doc = json.load(open(timed_scene_path, encoding="utf-8"))
    scenes_doc = json.load(open(os.path.join(out_dir, "writing", "scenes.json"),
                                encoding="utf-8"))
    # Remotion's staticFile() only serves remotion/public — mirror the
    # episode's runtime assets (audio + assets/) there for the bundler.
    slug = f"{ep['section']}--{ep['lab']}"
    pub_ep = os.path.join(REMO_DIR, "public", "episodes", slug)
    if os.path.isdir(pub_ep):
        shutil.rmtree(pub_ep)
    os.makedirs(pub_ep, exist_ok=True)
    for sub in ("audio", "assets"):
        src_sub = os.path.join(out_dir, sub)
        if os.path.isdir(src_sub):
            shutil.copytree(src_sub, os.path.join(pub_ep, sub))
    props = {
        "episodeDir": f"episodes/{slug}",
        "publicLabUrl": ep["public_lab_url"],
        "title": scenes_doc.get("title") or ep["lab"],
        "lessonLabel": scenes_doc.get("lesson_label") or ep["section"],
        "timedScenes": timed_doc["scenes"],
        "scenes": scenes_doc["scenes"],
        "totalDurationFrames": timed_doc["total_duration_frames"],
    }
    props_file = os.path.join(out_dir, "render-props.json")
    json.dump(props, open(props_file, "w", encoding="utf-8"), indent=2)
    render_cfg = json.load(open(os.path.join(VC, "config", "render.json"),
                                encoding="utf-8"))
    crf = str(render_cfg.get("crf", 18))
    p = subprocess.run(npx_cmd("remotion", "render", "Episode", out_mp4,
                               f"--props={props_file}", f"--crf={crf}"),
                       cwd=REMO_DIR)
    if p.returncode != 0:
        raise SystemExit(f"{ep['path']}: remotion render failed")
    run("quality_check.py", out_dir)
    run("generate_srt.py", out_dir)  # final SRT from actual audio (+coverage gate)
    run("qc_frames.py", out_dir)     # export preview/qc-frames for visual QC
    run("render_parts.py", out_dir)  # TWO-PART publishing deliverables (part1-main + part2-thankyou, +SRTs)
    set_status(PR, PROGRESS, ep, "RENDERED")


# status plumbing: PR is module-global for the run (set in main)
PR = None


def get_status_global(ep):
    return get_status(PR, ep)


def main():
    global PR
    ap = argparse.ArgumentParser()
    ap.add_argument("--source-root", default=os.environ.get("COURSE_SOURCE_ROOT") or os.getcwd())
    ap.add_argument("--mode", required=True,
                    choices=["scripts", "validate", "voice", "subtitles",
                             "render", "all", "ci"])
    ap.add_argument("--lab", help="e.g. 01, 17, 26, or all (default for batch modes)")
    ap.add_argument("--section", help="scope --lab resolution to one section, "
                                      "e.g. section-02-meta-arguments")
    ap.add_argument("--force", action="store_true", help="allow touching FINAL episodes")
    ap.add_argument("--provider", choices=["config", "edge", "minimax"], default="config",
                    help="voice provider override (edge is the free default)")
    ap.add_argument("--renderer", choices=["local", "github"], default="local",
                    help="render target for --mode render: local = this machine "
                         "(fallback/debug), github = delegate to cloud_render.py")
    args = ap.parse_args()

    course_cfg = json.load(open(COURSE_CFG, encoding="utf-8"))
    labs = load_course_manifest(args.source_root, rebuild=(args.mode == "ci"))
    targets = resolve_lab(args.lab, labs, section=args.section)
    PR = load_progress(PROGRESS)
    report = {"labs": len(targets), "done": 0, "skipped_final": 0,
              "renderer": args.renderer, "failed": []}

    if args.renderer == "github" and args.mode == "render":
        sys.path.insert(0, TOOLS)
        import cloud_render
        for ep in targets:
            print(f"[cloud] dispatching {ep['path']} to GitHub Actions...")
            run_id = cloud_render.trigger(ep, args.source_root, section=args.section)
            print(f"[cloud] run id: {run_id}")
        report["done"] = len(targets)
        print(json.dumps(report, indent=2))
        return

    for ep in targets:
        out_dir = episode_dir(ep, VC)
        status = get_status(PR, ep)
        if status == "FINAL" and not args.force:
            report["skipped_final"] += 1
            continue
        try:
            if args.mode in ("scripts", "all", "ci"):
                stage_scripts(ep, out_dir)
                # never downgrade an episode that already progressed (§41)
                if status == "DRAFT":
                    set_status(PR, PROGRESS, ep, "DRAFT",
                               public_lab_url=ep["public_lab_url"])
            if args.mode in ("validate", "all", "ci"):
                scenes = os.path.join(out_dir, "writing", "scenes.json")
                if not os.path.isfile(scenes):
                    raise SystemExit(f"{ep['path']}: no writing/scenes.json — "
                                     "script stage (agent work) not done")
                stage_validate(ep, out_dir)
                # never downgrade an episode that already advanced (§41)
                set_status(PR, PROGRESS, ep,
                           max_of(get_status(PR, ep), "VALIDATED"))
            if args.mode in ("voice", "all", "ci"):
                cur = get_status(PR, ep)  # re-read: mode=all advanced it earlier
                if cur in ("VOICE_COMPLETE", "MEDIA_READY", "RENDERED", "FINAL") \
                        and not args.force:
                    raise SystemExit(f"{ep['path']}: voice already complete (status={cur}) "
                                     "— use --force to regenerate")
                if cur not in ("VALIDATED", "APPROVED") and not args.force:
                    raise SystemExit(f"{ep['path']}: narration allowed only for VALIDATED "
                                     f"episodes (status={cur}) — a CI dispatch or explicit "
                                     "--force overrides this for regeneration")
                stage_voice(ep, out_dir, args.provider)
                set_status(PR, PROGRESS, ep,
                           max_of(get_status(PR, ep), "VOICE_COMPLETE"))
            if args.mode in ("subtitles", "all", "ci"):
                cur = get_status(PR, ep)  # re-read: mode=all advanced it above
                if cur not in ("VOICE_COMPLETE", "MEDIA_READY", "RENDERED"):
                    raise SystemExit(f"{ep['path']}: subtitles need VOICE_COMPLETE audio "
                                     f"(status={cur})")
                stage_subtitles(ep, out_dir)
                set_status(PR, PROGRESS, ep,
                           max_of(get_status(PR, ep), "MEDIA_READY"))
            if args.mode in ("render", "all", "ci"):
                stage_render(ep, out_dir, force=args.force)
            report["done"] += 1
        except SystemExit as e:
            report["failed"].append({"lab": ep["path"], "error": str(e)})
            if args.mode != "all":
                raise

    print(json.dumps(report, indent=2))
    if args.mode == "ci" and report["failed"]:
        sys.exit(1)  # CI job must fail, not just report


if __name__ == "__main__":
    main()