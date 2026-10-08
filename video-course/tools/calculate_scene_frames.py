#!/usr/bin/env python3
"""Audio frames + padding -> timing/timed-scenes.json (Remotion input).

Per scene: audio_frames = ceil(duration*fps);
total_frames = lead_in + audio_frames + lead_out.
Padding and fps from the skill's config/voice.json + config/theme.json.

Usage: calculate_scene_frames.py <episode-dir>
"""
import argparse
import json
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
VIDEO_COURSE_ROOT = os.path.dirname(HERE)  # tools/ -> video-course/
VOICE_CFG = os.path.join(VIDEO_COURSE_ROOT, "config", "voice.json")
THEME_CFG = os.path.join(VIDEO_COURSE_ROOT, "config", "theme.json")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("episode_dir")
    args = ap.parse_args()
    ep = args.episode_dir

    fps = json.load(open(THEME_CFG, encoding="utf-8"))["fps"]
    padding = json.load(open(VOICE_CFG, encoding="utf-8"))["padding"]
    durations = json.load(open(os.path.join(ep, "timing", "audio-durations.json"),
                               encoding="utf-8"))["durations_sec"]
    scenes_in = json.load(open(os.path.join(ep, "writing", "scenes.json"),
                               encoding="utf-8"))["scenes"]

    timed, offset = [], 0
    for s in scenes_in:
        dur = durations.get(s["id"])
        if dur is None:
            raise SystemExit(f"No measured audio for scene {s['id']} — "
                             f"run measure_audio.py first.")
        audio_frames = math.ceil(dur * fps)
        entry = {
            "id": s["id"],
            "duration_sec": dur,
            "audio_frames": audio_frames,
            "lead_in_frames": padding["lead_in_frames"],
            "lead_out_frames": padding["lead_out_frames"],
            "total_frames": padding["lead_in_frames"] + audio_frames + padding["lead_out_frames"],
            "starts_at_frame": offset + padding["lead_in_frames"],
            "scene_start_frame": offset,
        }
        # narration-synced diagram scenes: measured step durations -> per-step
        # highlight-change frames, RELATIVE to the scene's first frame. Step 1
        # begins at the lead-in; each step lasts ceil(step_dur*fps) frames; the
        # last step runs to the end of the scene audio (audio_frames), so
        # rounding drift never desynchronizes the final highlight.
        steps = s.get("steps") or []
        if steps:
            if not s.get("step_audio"):
                raise SystemExit(f"Scene {s['id']} has steps but no step_audio — "
                                 f"run TTS first.")
            sf, cur = [], padding["lead_in_frames"]
            for i in range(len(steps)):
                sdur = durations.get(f"{s['id']}.step{i + 1}")
                if sdur is None:
                    raise SystemExit(f"No measured audio for {s['id']}.step{i + 1} "
                                     f"— run measure_audio.py.")
                end = audio_frames if i == len(steps) - 1 else cur + math.ceil(sdur * fps)
                sf.append({"key": f"{s['id']}.step{i + 1}", "start": cur, "end": end})
                cur = end
            entry["step_frames"] = sf
        offset += entry["total_frames"]
        timed.append(entry)

    out_doc = {"fps": fps, "total_duration_frames": offset,
               "total_duration_sec": round(offset / fps, 3), "scenes": timed}
    out = os.path.join(ep, "timing", "timed-scenes.json")
    json.dump(out_doc, open(out, "w", encoding="utf-8"), indent=2)
    print(f"-> {out} ({len(timed)} scenes, {out_doc['total_duration_sec']}s total)")


if __name__ == "__main__":
    main()
