#!/usr/bin/env python3
"""Normalize every scene/step audio file with FFmpeg loudnorm (instruction §11).

Targets approximately -16 LUFS integrated / -1.5 dBTP true peak. Runs in place
(audio/S001.mp3 rewritten via a temp file) BEFORE measuring — the normalized
file is the timing authority:

    TTS -> normalize -> measure -> timing -> Remotion

Writes timing/normalization.json (per-file input/output loudness where ffmpeg
reports it). Idempotent: re-normalizing an already-normalized file is a no-op
within loudnorm tolerance.

Usage: normalize_audio.py <episode-dir>
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

_WINGET_FFMPEG = os.path.expandvars(
    r"%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget"
    r".Source_8wekyb3d8bbwe\ffmpeg-*-full_build\bin\ffmpeg.exe")

TARGET_I = -16.0    # LUFS integrated
TARGET_TP = -1.5    # dBTP true peak
TARGET_LRA = 11


def find_ffmpeg():
    found = shutil.which("ffmpeg")
    if not found and os.name == "nt":
        import glob
        hits = glob.glob(_WINGET_FFMPEG)
        found = hits[0] if hits else None
    return found


def measure_lufs(ffmpeg, path):
    """Integrated LUFS via ebur128 (None if unavailable)."""
    r = subprocess.run([ffmpeg, "-hide_banner", "-nostats", "-i", path,
                        "-af", "ebur128=framelog=quiet", "-f", "null", "-"],
                       capture_output=True, text=True)
    m = re.search(r"I:\s*(-?[\d.]+)\s*LUFS", r.stderr)
    return float(m.group(1)) if m else None


def normalize(ffmpeg, path):
    """loudnorm one-pass rewrite in place; returns (in_lufs, out_lufs)."""
    in_lufs = measure_lufs(ffmpeg, path)
    tmp = path + ".norm.mp3"
    r = subprocess.run(
        [ffmpeg, "-y", "-i", path,
         "-af", f"loudnorm=I={TARGET_I}:TP={TARGET_TP}:LRA={TARGET_LRA}",
         "-ar", "44100", "-b:a", "128k", tmp],
        capture_output=True, text=True)
    if r.returncode != 0 or not os.path.isfile(tmp) or os.path.getsize(tmp) == 0:
        sys.exit(f"loudnorm failed for {path}: {r.stderr.strip()[-400:]}")
    os.replace(tmp, path)
    out_lufs = measure_lufs(ffmpeg, path)
    return in_lufs, out_lufs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("episode_dir")
    args = ap.parse_args()
    ffmpeg = find_ffmpeg()
    if not ffmpeg:
        sys.exit("ffmpeg not found (PATH and winget install).")

    scenes = json.load(open(os.path.join(args.episode_dir, "writing", "scenes.json"),
                            encoding="utf-8"))["scenes"]
    audio_dir = os.path.join(args.episode_dir, "audio")
    report, touched = {}, 0
    for s in scenes:
        targets = [s.get("audio")] + list(s.get("step_audio", []))
        for rel in targets:
            if not rel:
                continue
            p = os.path.join(args.episode_dir, rel)
            if not os.path.isfile(p):
                continue  # missing audio is measure_audio.py's error to raise
            in_l, out_l = normalize(ffmpeg, p)
            report[rel.replace("\\", "/")] = {
                "input_lufs": in_l, "output_lufs": out_l,
                "target_lufs": TARGET_I, "target_dbtp": TARGET_TP}
            touched += 1
            print(f"  {rel}: {in_l if in_l is not None else '?'} -> "
                  f"{out_l if out_l is not None else '?'} LUFS")
    os.makedirs(os.path.join(args.episode_dir, "timing"), exist_ok=True)
    out = os.path.join(args.episode_dir, "timing", "normalization.json")
    json.dump({"ffmpeg_loudnorm": {"I": TARGET_I, "TP": TARGET_TP, "LRA": TARGET_LRA},
               "files": report},
              open(out, "w", encoding="utf-8"), indent=2)
    print(f"-> {out} ({touched} file(s) normalized to ~{TARGET_I} LUFS)")


if __name__ == "__main__":
    main()