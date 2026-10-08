#!/usr/bin/env python3
"""Generate the separate SRT for an episode, timed from ACTUAL audio.

Policy (render.json): the SRT is standalone — never burned into the MP4, never
embedded as a subtitle stream, never rendered by Remotion.

Timing sources, in preference order (never estimated-when-exact-exists):
  1. timing/word-timing.json  — edge-tts WordBoundary events (exact)
  2. timing/timestamps.json   — whisperx word alignment
  3. scene-level proportional distribution (fallback)

Text preservation (instruction §4.3): cue text is NEVER truncated to satisfy
line-count rules. Long text wraps to max_lines; if it still does not fit, it
becomes MULTIPLE SEQUENTIAL cues — every spoken word survives. Scenes with
`steps` speak their step narrations (instruction §4.4).

After writing, the episode's SRT coverage is validated (>= 99.5%, see
validate_srt_coverage.py) and this tool exits 1 below the threshold.

Output: captions/episode.srt and final/episode.srt
Usage: generate_srt.py <episode-dir>
"""
import argparse
import json
import os
import re
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from validate_srt_coverage import normalize as norm_words, spoken_text, validate as validate_coverage  # noqa: E402

VIDEO_COURSE_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RENDER_CFG = os.path.join(VIDEO_COURSE_ROOT, "config", "render.json")
THEME_CFG = os.path.join(VIDEO_COURSE_ROOT, "config", "theme.json")

TAG_RE = re.compile(r"<#\d+(?:\.\d+)?#>")


def fmt_ts(sec):
    ms = round(sec * 1000)
    h, ms = divmod(ms, 3600000)
    m, ms = divmod(ms, 60000)
    s, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def clean(text):
    """Strip TTS control tags + collapse whitespace (tags control delivery
    only — never subtitle text)."""
    return re.sub(r"\s+", " ", TAG_RE.sub(" ", text)).strip()


def split_cues(text, maxlen):
    """Greedy word-wrap; keep identifiers (no-space tokens) intact."""
    words = text.split()
    lines, cur = [], ""
    for w in words:
        if cur and len(cur) + 1 + len(w) > maxlen:
            lines.append(cur)
            cur = w
        else:
            cur = f"{cur} {w}".strip()
    if cur:
        lines.append(cur)
    return lines or [""]


def scene_word_events(scene_id, ep):
    """Exact word timing for a scene: edge-tts boundaries first, then whisperx."""
    wt = os.path.join(ep, "timing", "word-timing.json")
    if os.path.isfile(wt):
        doc = json.load(open(wt, encoding="utf-8"))
        for sc in doc.get("scenes", []):
            if sc["id"] == scene_id and sc.get("words"):
                if doc.get("mode") == "edge-word-boundaries":
                    # word offsets are relative to the scene audio start (ms)
                    return [w for w in sc["words"]]
    ts = os.path.join(ep, "timing", "timestamps.json")
    if os.path.isfile(ts):
        doc = json.load(open(ts, encoding="utf-8"))
        if doc.get("mode") == "whisperx-word-alignment":
            for sc in doc.get("scenes", []):
                if sc["id"] == scene_id and sc.get("words"):
                    return [{"text": w["word"],
                             "offset_ms": w["start"] * 1000,
                             "duration_ms": (w["end"] - w["start"]) * 1000}
                            for w in sc["words"] if "start" in w]
    return None


def cues_from_words(words, style):
    """Word-timing cues: split at max duration / line capacity / sentence ends.
    Never drops a word — a cue that cannot fit becomes several cues."""
    max_line = style["chars_per_line"][1]
    max_chars = style["max_lines"] * max_line
    min_t, max_t = style["segment_sec"]
    cues, buf, t0, end = [], [], None, None

    def flush():
        nonlocal buf, t0, end
        if buf:
            cues.append((t0 / 1000.0, end / 1000.0, " ".join(buf)))
            buf, t0, end = [], None, None

    for w in words:
        txt = clean(w["text"])
        if not txt:
            continue
        cand = " ".join(buf + [txt])
        w_start = w["offset_ms"] / 1000.0
        w_end = (w["offset_ms"] + w["duration_ms"]) / 1000.0
        if t0 is None:
            t0, end = w_start, w_end
            buf = [txt]
            continue
        # fit check uses the REAL greedy wrap, not max_lines*max_line: a
        # duration-capped cue can carry chars that wrap to max_lines+1 lines,
        # and the writer would then silently truncate the overflow line
        over = len(split_cues(cand, max_line)) > style["max_lines"] \
            or (w_end - t0 >= max_t)
        sentence_end = re.search(r"[.!?]['\"]?$", txt) and (w_end - t0) >= min_t
        if over or sentence_end:
            flush_end = max(end, w_start)  # cue ends where the next word begins
            cues.append((t0, flush_end, " ".join(buf)))
            buf, t0, end = [txt], w_start, w_end
        else:
            buf.append(txt)
            end = w_end
    if buf:
        cues.append((t0, max(end, t0 + 0.5), " ".join(buf)))
    return cues


