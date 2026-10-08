#!/usr/bin/env python3
"""Visual-QC frame export (instruction §33): deterministic build never depends
on a cloud model, but representative frames are exported for the optional
multimodal visual QC pass (text clipping, code readability, overlaps,
highlight visibility).

Exports to preview/qc-frames/:
  - first + middle frame of every scene
  - every step-transition frame (step_frames windows)
  - final frame of the episode

Usage: qc_frames.py <episode-dir>
"""
import argparse
import json
import os
import shutil
import subprocess
import sys

_WINGET_FFMPEG = os.path.expandvars(
    r"%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget"
    r".Source_8wekyb3d8bbwe\ffmpeg-*-full_build\bin\ffmpeg.exe")


def find_ffmpeg():
    found = shutil.which("ffmpeg")
    if not found and os.name == "nt":
        import glob
        hits = glob.glob(_WINGET_FFMPEG)
        found = hits[0] if hits else None
    return found


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("episode_dir")
    args = ap.parse_args()
    ep = args.episode_dir
    ffmpeg = find_ffmpeg()
    if not ffmpeg:
        sys.exit("ffmpeg not found — cannot export QC frames.")

    mp4 = os.path.join(ep, "final", "episode.mp4")
    if not os.path.isfile(mp4):
        sys.exit(f"no final/episode.mp4 at {ep} — render first")
    timed = json.load(open(os.path.join(ep, "timing", "timed-scenes.json"),
                           encoding="utf-8"))
    fps = timed["fps"]
    out_dir = os.path.join(ep, "preview", "qc-frames")
    os.makedirs(out_dir, exist_ok=True)

    def grab(frame, name):
        out = os.path.join(out_dir, f"{name}.png")
        subprocess.run([ffmpeg, "-y", "-loglevel", "error",
                        "-ss", str(frame / fps), "-i", mp4,
                        "-frames:v", "1", out], capture_output=True)

    n = 0
    for t in timed["scenes"]:
        sid = t["id"]
        start, total = t["scene_start_frame"], t["total_frames"]
        grab(start, f"{sid}-first")
        grab(start + total // 2, f"{sid}-middle")
        for sf in t.get("step_frames", []):
            grab(start + sf["start"], f"{sid}-{sf['key']}-stepstart")
        grab(start + total - 1, f"{sid}-last")
        n += 4 + len(t.get("step_frames", []))
    grab(max(0, timed["total_duration_frames"] - 1), "final-frame")
    print(f"-> {out_dir} ({n + 1} frames)")


if __name__ == "__main__":
    main()