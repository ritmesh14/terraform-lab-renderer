#!/usr/bin/env python3
"""Provider-neutral scene TTS — the canonical voice tool (instruction §4.1).

Edge TTS is the FREE CANONICAL DEFAULT (en-US-AndrewNeural male instructor);
MiniMax is an optional provider only. TTS remains the timing authority.

Reads writing/scenes.json and generates ONE audio file per scene
(audio/S001.mp3, …). Regenerate a single scene with --only S003. Scenes with
`steps` get one file per step concatenated into the scene file.

Word timing (instruction §4.2): the edge provider captures the streaming
WordBoundary events and persists them per scene:

    timing/word-timing/S001.json   {"words": [{"text","offset_ms","duration_ms"}...]}
    timing/word-timing.json        merged {scenes: [{id, words}...]}

Word timing drives SRT cue breaks, code line/token focus, concept reveal and
recap timing. The MiniMax provider cannot provide boundaries; when it is used
the timing files record {"mode": "none"} and downstream stages fall back to
scene-level timing (never estimated-when-exact-exists).

Providers (config/voice.json):
  edge   (default, free, no key)   python edge-tts streaming, uvx CLI fallback
  minimax (optional)               needs MINIMAX_API_KEY; selected only via
                                   --provider minimax or optional_providers

Usage:
  generate_voice.py <episode-dir> [--only S003,S007] [--provider edge]
"""
import argparse
import asyncio
import json
import os
import re
import shutil
import subprocess
import sys
import time

import requests

HERE = os.path.dirname(os.path.abspath(__file__))
VIDEO_COURSE_ROOT = os.path.dirname(HERE)
DEFAULT_VOICE_CFG = os.path.join(VIDEO_COURSE_ROOT, "config", "voice.json")

API_KEY = os.getenv("MINIMAX_API_KEY")
API_BASE = os.getenv("MINIMAX_API_BASE", "https://api.minimax.io/v1").rstrip("/")

_WINGET_FFMPEG = os.path.expandvars(
    r"%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget"
    r".Source_8wekyb3d8bbwe\ffmpeg-*-full_build\bin\ffmpeg.exe")

MAX_TEXT = 9000
RETRIES = 3


def find_ffmpeg():
    found = shutil.which("ffmpeg")
    if not found and os.name == "nt":
        import glob
        hits = glob.glob(_WINGET_FFMPEG)
        found = hits[0] if hits else None
    return found


def _pct(x, unit):
    n = round((float(x) - 1.0) * 100)
    return f"{'+' if n >= 0 else ''}{n}{unit}"


# --------------------------------------------------------------------- edge

# MiniMax pause markers (<#1.5#>). MiniMax reads them as pauses; edge-tts reads
# them ALOUD as literal text — strip before any edge synthesis (course rule).
TAG_RE = re.compile(r"<#\d+(?:\.\d+)?#>")


def clean_for_edge(text):
    return TAG_RE.sub(" ", text).strip()


def edge_word_timing(text, cfg):
    """Synthesize via the edge-tts Python streaming API.

    Returns (mp3_bytes, words) where words = [{"text","offset_ms","duration_ms"}]
    captured from the WordBoundary stream events. Raises RuntimeError when the
    package is missing or synthesis fails, so the caller can fall back.
    """
    try:
        import edge_tts
    except ImportError:
        raise RuntimeError("edge-tts python package not installed")
    voice = cfg.get("edge_voice", "en-US-AndrewNeural")
    rate = _pct(cfg.get("speed", 1.0), "%")
    volume = _pct(cfg.get("vol", 1.0), "%")
    pitch = f"{'+' if int(cfg.get('pitch', 0)) >= 0 else ''}{int(cfg.get('pitch', 0))}Hz"
    text = clean_for_edge(text)

    async def run():
        mp3, words = bytearray(), []
        # boundary="WordBoundary" — edge-tts 7.x defaults to SentenceBoundary;
        # the SRT pipeline needs per-word timing
        comm = edge_tts.Communicate(text, voice, rate=rate, volume=volume,
                                    pitch=pitch, boundary="WordBoundary")
        async for chunk in comm.stream():
            if chunk["type"] == "audio":
                mp3.extend(chunk["data"])
            elif chunk["type"] == "WordBoundary":
                # offset/duration arrive in 100-ns ticks -> ms
                words.append({
                    "text": chunk["text"],
                    "offset_ms": round(chunk["offset"] / 10000),
                    "duration_ms": round(chunk["duration"] / 10000),
                })
        return bytes(mp3), words

    mp3, words = asyncio.run(run())
    if not mp3:
        raise RuntimeError("edge-tts produced no audio")
    return mp3, words