def scene_cues(text, start, dur, style):
    """Fallback: distribute narration across the scene window in word-proportional
    multi-cues bounded by max_lines x chars_per_line (nothing truncated)."""
    max_line = style["chars_per_line"][1]
    max_chars = style["max_lines"] * max_line
    words = text.split()
    if not words:
        return []
    # group words into cue-sized chunks (<= max_chars, prefer sentence breaks)
    chunks, cur = [], []
    def flush():
        if cur:
            chunks.append(" ".join(cur))
            cur.clear()
    for w in words:
        cand = " ".join(cur + [w])
        if cur and len(cand) > max_chars:
            flush()
        cur.append(w)
    flush()
    # weight each chunk by its word count for timing
    total = sum(len(c.split()) for c in chunks) or 1
    cues, t = [], start
    for c in chunks:
        share = dur * len(c.split()) / total
        cues.append((t, min(t + share, start + dur), c))
        t += share
    if cues:
        cues[-1] = (cues[-1][0], start + dur, cues[-1][2])
    return cues


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("episode_dir")
    args = ap.parse_args()
    ep = args.episode_dir

    cfg = json.load(open(RENDER_CFG, encoding="utf-8"))
    style = cfg["srt_style"]
    fps = json.load(open(THEME_CFG, encoding="utf-8"))["fps"]

    scenes_doc = json.load(open(os.path.join(ep, "writing", "scenes.json"),
                                encoding="utf-8"))
    scenes_def = {s["id"]: s for s in scenes_doc["scenes"]}
    timed = json.load(open(os.path.join(ep, "timing", "timed-scenes.json"),
                           encoding="utf-8"))

    cues = []
    for sc in timed["scenes"]:
        sid = sc["id"]
        start = sc["starts_at_frame"] / fps
        dur = sc["audio_frames"] / fps
        sdef = scenes_def.get(sid, {})
        steps = sdef.get("steps") or []
        # steps are the spoken text for step scenes (§4.4)
        text = clean(spoken_text([sdef])) if (steps or sdef.get("narration")) else ""
        if not text:
            continue
        we = scene_word_events(sid, ep)
        if we:
            # align word events to the scene window; clamp into [start, start+dur]
            raw = cues_from_words(we, style)
            cues.extend((start + a, min(start + b, start + dur), t)
                        for a, b, t in raw if t)
        else:
            cues.extend(scene_cues(text, start, dur, style))

    # enforce: ordered, no overlaps, >= 0.3s
    cues.sort(key=lambda c: c[0])
    fixed = []
    for a, b, t in cues:
        if fixed and a < fixed[-1][1]:
            a = fixed[-1][1]
        if b - a < 0.3:
            b = a + 0.3
        fixed.append((a, b, t))

    srt_lines = []
    for i, (a, b, t) in enumerate(fixed, 1):
        body = "\n".join(split_cues(t, style["chars_per_line"][1])[: style["max_lines"]])
        srt_lines.append(f"{i}\n{fmt_ts(a)} --> {fmt_ts(b)}\n{body}\n")
    srt = "\n".join(srt_lines)

    os.makedirs(os.path.join(ep, "captions"), exist_ok=True)
    os.makedirs(os.path.join(ep, "final"), exist_ok=True)
    cap = os.path.join(ep, "captions", "episode.srt")
    fin = os.path.join(ep, "final", "episode.srt")
    open(cap, "w", encoding="utf-8").write(srt)
    shutil.copyfile(cap, fin)
    print(f"-> {cap}\n-> {fin} ({len(fixed)} cues)")

    # gate: coverage must hold BEFORE anything downstream trusts this SRT
    report, fails = validate_coverage(ep)
    os.makedirs(os.path.join(ep, "validation"), exist_ok=True)
    json.dump(report, open(os.path.join(ep, "validation", "srt-coverage.json"),
                           "w", encoding="utf-8"), indent=2)
    if fails:
        for f in fails:
            print(f"SRT COVERAGE FAIL: {f}")
        sys.exit(1)
    print(f"SRT coverage: {report['coverage_pct']}% (>= {report['min_coverage']}%)")


if __name__ == "__main__":
    main()