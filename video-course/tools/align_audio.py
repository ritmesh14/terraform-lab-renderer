#!/usr/bin/env python3
"""Optional word-level alignment -> timing/timestamps.json.

If whisperx is installed: force-align each scene's audio against its narration.
Otherwise: emit scene-level timing only (captions fall back to even
distribution within the scene). NEVER relies on TTS word timestamps.

Usage: align_audio.py <episode-dir>
"""
import argparse
import json
import os
import sys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("episode_dir")
    args = ap.parse_args()
    ep = args.episode_dir

    scenes = json.load(open(os.path.join(ep, "writing", "scenes.json"),
                            encoding="utf-8"))["scenes"]
    durations = json.load(open(os.path.join(ep, "timing", "audio-durations.json"),
                               encoding="utf-8"))["durations_sec"]

    result = {"mode": None, "scenes": []}
    try:
        import whisperx  # noqa
        result["mode"] = "whisperx-word-alignment"
        device = "cuda" if os.environ.get("ALIGN_DEVICE") == "cuda" else "cpu"
        model = whisperx.load_model("base", device)
        for s in scenes:
            if s["id"] not in durations:
                continue
            audio = whisperx.load_audio(os.path.join(ep, s["audio"]))
            tr = model.transcribe(audio, batch_size=8)
            aligned = whisperx.align(tr["segments"],
                                     whisperx.load_align_model("en", device)[0],
                                     whisperx.load_align_model("en", device)[1],
                                     audio, device)
            words = [{"word": w["word"], "start": w["start"], "end": w["end"]}
                     for seg in aligned["segments"] for w in seg.get("words", [])
                     if "start" in w]
            result["scenes"].append({"id": s["id"], "words": words})
    except ImportError:
        result["mode"] = "scene-level-only"
        for s in scenes:
            if s["id"] in durations:
                result["scenes"].append({"id": s["id"],
                                         "duration_sec": durations[s["id"]]})
        print("whisperx not installed; emitting scene-level timing only. "
              "(pip install whisperx for word alignment.)")

    out = os.path.join(ep, "timing", "timestamps.json")
    json.dump(result, open(out, "w", encoding="utf-8"), indent=2)
    print(f"-> {out} (mode: {result['mode']})")


if __name__ == "__main__":
    main()