def edge_cli_timing(text, cfg, out_path, timeout=180):
    """uvx edge-tts CLI fallback (no word boundaries available)."""
    uvx = shutil.which("uvx")
    if not uvx:
        raise RuntimeError("uvx not found on PATH")
    cmd = [uvx, "edge-tts", "--voice", cfg.get("edge_voice", "en-US-AndrewNeural")]
    if float(cfg.get("speed", 1.0)) != 1.0:
        cmd += ["--rate", _pct(cfg["speed"], "%")]
    if float(cfg.get("vol", 1.0)) != 1.0:
        cmd += ["--volume", _pct(cfg["vol"], "%")]
    if int(cfg.get("pitch", 0)) != 0:
        cmd += ["--pitch", f"{'+' if int(cfg['pitch']) >= 0 else ''}{int(cfg['pitch'])}Hz"]
    cmd += ["--text", clean_for_edge(text), "--write-media", out_path]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    if r.returncode != 0 or not os.path.isfile(out_path) or os.path.getsize(out_path) == 0:
        raise RuntimeError(f"edge-tts CLI failed (rc={r.returncode}): {r.stderr.strip()[:400]}")


# ------------------------------------------------------------------- minimax

def tts_minimax(text, cfg, timeout=120):
    if not API_KEY:
        sys.exit("ERROR: MINIMAX_API_KEY is not set (optional provider).")
    voice_setting = {"voice_id": cfg["voice_id"], "speed": cfg["speed"],
                     "vol": cfg["vol"], "pitch": cfg["pitch"]}
    if cfg.get("emotion"):
        voice_setting["emotion"] = cfg["emotion"]
    payload = {
        "model": cfg["model"], "text": text, "stream": False,
        "voice_setting": voice_setting,
        "audio_setting": {"sample_rate": 32000, "bitrate": 128000,
                          "format": cfg["audio_format"], "channel": 1},
        "language_boost": "auto", "output_format": "hex",
    }
    resp = requests.post(f"{API_BASE}/t2a_v2",
                         headers={"Authorization": f"Bearer {API_KEY}",
                                  "Content-Type": "application/json"},
                         json=payload, timeout=timeout)
    resp.raise_for_status()
    data = resp.json()
    base = data.get("base_resp", {})
    if base.get("status_code", 0) != 0:
        sys.exit(f"MiniMax API error {base.get('status_code')}: {base.get('status_msg')}")
    audio_hex = (data.get("data") or {}).get("audio")
    if not audio_hex:
        sys.exit(f"Unexpected response (no audio): {json.dumps(data)[:500]}")
    return bytes.fromhex(audio_hex)


# ------------------------------------------------------------------ pipeline

