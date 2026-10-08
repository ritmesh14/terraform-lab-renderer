#!/usr/bin/env python3
"""Render a terminal scene as SVG for Remotion to animate.

Input spec JSON:
{
  "command": "terraform plan",
  "output_file": "fixtures/plan.txt",
  "highlight": ["+ create"]
}

-> terminal-plan.svg : dark window, prompt line, output lines, highlight rows
tinted in Azure accent, block cursor after the command. Remotion animates:
cursor appears -> output scrolls -> highlight pulses.

Usage: render_terminal_svg.py spec.json -o terminal-plan.svg [--theme config/theme.json]
"""
import argparse
import html
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
VIDEO_COURSE_ROOT = os.path.dirname(HERE)  # tools/ -> video-course/
THEME_CFG = os.path.join(VIDEO_COURSE_ROOT, "config", "theme.json")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("spec")
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--theme", default=THEME_CFG)
    ap.add_argument("--max-lines", type=int, default=24)
    args = ap.parse_args()

    theme = json.load(open(args.theme, encoding="utf-8"))
    spec = json.load(open(args.spec, encoding="utf-8"))
    font = theme["terminal"]["font"]
    size = theme["terminal"]["fontSize"]
    bg, accent = theme["background"], theme["azure"]["primary"]

    output_path = spec["output_file"]
    if not os.path.isabs(output_path):
        # relative output_file resolves against the spec's own directory
        output_path = os.path.join(os.path.dirname(os.path.abspath(args.spec)),
                                   output_path)
    output = open(output_path, encoding="utf-8").read().splitlines()
    output = output[: args.max_lines]
    hl = spec.get("highlight", [])
    rows = [f"$ {spec['command']}"] + output

    w, h = theme["resolution"]["width"] - 192, 80 + int(size * 1.5) * (len(rows) + 1)
    pad, line_h = 40, int(size * 1.5)
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}">',
        f'<rect width="{w}" height="{h}" rx="16" fill="{bg}" stroke="#1E2A44"/>',
        f'<circle cx="52" cy="34" r="7" fill="#FF5F57"/><circle cx="76" cy="34" r="7" '
        f'fill="#FEBC2E"/><circle cx="100" cy="34" r="7" fill="#28C840"/>',
        f'<g font-family="{font}, monospace" font-size="{size}">',
    ]
    y = 80
    for i, row in enumerate(rows):
        highlight = any(t in row for t in hl)
        if highlight:
            parts.append(f'<rect x="16" y="{y - size}" width="{w - 32}" '
                         f'height="{line_h}" rx="6" fill="{accent}" fill-opacity="0.18"/>')
        fill = "#50E6FF" if i == 0 else ("#9BD1FF" if highlight else "#C9D3E8")
        parts.append(f'<text x="{pad}" y="{y}" fill="{fill}">{html.escape(row)}</text>')
        y += line_h
    # block cursor at end of the command line
    cx = pad + len(f"$ {spec['command']}") * int(size * 0.62) + 8
    parts.append(f'<rect id="cursor" x="{cx}" y="{80 - size + 4}" width="{int(size*0.6)}" '
                 f'height="{size}" fill="#50E6FF"/>')
    parts.append("</g></svg>")

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    open(args.out, "w", encoding="utf-8").write("".join(parts))
    print(f"-> {args.out}")


if __name__ == "__main__":
    main()
