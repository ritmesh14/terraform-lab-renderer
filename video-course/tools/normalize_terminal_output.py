#!/usr/bin/env python3
"""Strip terminal captures to safe, on-screen-ready text.

Removes ANSI escapes, absolute machine paths, subscription/tenant GUIDs, and
anything matching common secret shapes. Output is a fixture safe to show in a
course video (feeds render_terminal_svg.py).

Usage: normalize_terminal_output.py raw.txt [-o clean.txt]
"""
import argparse
import re
import sys

RULES = [
    (re.compile(r"\x1b\[[0-9;]*[A-Za-z]"), ""),          # ANSI colours
    (re.compile(r"\x1b\][^\x07]*\x07"), ""),             # OSC sequences
    (re.compile(r"[A-Za-z]:\\Users\\[^\s\\]+"), "~"),    # home dir paths
    (re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"), "<guid>"),
    (re.compile(r"(?i)(password|secret|token|key)\s*[=:]\s*\S+"), r"\1 = <redacted>"),
]


def normalize(text):
    lines = []
    for line in text.splitlines():
        for rx, repl in RULES:
            line = rx.sub(repl, line)
        lines.append(line.rstrip())
    while lines and not lines[-1]:
        lines.pop()   # trailing blank lines
    return "\n".join(lines) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("-o", "--out")
    args = ap.parse_args()
    text = open(args.input, encoding="utf-8", errors="replace").read()
    cleaned = normalize(text)
    if args.out:
        open(args.out, "w", encoding="utf-8").write(cleaned)
        print(f"-> {args.out}")
    else:
        sys.stdout.write(cleaned)


if __name__ == "__main__":
    main()