def concat(parts, out_path):
    """ffmpeg-concat step audios into the scene file (same codec)."""
    ffmpeg = find_ffmpeg()
    if not ffmpeg:
        sys.exit("ffmpeg not found — required to concatenate step audios.")
    lst = out_path + ".concat.txt"
    with open(lst, "w", encoding="utf-8") as f:
        for p in parts:
            esc = os.path.abspath(p).replace("\\", "/").replace("'", "'\\''")
            f.write(f"file '{esc}'\n")
    r = subprocess.run([ffmpeg, "-y", "-f", "concat", "-safe", "0", "-i", lst,
                        "-c", "copy", out_path], capture_output=True, text=True)
    os.remove(lst)
    if r.returncode != 0 or not os.path.isfile(out_path) or os.path.getsize(out_path) == 0:
        sys.exit(f"step concat failed for {out_path}: {r.stderr.strip()[:400]}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("episode_dir")
    ap.add_argument("--only", help="comma-separated scene ids to (re)generate")
    ap.add_argument("--voice-config", default=DEFAULT_VOICE_CFG)
    ap.add_argument("--voice")
    ap.add_argument("--model")
    ap.add_argument("--provider", choices=["config", "edge", "minimax"],
                    default="config",
                    help="edge = free canonical default; minimax = optional "
                         "(only when explicitly requested AND a key is set)")
    args = ap.parse_args()

    cfg = json.load(open(args.voice_config, encoding="utf-8"))
    if args.voice:
        cfg["edge_voice"] = cfg["voice_id"] = args.voice
    if args.model:
        cfg["model"] = args.model
    optional = cfg.get("optional_providers", {})
    if args.provider == "minimax" or (args.provider == "config"
                                      and cfg.get("provider") == "minimax"
                                      and optional.get("minimax", {}).get("enabled")):
        provider, fmt = "minimax", cfg["audio_format"]
        print(f"provider: minimax {cfg['model']} (OPTIONAL — edge is the course default)")
    else:
        provider, fmt = "edge", "mp3"
        print(f"provider: edge-tts (free default) — voice {cfg.get('edge_voice', 'en-US-AndrewNeural')}")

    scenes_path = os.path.join(args.episode_dir, "writing", "scenes.json")
    doc = json.load(open(scenes_path, encoding="utf-8"))
    scenes = doc["scenes"]
    only = set(args.only.split(",")) if args.only else None
    audio_dir = os.path.join(args.episode_dir, "audio")
    wt_dir = os.path.join(args.episode_dir, "timing", "word-timing")
    os.makedirs(audio_dir, exist_ok=True)
    os.makedirs(wt_dir, exist_ok=True)

    timing_mode = "edge-word-boundaries" if provider == "edge" else "none"
    word_timings = {}
    # --only regenerates a subset: keep the other scenes' word timing. The
    # per-scene timing/word-timing/<sid>.json files are the durable source.
    if only:
        for s in scenes:
            sid = s["id"]
            if sid in only:
                continue
            p = os.path.join(wt_dir, f"{sid}.json")
            if os.path.isfile(p):
                try:
                    word_timings[sid] = json.load(open(p, encoding="utf-8")).get("words", [])
                except (OSError, ValueError):
                    pass

    def synth(text, path):
        """One TTS call -> (path, words|None), bounded retry on transients."""
        last = None
        for attempt in range(RETRIES):
            try:
                if provider == "minimax":
                    open(path, "wb").write(tts_minimax(text, cfg))
                    return None
                if timing_mode == "edge-word-boundaries":
                    data, words = edge_word_timing(text, cfg)
                    if not words:
                        # 7.x default boundary is SentenceBoundary — a silent
                        # regression here would starve the SRT of word timing
                        raise RuntimeError("edge stream produced no word boundaries")
                    tmp = path + ".tmp.mp3"
                    open(tmp, "wb").write(data)
                    os.replace(tmp, path)
                    return words
                # uvx CLI fallback (python edge-tts unavailable)
                tmp = path + ".tmp.mp3"
                edge_cli_timing(text, cfg, tmp)
                os.replace(tmp, path)
                return None
            except (RuntimeError, subprocess.SubprocessError) as e:
                last = e
                time.sleep(2 * (attempt + 1))
        raise SystemExit(f"TTS failed after {RETRIES} attempts: {last}")

    for s in scenes:
        sid = s["id"]
        if only and sid not in only:
            continue
        steps = s.get("steps") or []
        s_words = []
        if steps:
            step_paths, step_keys = [], []
            for i, st in enumerate(steps, 1):
                text = (st.get("narration") or "").strip()
                if not text:
                    sys.exit(f"Scene {sid} step {i} has empty narration.")
                spath = os.path.join(audio_dir, f"{sid}.step{i}.{fmt}")
                words = synth(text, spath)
                if words:
                    for w in words:
                        w["step"] = i
                    s_words.extend(words)
                step_paths.append(spath)
                step_keys.append(f"audio/{sid}.step{i}.{fmt}")
            path = os.path.join(audio_dir, f"{sid}.{fmt}")
            concat(step_paths, path)
            s["step_audio"] = step_keys
            s["audio"] = f"audio/{sid}.{fmt}"
            print(f"  {sid}: {len(steps)} steps -> {path} "
                  f"({len(s_words)} word events)")
        else:
            text = (s.get("narration") or "").strip()
            if not text:
                sys.exit(f"Scene {sid} has empty narration — fix scenes.json first.")
            if len(text) > MAX_TEXT:
                sys.exit(f"Scene {sid} is {len(text)} chars (>{MAX_TEXT}). Split it.")
            path = os.path.join(audio_dir, f"{sid}.{fmt}")
            words = synth(text, path)
            s_words = words or []
            s["audio"] = f"audio/{sid}.{fmt}"
            print(f"  {sid}: -> {path} ({len(s_words)} word events)")
        if s_words:
            with open(os.path.join(wt_dir, f"{sid}.json"), "w", encoding="utf-8") as f:
                json.dump({"scene": sid, "mode": timing_mode, "words": s_words},
                          f, indent=2, ensure_ascii=False)
        word_timings[sid] = s_words

    # persist audio paths back into scenes.json (full doc survives the rewrite)
    with open(scenes_path, "w", encoding="utf-8") as f:
        json.dump(doc, f, indent=2, ensure_ascii=False)

    merged = [{"id": sid, "mode": timing_mode, "words": word_timings.get(sid, [])}
              for sid in [s["id"] for s in scenes]]
    with open(os.path.join(args.episode_dir, "timing", "word-timing.json"),
              "w", encoding="utf-8") as f:
        json.dump({"mode": timing_mode, "scenes": merged}, f, indent=2,
                  ensure_ascii=False)
    print(f"-> timing/word-timing.json (mode: {timing_mode})")

    # archive narration.mp3 (all scenes present)
    expected = [os.path.join(audio_dir, f"{s['id']}.{fmt}") for s in scenes]
    if all(os.path.isfile(p) for p in expected):
        ffmpeg = find_ffmpeg()
        if not ffmpeg:
            print("ffmpeg not found — skipped archive narration.mp3 concat.")
            return
        lst = os.path.join(audio_dir, "concat.txt")
        with open(lst, "w", encoding="utf-8") as f:
            for p in expected:
                esc = p.replace("\\", "/").replace("'", "'\\''")
                f.write(f"file '{esc}'\n")
        out_mp3 = os.path.join(audio_dir, "narration.mp3")
        subprocess.run([ffmpeg, "-y", "-f", "concat", "-safe", "0", "-i", lst,
                        "-c", "copy", out_mp3], capture_output=True)
        os.remove(lst)
        print(f"archive narration.mp3 -> {out_mp3}")


if __name__ == "__main__":
    main()