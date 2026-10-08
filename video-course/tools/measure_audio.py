#!/usr/bin/env python3
"""Measure per-scene audio durations with ffprobe -> timing/audio-durations.json.

Usage: measure_audio.py <episode-dir>
Requires ffprobe on PATH (comes with ffmpeg).
"""
import argparse
import glob
import json
import os
import shutil
import subprocess
import sys

_WINGET_FFMPEG_BIN = os.path.expandvars(
    r"%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget"
    r".Source_8wekyb3d8bbwe\ffmpeg-*-full_build\bin")


def _ffprobe():
    """PATH first, then (Windows only) the winget ffmpeg install (not always on PATH)."""
    found = shutil.which("ffprobe")
    if found or os.name != "nt":
        return found
    hits = glob.glob(os.path.join(_WINGET_FFMPEG_BIN, "ffprobe.exe"))
    return hits[0] if hits else None


def probe(path):
    p = subprocess.run(
        [_ffprobe(), "-v", "quiet", "-print_format", "json", "-show_format", path],
        capture_output=True, text=True)
    if p.returncode != 0:
        return None
    return float(json.loads(p.stdout)["format"]["duration"])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("episode_dir")
    args = ap.parse_args()

    if _ffprobe() is None:
        sys.exit("ffprobe not found (PATH and winget install).")

    ep = args.episode_dir
    scenes = json.load(open(os.path.join(ep, "writing", "scenes.json"),
                            encoding="utf-8"))["scenes"]
    durations, missing, bad = {}, [], []
    for s in scenes:
        audio = os.path.join(ep, s.get("audio", ""))
        if not os.path.isfile(audio):
            missing.append(s["id"])
            continue
        dur = probe(audio)
        if dur is None or dur <= 0:
            bad.append(s["id"])   # corrupt / zero-duration audio
            continue
        durations[s["id"]] = round(dur, 3)
        # step audios (narration-synced diagram scenes) measured individually —
        # the per-step durations drive the highlight-change frames in Remotion
        for k in s.get("step_audio", []):
            spath = os.path.join(ep, k)
            if not os.path.isfile(spath):
                missing.append(k)
                continue
            sdur = probe(spath)
            if sdur is None or sdur <= 0:
                bad.append(k)
                continue
            key = k.split("/")[-1].rsplit(".", 1)[0]  # audio/S009.step1.mp3 -> S009.step1
            durations[key] = round(sdur, 3)

    os.makedirs(os.path.join(ep, "timing"), exist_ok=True)
    out = os.path.join(ep, "timing", "audio-durations.json")
    json.dump({"durations_sec": durations, "missing_audio": missing,
               "invalid_audio": bad},
              open(out, "w", encoding="utf-8"), indent=2)
    print(f"-> {out}")
    if missing:
        print(f"WARNING: no audio for scenes: {', '.join(missing)}")
        sys.exit(1)
    if bad:
        print(f"ERROR: corrupt/zero-duration audio: {', '.join(bad)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
