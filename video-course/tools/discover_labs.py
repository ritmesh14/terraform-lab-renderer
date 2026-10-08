#!/usr/bin/env python3
"""Discover course labs under <source-root>/section-*.

Emits a JSON episode list: section, lab id, path, absolute path.
All numbered lab folders count (2026-09-26: no-.tf demo labs included,
numbering runs continuously 01-126 across sections; folders sort numerically
so 100- follows 99-).
Usage: discover_labs.py [--root <source-root>] [--out episodes.json]
"""
import argparse
import json
import os
import re


def discover(root):
    episodes = []
    for section in sorted(os.listdir(root)):
        sec_dir = os.path.join(root, section)
        if not (section.startswith("section-") and os.path.isdir(sec_dir)):
            continue
        labs = [l for l in os.listdir(sec_dir) if re.match(r"\d", l)]
        labs.sort(key=lambda l: int(re.match(r"(\d+)", l).group(1)))  # numeric, not lexicographic (100- must follow 99-)
        for lab in labs:
            lab_dir = os.path.join(sec_dir, lab)
            if not os.path.isdir(lab_dir):
                continue
            num = re.match(r"(\d+)", lab)
            episodes.append({
                "section": section,
                "lab": lab,
                "order": int(num.group(1)) if num else 0,
                "path": f"{section}/{lab}",
                "abs_path": os.path.abspath(lab_dir),
            })
    return episodes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.environ.get("COURSE_SOURCE_ROOT") or os.getcwd())
    ap.add_argument("--out", help="write JSON here (default: stdout)")
    args = ap.parse_args()
    episodes = discover(args.root)
    out = json.dumps(episodes, indent=2)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(out)
        print(f"{len(episodes)} labs -> {args.out}")
    else:
        print(out)


if __name__ == "__main__":
    main()
