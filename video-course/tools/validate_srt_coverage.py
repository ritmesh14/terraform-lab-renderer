#!/usr/bin/env python3
"""SRT coverage validation (instruction §4.3): every spoken word must survive
into the SRT. A missing SRT file and an incomplete SRT file are both failures.

Compares the NORMALIZED spoken narration (scenes.json, including step
narrations — steps are the spoken text for step scenes) against the normalized
SRT cue text. Coverage = multiset word overlap / narration word count.

Requirement: coverage >= 99.5% (100% preferred; control tags are not spoken).
Also fails on: overlapping cues, control tags (<#N#>) leaking into cue text.

Usage:
  validate_srt_coverage.py <episode-dir>   # validates final/episode.srt
Writes validation/srt-coverage.json; exit 1 below threshold.
"""
import argparse
import json
import os
import re
import sys
from collections import Counter

VIDEO_COURSE_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MIN_COVERAGE = 99.5

TAG_RE = re.compile(r"<#\d+(?:\.\d+)?#>")
CUE_TS_RE = re.compile(r"(\d+):(\d+):(\d+)[,.](\d+)\s*-->\s*(\d+):(\d+):(\d+)[,.](\d+)")
PUNCT_RE = re.compile(r"[^\w']+")


def spoken_text(scenes):
    """The full spoken narration of the episode, in scene order.

    Scenes with `steps` speak their step narrations, NOT the top-level
    narration field (instruction §4.4)."""
    parts = []
    for s in scenes:
        steps = s.get("steps") or []
        if steps:
            parts.extend((st.get("narration") or "").strip() for st in steps)
        else:
            parts.append((s.get("narration") or "").strip())
    return " ".join(p for p in parts if p)


def normalize(text):
    """Lowercase, strip control tags + punctuation; keep only word tokens."""
    text = TAG_RE.sub(" ", text)
    text = text.lower().replace("’", "'")
    return [w for w in PUNCT_RE.split(text) if w]


def parse_srt(path):
    txt = open(path, encoding="utf-8-sig").read().replace("\r\n", "\n")
    cues = []
    for block in re.split(r"\n\s*\n", txt.strip()):
        lines = [l for l in block.split("\n") if l.strip()]
        if len(lines) < 2 or not CUE_TS_RE.search(lines[1]):
            continue
        text = " ".join(lines[2:])
        cues.append(text)
    return cues


def coverage(narration_words, srt_words):
    """Multiset word coverage (%) — how much of the narration the SRT carries."""
    narr = Counter(narration_words)
    have = Counter(srt_words)
    matched = sum(min(narr[w], have[w]) for w in narr)
    total = sum(narr.values())
    return (100.0 * matched / total) if total else 100.0


def validate(ep_dir, srt_rel="final/episode.srt", scenes=None):
    """Returns (report_dict, fails:list[str])."""
    scenes = scenes or json.load(open(os.path.join(
        ep_dir, "writing", "scenes.json"), encoding="utf-8"))["scenes"]
    srt_path = os.path.join(ep_dir, *srt_rel.split("/"))
    fails = []
    if not os.path.isfile(srt_path):
        return ({"coverage_pct": 0.0, "srt": srt_rel, "missing": True},
                [f"SRT file missing: {srt_path}"])
    cues = parse_srt(srt_path)
    if not cues:
        return ({"coverage_pct": 0.0, "cues": 0},
                ["SRT has no parseable cues"])

    narr = normalize(spoken_text(scenes))
    srt = normalize(" ".join(cues))
    pct = coverage(narr, srt)

    # control tags must never leak into subtitle text
    if any(TAG_RE.search(c) for c in cues):
        fails.append("control tag (<#N#>) leaked into SRT cue text")

    # no overlapping cues
    ts = []
    for block in re.split(r"\n\s*\n", open(srt_path, encoding="utf-8-sig")
                          .read().replace("\r\n", "\n").strip()):
        m = CUE_TS_RE.search(block)
        if m:
            g = [int(x) for x in m.groups()]
            ts.append((g[0] * 3600000 + g[1] * 60000 + g[2] * 1000 + g[3],
                       g[4] * 3600000 + g[5] * 60000 + g[6] * 1000 + g[7]))
    for i in range(1, len(ts)):
        if ts[i][0] < ts[i - 1][1]:
            fails.append(f"overlapping cues #{i} / #{i + 1}")

    if pct < MIN_COVERAGE:
        # report the first missing words to make repair concrete
        have = Counter(srt)
        want = Counter(narr)
        miss = [w for w in narr if want[w] > have.get(w, 0)][:10]
        fails.append(f"SRT coverage {pct:.2f}% < {MIN_COVERAGE}% "
                     f"(missing words like: {', '.join(miss)})")
    report = {"srt": srt_rel, "cues": len(cues),
              "narration_words": len(narr), "srt_words": len(srt),
              "coverage_pct": round(pct, 2),
              "min_coverage": MIN_COVERAGE, "status": "pass" if not fails else "fail",
              "fails": fails}
    return report, fails


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("episode_dir")
    args = ap.parse_args()
    report, fails = validate(args.episode_dir)
    os.makedirs(os.path.join(args.episode_dir, "validation"), exist_ok=True)
    out = os.path.join(args.episode_dir, "validation", "srt-coverage.json")
    json.dump(report, open(out, "w", encoding="utf-8"), indent=2)
    print(json.dumps(report, indent=2))
    print(f"-> {out}")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()