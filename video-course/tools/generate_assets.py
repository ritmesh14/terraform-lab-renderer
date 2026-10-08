#!/usr/bin/env python3
"""Generate every scene visual asset for one episode from writing/scenes.json.

Deterministic, CI-safe stage: for each scene that references an asset, re-render
it from its authored spec (specs live beside the generated asset as
<name>.spec.json — they are synced to CI, the rendered outputs are not):

  CODE     -> remotion/tools/render_code_html.mjs (Shiki, EXACT lab source)
              + Playwright Chromium screenshot -> assets/code/<name>.png (1920x1080)
  DIAGRAM  -> build_diagram.py --json <spec>  (label-collision gate: exit 3 blocks)
  TERMINAL -> render_terminal_svg.py <spec>

TITLE/CONCEPT/RECAP/NEXT scenes have no asset file — Remotion renders them
natively from scenes.json.

Usage: generate_assets.py <episode_dir> <lab_dir>
"""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
VC = os.path.dirname(HERE)
REMO_TOOLS = os.path.join(VC, "remotion", "tools")


def run(cmd):
    p = subprocess.run(cmd)
    if p.returncode != 0:
        sys.exit(f"asset stage failed (exit {p.returncode}): "
                 f"{' '.join(str(c) for c in cmd)}")


def screenshot_code_html(html_path, png_path):
    """1920x1080 Chromium screenshot of a Shiki code page (matches the
    authoring-PC assets: full viewport, page background fills the frame)."""
    from playwright.sync_api import sync_playwright
    url = "file:///" + html_path.replace("\\", "/").lstrip("/")
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": 1920, "height": 1080},
                                device_scale_factor=1)
        page.goto(url, wait_until="networkidle")
        page.evaluate("() => document.fonts.ready")
        overflow = page.evaluate(
            "() => Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)")
        page.screenshot(path=png_path, full_page=overflow > 1080)
        browser.close()
    if overflow > 1080:
        print(f"    note: content height {overflow}px > 1080 — full-page screenshot")


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: generate_assets.py <episode_dir> <lab_dir>")
    ep_dir, lab_dir = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
    scenes_path = os.path.join(ep_dir, "writing", "scenes.json")
    scenes = json.load(open(scenes_path, encoding="utf-8"))["scenes"]

    n = 0
    for sc in scenes:
        asset = sc.get("asset")
        if not asset:
            continue
        out = os.path.join(ep_dir, *asset.split("/"))
        os.makedirs(os.path.dirname(out), exist_ok=True)
        kind = sc["type"]
        if kind == "CODE":
            html_out = os.path.splitext(out)[0] + ".html"
            hl = ",".join(str(x) for x in sc.get("highlight_lines", []))
            run(["node", os.path.join(REMO_TOOLS, "render_code_html.mjs"),
                 os.path.join(lab_dir, sc["source_file"]),
                 str(sc["start_line"]), str(sc["end_line"]), html_out, hl])
            screenshot_code_html(html_out, out)
        elif kind == "DIAGRAM":
            spec = os.path.splitext(out)[0] + ".spec.json"
            if not os.path.isfile(spec):
                sys.exit(f"missing diagram spec: {spec}")
            run([sys.executable, os.path.join(HERE, "build_diagram.py"),
                 "--json", spec, "-o", out])
        elif kind == "TERMINAL":
            spec = os.path.splitext(out)[0] + ".spec.json"
            if not os.path.isfile(spec):
                sys.exit(f"missing terminal spec: {spec}")
            run([sys.executable, os.path.join(HERE, "render_terminal_svg.py"),
                 spec, "-o", out])
        else:
            # no asset file for this visual_type. Asset-less transform types
            # (ITERATION_EXPANSION, STATE_ADDRESS, FOR_EACH_MAP, and the
            # later transform family) render themselves in Remotion from
            # scenes.json data — never pre-rendered images, so nothing to
            # generate here.
            continue
        print(f"[assets] {asset}")
        n += 1
    print(f"[assets] generated {n} asset(s) for {os.path.basename(ep_dir)}")


if __name__ == "__main__":
    main()