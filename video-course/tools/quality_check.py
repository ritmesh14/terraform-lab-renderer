#!/usr/bin/env python3
"""Automated QC for the rendered episode (instruction §32) — validates media
SUBSTANCE, not just file existence.

Checks final/episode.mp4 against timing/timed-scenes.json + configs:
  - file exists, has video AND audio stream, NO embedded subtitle stream
  - resolution 1920x1080 + fps match theme; H.264 / AAC (configured codecs)
  - duration within tolerance of expected total frames / fps
  - final/episode.srt exists SEPARATELY + SRT coverage >= 99.5%
  - audio loudness near the loudnorm target (no silent/over-hot mixes)
  - no zero-duration scene audio
  - every scene asset exists
  - same-video demo present when promised (NEXT transition needs demo scenes)
  - the four validation gates passed (validation.json)

Writes validation/quality-check.json with explicit failure reasons. Exit 1 on
any failed check.

Usage: quality_check.py <episode-dir>
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from validate_srt_coverage import validate as srt_validate  # noqa: E402

VIDEO_COURSE_ROOT = os.path.dirname(HERE)
THEME_CFG = os.path.join(VIDEO_COURSE_ROOT, "config", "theme.json")
RENDER_CFG = os.path.join(VIDEO_COURSE_ROOT, "config", "render.json")

_WINGET_FFMPEG_BIN = os.path.expandvars(
    r"%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget"
    r".Source_8wekyb3d8bbwe\ffmpeg-*-full_build\bin")

LOUDNESS_TOLERANCE_LUFS = 2.5


def _ff():
    """PATH first, then (Windows only) the winget ffmpeg install."""
    import glob
    found = shutil.which("ffprobe")
    ffmpeg = shutil.which("ffmpeg")
    if os.name == "nt" and not found:
        hits = glob.glob(os.path.join(_WINGET_FFMPEG_BIN, "ffprobe.exe"))
        found = hits[0] if hits else None
        if not ffmpeg:
            f = glob.glob(os.path.join(_WINGET_FFMPEG_BIN, "ffmpeg.exe"))
            ffmpeg = f[0] if f else None
    return found, ffmpeg


def probe(path):
    p = subprocess.run([_ff()[0], "-v", "quiet", "-print_format", "json",
                        "-show_format", "-show_streams", path],
                       capture_output=True, text=True)
    return json.loads(p.stdout) if p.returncode == 0 else None


def loudness_lufs(ffmpeg, path):
    r = subprocess.run([ffmpeg, "-hide_banner", "-nostats", "-i", path,
                        "-af", "ebur128=framelog=quiet", "-f", "null", "-"],
                       capture_output=True, text=True)
    m = re.search(r"I:\s*(-?[\d.]+)\s*LUFS", r.stderr)
    return float(m.group(1)) if m else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("episode_dir")
    args = ap.parse_args()
    ep = args.episode_dir

    ffprobe, ffmpeg = _ff()
    if ffprobe is None:
        sys.exit("ffprobe not found (PATH and winget install).")

    mp4 = os.path.join(ep, "final", "episode.mp4")
    checks, ok = [], True

    def check(name, passed, detail="", blocking=True):
        nonlocal ok
        checks.append({"check": name, "passed": bool(passed), "detail": detail,
                       "blocking": bool(blocking)})
        if blocking:
            ok = ok and passed

    check("file exists", os.path.isfile(mp4), mp4)
    check("separate episode.srt exists", os.path.isfile(os.path.join(ep, "final", "episode.srt")),
          os.path.join(ep, "final", "episode.srt"))
    theme = json.load(open(THEME_CFG, encoding="utf-8"))
    render_cfg = json.load(open(RENDER_CFG, encoding="utf-8"))

    if os.path.isfile(mp4):
        info = probe(mp4)
        check("ffprobe readable", info is not None)
        if info:
            streams = [s["codec_type"] for s in info.get("streams", [])]
            check("has video stream", "video" in streams, str(streams))
            check("has audio stream", "audio" in streams, str(streams))
            check("no embedded subtitle stream", "subtitle" not in streams, str(streams))
            vids = [s for s in info["streams"] if s["codec_type"] == "video"]
            auds = [s for s in info["streams"] if s["codec_type"] == "audio"]
            if vids:
                v = vids[0]
                check("resolution matches theme",
                      v["width"] == theme["resolution"]["width"]
                      and v["height"] == theme["resolution"]["height"],
                      f"{v['width']}x{v['height']}")
                try:
                    num, den = (int(x) for x in v.get("r_frame_rate", "").split("/"))
                    check("fps matches theme", abs(num / den - theme["fps"]) < 0.01,
                          f"{v.get('r_frame_rate')} (expected {theme['fps']} fps)")
                except (ValueError, ZeroDivisionError):
                    check("fps matches theme", False,
                          f"unparseable r_frame_rate: {v.get('r_frame_rate')!r}")
                # codec family check (h264 may report as avc1/h264)
                want = render_cfg.get("codec", "h264")
                cc = (v.get("codec_name") or "") + (v.get("codec_tag_string") or "")
                check(f"video codec ~{want}", want in cc or cc in ("h264", "avc1"),
                      v.get("codec_name"))
            if auds:
                want_a = render_cfg.get("audio_codec", "aac")
                check(f"audio codec ~{want_a}", want_a in (auds[0].get("codec_name") or ""),
                      auds[0].get("codec_name"))
            # loudness (final mix near the loudnorm target)
            if ffmpeg:
                lufs = loudness_lufs(ffmpeg, mp4)
                target = -16.0
                if lufs is not None:
                    check("loudness near target",
                          abs(lufs - target) <= LOUDNESS_TOLERANCE_LUFS,
                          f"{lufs} LUFS (target {target} ± {LOUDNESS_TOLERANCE_LUFS})")
                else:
                    check("loudness near target", False, "ebur128 measurement failed")
            ts_path = os.path.join(ep, "timing", "timed-scenes.json")
            if os.path.isfile(ts_path):
                ts = json.load(open(ts_path, encoding="utf-8"))
                expected = ts["total_duration_frames"] / ts["fps"]
                actual = float(info["format"]["duration"])
                check("duration matches timeline", abs(actual - expected) <= 0.5,
                      f"expected {expected:.2f}s, actual {actual:.2f}s")

    # SRT coverage (independent, not just file existence)
    cov_report, cov_fails = srt_validate(ep)
    check("SRT coverage >= 99.5%", not cov_fails,
          f"{cov_report.get('coverage_pct', 0)}% " +
          (f"; {'; '.join(cov_fails)}" if cov_fails else ""))

    # no zero-duration scene audio
    audio_dir = os.path.join(ep, "audio")
    zero_audio = []
    if os.path.isdir(audio_dir):
        for fn in os.listdir(audio_dir):
            if fn.endswith(".mp3") and fn != "narration.mp3":
                p = os.path.join(audio_dir, fn)
                if os.path.getsize(p) < 512:  # <0.5KB mp3 = empty/failed synth
                    zero_audio.append(fn)
    check("no zero-duration scene audio", not zero_audio, ", ".join(zero_audio))

    # every scene asset exists
    missing_assets = []
    scenes = json.load(open(os.path.join(ep, "writing", "scenes.json"),
                            encoding="utf-8"))["scenes"]
    for s in scenes:
        for key in ("asset",):
            if s.get(key) and not os.path.isfile(os.path.join(ep, s[key])):
                missing_assets.append(f"{s['id']}:{s[key]}")
    check("all scene assets exist", not missing_assets, ", ".join(missing_assets))

    # demo gate: NEXT transition present -> demo material is expected. With the
    # two-part delivery format the real Azure demo is inserted MANUALLY between
    # part1-main and part2-thankyou before publishing, so this check is
    # RECORD-ONLY (never blocking at any status) — it documents whether demo
    # scenes exist inside the episode for traceability.
    types = [str(s.get("type", "")).upper() for s in scenes]
    if "NEXT" in types:
        after = scenes[types.index("NEXT") + 1:]
        has_demo = any(s.get("demo") for s in after)
        check("same-video demo present when promised", has_demo,
              "" if has_demo else
              "NEXT transition exists but no demo scenes follow it — the demo "
              "is inserted manually between the two publishing parts",
              blocking=False)

    # all four validation gates passed. gate4_media_quality is EXCLUDED: it is
    # derived FROM this very report (validate_episode.py reads quality-check.json),
    # so counting it here creates a circular dependency — one stale failed QC
    # run would deadlock every later re-render even with all media checks green.
    # This file is the authority for gate4; the checks above ARE gate4.
    val_path = os.path.join(ep, "validation", "validation.json")
    if os.path.isfile(val_path):
        gates = json.load(open(val_path, encoding="utf-8")).get("gates", {})
        bad_gates = [k for k, g in gates.items()
                     if k != "gate4_media_quality"
                     and g.get("status") in ("fail",)]
        check("all validation gates passed", not bad_gates, ", ".join(bad_gates))
    else:
        check("all validation gates passed", False, "no validation.json (run validate)")

    report = {"episode": os.path.abspath(ep), "qc_passed": ok, "checks": checks}
    os.makedirs(os.path.join(ep, "validation"), exist_ok=True)
    out = os.path.join(ep, "validation", "quality-check.json")
    json.dump(report, open(out, "w", encoding="utf-8"), indent=2)
    print(json.dumps(report, indent=2))
    print(f"-> {out}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()