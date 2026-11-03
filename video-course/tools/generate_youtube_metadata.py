#!/usr/bin/env python3
"""YouTube metadata generator (chapters + description) for course episodes.

Emits, per episode, two paste-ready files into final/:
  <folder>-chapters.txt      YouTube chapter list (00:00 first, >=10s each,
                             action-describing names — not "Part 1")
  <folder>-description.txt   full video description: hook line, chapters,
                             public lab URL, course repo link, demo note,
                             hashtags

Timings come from timing/timed-scenes.json (the audio-derived authority —
never pre-assigned), restricted to Part 1 (frames before the outro split,
which is where viewers watch the lesson). Chapter names come from the
authored writing/scenes.json (caption/heading/label) with type-based
fallbacks so every episode works without per-episode curation.

Chapter rules (YouTube requirements): first stamp must be 00:00; every
chapter >= 10 seconds; names describe the action/content of the section.

Standalone:
  python generate_youtube_metadata.py --lab NN --section <section>
  python generate_youtube_metadata.py --lab all
"""
import argparse
import glob
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from course_index import (episode_dir, load_course_manifest,  # noqa: E402
                          public_lab_url, resolve_lab)

REPO_URL = "https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies"
HASHTAGS = "#terraform #azure #infrastructureascode #devops #cloudcomputing"


def _load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def chapter_name(scene, ep):
    """Descriptive chapter name for a scene, authored fields first."""
    for key in ("caption", "heading", "label", "title"):
        v = scene.get(key)
        if isinstance(v, str) and v.strip():
            v = " ".join(v.split())
            return "Thanks for watching" if "thanks" in v.lower() else v
    t = scene.get("type")
    if t == "CODE":
        return f"Code: {scene.get('source_file', 'the configuration')}"
    if t == "TERMINAL":
        asset = (scene.get("asset") or "").lower()
        if "apply" in asset:
            return "Running terraform apply"
        if "output" in asset or "state" in asset:
            return "Reading the state and outputs"
        return "Running terraform plan"
    if t == "MANIM":
        # authored clip title lives in the manim spec next to the asset
        spec = os.path.join(ep, os.path.splitext(scene.get("asset", ""))[0]
                           + ".spec.json")
        if os.path.isfile(spec):
            try:
                return _load(spec).get("title") or "How the deployment unfolds"
            except (OSError, ValueError):
                pass
        return "How the deployment unfolds"
    if t == "NEXT":
        return "Next: real-world demo"
    if t == "RECAP":
        return "Recap"
    if t == "CONCEPT":
        return "Overview"
    return "Lesson"


def fmt_ts(sec):
    sec = int(round(sec))
    m, s = divmod(sec, 60)
    h, m = divmod(m, 60)
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"


def generate_for_episode(ep, lab_rec):
    ts = os.path.join(ep, "timing", "timed-scenes.json")
    sc = os.path.join(ep, "writing", "scenes.json")
    fin = os.path.join(ep, "final")
    if not (os.path.isfile(ts) and os.path.isfile(sc) and os.path.isdir(fin)):
        return False
    timed = _load(ts)
    scenes = {s["id"]: s for s in _load(sc)["scenes"]}
    fps = timed.get("fps", 30)

    # part 1 = everything before the outro (split = LAST scene's start)
    part1 = timed["scenes"][:-1]
    # a chapter must run >= 10s; first must be 00:00 Introduction
    chapters = []
    for i, t in enumerate(part1):
        sec = t["scene_start_frame"] / fps
        dur = t["duration_sec"] + (t.get("lead_out_frames", 0) / fps)
        nxt = part1[i + 1]["scene_start_frame"] / fps if i + 1 < len(part1) else None
        span = (nxt - sec) if nxt is not None else t["total_frames"] / fps
        if span < 10 and chapters:
            continue  # too short for its own chapter (YouTube minimum)
        name = chapter_name(scenes.get(t["id"], {}), ep)
        if chapters and chapters[-1][1] == name:
            continue  # merge consecutive same-named sections
        chapters.append((sec, name))
    if not chapters or chapters[0][0] > 0.5:
        chapters.insert(0, (0, "Introduction"))

    folder = os.path.basename(ep)
    chap_file = os.path.join(fin, f"{folder}-chapters.txt")
    with open(chap_file, "w", encoding="utf-8") as f:
        for sec, name in chapters:
            f.write(f"{fmt_ts(sec)} {name}\n")

    lab_url = lab_rec.get("public_lab_url") or public_lab_url(lab_rec)
    label = lab_rec.get("lab", folder)
    desc = [
        f"{lab_rec.get('title', label)} — Terraform on Azure, hands-on lab.",
        "",
        "In this lesson we walk the complete Terraform configuration for "
        f"this lab, line by line, then see how the pieces connect and how "
        "Terraform orders the deployment.",
        "",
        "Chapters:",
    ]
    desc += [f"{fmt_ts(sec)} {name}" for sec, name in chapters]
    desc += [
        "",
        f"Lab files: {lab_url}",
        f"Full course repository: {REPO_URL}",
        "",
        "Right after this lesson, a real-world demo deploys this exact "
        "configuration in Microsoft Azure.",
        "",
        HASHTAGS,
    ]
    desc_file = os.path.join(fin, f"{folder}-description.txt")
    with open(desc_file, "w", encoding="utf-8") as f:
        f.write("\n".join(desc) + "\n")
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lab", required=True, help="lab number or 'all'")
    ap.add_argument("--section", help="scope ambiguous numeric refs")
    ap.add_argument("--source-root",
                    default=os.environ.get("COURSE_SOURCE_ROOT") or os.getcwd())
    args = ap.parse_args()

    labs = load_course_manifest(args.source_root)
    refs = labs if args.lab in (None, "all") else resolve_lab(
        args.lab, labs, section=args.section)
    if not isinstance(refs, list):
        refs = [refs]
    done = skipped = 0
    for rec in refs:
        ep = episode_dir(rec)
        try:
            if generate_for_episode(ep, rec):
                done += 1
                print(f"[meta] {rec['lab']}: chapters + description written")
            else:
                skipped += 1
        except (OSError, ValueError, KeyError) as e:
            skipped += 1
            print(f"[meta] {rec['lab']}: SKIPPED ({e})")
    print(f"[meta] done={done} skipped={skipped}")


if __name__ == "__main__":
    main()