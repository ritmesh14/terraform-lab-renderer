#!/usr/bin/env python3
"""Two-part publishing deliverables (default pipeline output since 2026-09-24).

Called automatically by generate_course.py --mode render|all|ci after the
full-cut render; also usable standalone to re-split an existing episode:

  final/<lab-folder>-part1-main.mp4      (+ .srt)  everything before the outro
  final/<lab-folder>-part2-thankyou.mp4  (+ .srt)  centered outro, cues from 0

The real Azure demo is inserted manually between the two parts before
publishing. final/episode.mp4 + final/episode.srt stay as the archive full
cut. Split frame = the last scene's scene_start_frame in timed-scenes.json.
Filenames carry the lab number + folder name (e.g.
02-storage-account-part1-main.mp4).

Usage: render_parts.py <episode-dir>   (run AFTER the full episode.mp4 render)
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REMO_DIR = os.path.join(os.path.dirname(HERE), "remotion")


def npx_cmd(*npx_args):
    """Cross-platform npx invocation (Windows: npx is a .cmd shim)."""
    npx = shutil.which("npx")
    if npx and os.name == "nt":
        return ["cmd", "/c", os.path.abspath(npx), *npx_args]
    return ["npx", *npx_args]


# ---------------------------------------------------------------- SRT split

def parse_srt(path):
    txt = open(path, encoding="utf-8-sig").read().strip().replace("\r\n", "\n")
    cues = []
    for block in txt.split("\n\n"):
        lines = block.split("\n")
        if len(lines) < 2:
            continue
        m = re.match(r"(\d+):(\d+):(\d+)[,.](\d+) --> (\d+):(\d+):(\d+)[,.](\d+)",
                     lines[1])
        g = [int(x) for x in m.groups()]
        start = g[0] * 3600 + g[1] * 60 + g[2] + g[3] / 1000
        end = g[4] * 3600 + g[5] * 60 + g[6] + g[7] / 1000
        cues.append((start, end, "\n".join(lines[2:])))
    return cues


def fmt_ts(t):
    h = int(t // 3600); m = int(t % 3600 // 60); s = int(t % 60)
    ms = round((t - int(t)) * 1000)
    if ms == 1000:
        s += 1; ms = 0
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def write_srt(path, cues):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        for i, (a, b, txt) in enumerate(cues, 1):
            f.write(f"{i}\n{fmt_ts(a)} --> {fmt_ts(b)}\n{txt}\n\n")


# -------------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("episode_dir")
    args = ap.parse_args()
    # absolute everywhere: Remotion runs with cwd=remotion, so relative
    # --props/--frames output paths would resolve from the wrong directory
    ep = os.path.abspath(args.episode_dir)

    timed = json.load(open(os.path.join(ep, "timing", "timed-scenes.json"),
                           encoding="utf-8"))
    props_file = os.path.join(ep, "render-props.json")
    if not os.path.isfile(props_file):
        sys.exit("render-props.json not found — run the full render stage first")
    # render-props.json is the authority: the composition derives
    # durationInFrames from it, so its total may differ slightly from
    # timed-scenes.json (lead-out tail). Frame bounds must match the render.
    props = json.load(open(props_file, encoding="utf-8"))
    total = props["totalDurationFrames"]
    split = props["timedScenes"][-1]["scene_start_frame"]  # outro scene starts

    lab_folder = os.path.basename(os.path.normpath(ep))
    final_dir = os.path.join(ep, "final")
    targets = [
        (0, split - 1, os.path.join(final_dir, f"{lab_folder}-part1-main.mp4")),
        (split, total - 1, os.path.join(final_dir, f"{lab_folder}-part2-thankyou.mp4")),
    ]
    for lo, hi, out_mp4 in targets:
        print(f"[parts] rendering frames {lo}-{hi} -> {os.path.basename(out_mp4)}")
        p = subprocess.run(npx_cmd("remotion", "render", "Episode", out_mp4,
                                   f"--props={props_file}", f"--frames={lo}-{hi}"),
                           cwd=REMO_DIR)
        if p.returncode != 0:
            sys.exit(f"part render failed: {out_mp4}")

    # SRT split: part1 keeps cues ending before the outro; part2 shifts to 0
    srt_in = os.path.join(final_dir, "episode.srt")
    cues = parse_srt(srt_in)
    split_sec = split / timed["fps"]
    part1 = [c for c in cues if c[0] < split_sec and c[1] <= split_sec + 0.01]
    part2 = [(a - split_sec, b - split_sec, t) for a, b, t in cues if a >= split_sec - 0.01]
    write_srt(os.path.join(final_dir, f"{lab_folder}-part1-main.srt"), part1)
    write_srt(os.path.join(final_dir, f"{lab_folder}-part2-thankyou.srt"), part2)
    print(f"[parts] SRT split: {len(part1)} + {len(part2)} cues "
          f"(of {len(cues)}) at frame {split} ({split_sec:.2f}s)")


if __name__ == "__main__":
    main()