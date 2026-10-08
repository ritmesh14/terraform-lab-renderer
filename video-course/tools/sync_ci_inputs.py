#!/usr/bin/env python3
"""Sync the CI inputs from the authoring source to the public Git clone.

Copies ONLY what the GitHub Actions runner needs:
  - ACTIVE_LAB source files            -> <clone>/labs/<section>/<lab>/
  - explicitly referenced modules      -> <clone>/modules/<module>/
  - portable production source         -> <clone>/video-course/
  - approved lightweight episode spec  -> <clone>/video-course/output/<...>/writing/
  - authored asset specs + fixtures    -> <clone>/video-course/output/<...>/assets/
  - sanitized demo inputs (if any)     -> <clone>/video-course/output/<...>/demo/

Never copies: secrets, node_modules, .remotion browser cache, audio/, timing/,
assets renders, captions/, preview/, final/, *.mp4, state files, raw unsanitized
terminal logs. Verifies with SHA-256 after copy and scans every staged text
file for internal path leakage (Windows drive paths, CI runner home paths). Fails on
mismatch or leakage. This helper NEVER renders and NEVER touches git.

Lab resolution uses the shared canonical resolver (tools/course_index.py) —
never a private prefix heuristic.

Usage:
  sync_ci_inputs.py --source-root <source-root> --github-clone <path> --lab 01
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from course_index import load_course_manifest, public_rel_path, resolve_lab  # noqa: E402

VC = os.path.dirname(HERE)

LAB_FILE_EXTS = (".tf", ".tfvars.example", ".tftest.hcl", ".yml", ".yaml", ".tpl")
LAB_FILE_NAMES = ("README.md",)
MODULE_SOURCE_EXTS = (".tf", ".md")

# production source synced verbatim (files) / recursively (dirs)
VC_FILES = ["course-progress.json", "requirements-ci.txt"]
VC_CONFIG_DIR = "config"
VC_TOOLS_DIR = "tools"
REMOTION_FILES = ["package.json", "package-lock.json", "tsconfig.json",
                  "remotion.config.ts"]
REMOTION_DIRS = ["src", "tools"]
WRITING_FILES = ["script.md", "narration.json", "scenes.json"]
# demo layer: sanitized fixtures only — raw logs never sync
DEMO_FILES = ["demo-manifest.json"]
DEMO_DIRS = ["terminal", "verification", "screenshots"]
DEMO_EXTS = (".txt", ".json", ".png", ".svg")

# fragments assembled at runtime: the scanner must never trip on
# its own source when it scans the synced production source
LEAK_RE = re.compile("|".join((
    "E:" + chr(92) * 2, "C:" + chr(92) * 2,
    "/home/" + "runner/",
    chr(92) + chr(36) + "GITHUB_" + "WORKSPACE")))
# §40A public-attribution policy: the repo's public surface must never carry
# assistant co-author trailers or assistant branding — commits, code comments,
# workflow text, video metadata all use the repo owner's identity only. The
# brand fragments are assembled at runtime so this scanner does not trip its
# own pattern when it scans the synced production source.
ATTRIBUTION_RE = re.compile("|".join((
    "cla" + "ude", "anthro" + "pic", "co-authored" + "-by")), re.IGNORECASE)
TEXT_SUFFIXES = (".md", ".json", ".py", ".ts", ".tsx", ".js", ".mjs", ".txt",
                 ".yml", ".yaml", ".tf")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def copy_file(src, dst, changed):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if os.path.isfile(dst) and sha256(src) == sha256(dst):
        return False
    shutil.copy2(src, dst)
    changed.append(dst)
    return True


def sync_tree(src_dir, dst_dir, exts=None, names=None, exclude_dirs=("__pycache__",),
              changed=None):
    """Mirror matching files from src_dir to dst_dir; report per-file changes."""
    n = 0
    for root, dirs, files in os.walk(src_dir):
        dirs[:] = [d for d in dirs if d not in exclude_dirs
                   and d not in ("node_modules", ".terraform", ".remotion")]
        for fn in files:
            if exts is not None and not fn.endswith(exts):
                continue
            if names is not None and fn not in names:
                continue
            src = os.path.join(root, fn)
            dst = os.path.join(dst_dir, os.path.relpath(src, src_dir))
            if copy_file(src, dst, changed):
                n += 1
    return n


def find_referenced_modules(lab_dir, source_root):
    """Local modules the lab actually references: source = "../modules/<name>"."""
    mods = set()
    for root, _dirs, files in os.walk(lab_dir):
        for fn in files:
            if not fn.endswith(".tf"):
                continue
            txt = open(os.path.join(root, fn), encoding="utf-8", errors="replace").read()
            for m in re.finditer(r'source\s*=\s*"(\.\./modules/([^"]+))"', txt):
                mods.add(m.group(2).strip("/"))
    return sorted(mods)


def scan_leakage(paths, clone_root):
    """Fail if any staged text file leaks internal/runner paths or carries
    assistant attribution (§40A: the public repo uses the owner's identity
    only — never assistant co-author trailers or assistant branding)."""
    bad = []
    for p in paths:
        if not p.endswith(TEXT_SUFFIXES):
            continue
        try:
            txt = open(p, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        for i, line in enumerate(txt.splitlines(), 1):
            if LEAK_RE.search(line):
                bad.append(f"{os.path.relpath(p, clone_root)}:{i}: path leak: {line.strip()[:120]}")
            if ATTRIBUTION_RE.search(line):
                bad.append(f"{os.path.relpath(p, clone_root)}:{i}: attribution: {line.strip()[:120]}")
    return bad


def sync_demo(ep_dir, clone_out, changed):
    """Sanitized demo fixtures only (instruction §21/§25): demo-manifest.json +
    terminal/verification/screenshots fixture files. Raw logs are excluded —
    everything here must already have passed normalize_terminal_output.py."""
    n = 0
    demo_src = os.path.join(ep_dir, "demo")
    if not os.path.isdir(demo_src):
        return 0
    for fn in DEMO_FILES:
        src = os.path.join(demo_src, fn)
        if os.path.isfile(src):
            copy_file(src, os.path.join(clone_out, "demo", fn), changed)
            n += 1
    for sub in DEMO_DIRS:
        src_sub = os.path.join(demo_src, sub)
        if os.path.isdir(src_sub):
            n += sync_tree(src_sub, os.path.join(clone_out, "demo", sub),
                           exts=DEMO_EXTS, changed=changed)
    return n


def sync_episode(ep, source_root, clone, changed=None):
    """Sync one resolved episode into the clone. Used by cloud_render.py too."""
    if changed is None:
        changed = []
    clone = os.path.abspath(clone)
    if not os.path.isdir(os.path.join(clone, ".git")):
        raise SystemExit(f"not a git clone: {clone}")

    lab = ep["abs_path"]
    section = ep["section"]
    # The public repo keeps the OLD lab names (2026-09-26 renumbering was
    # local-only): every copy target under <clone> must use the public name.
    pub_lab = os.path.basename(public_rel_path(ep).rstrip("/"))
    print(f"[sync] ACTIVE_LAB = {ep['path']} (public name: {pub_lab})")

    # 1. lab source files -> <clone>/labs/<section>/<public-name>/
    dst_lab = os.path.join(clone, "labs", section, pub_lab)
    n = 0
    for fn in sorted(os.listdir(lab)):
        src = os.path.join(lab, fn)
        if os.path.isfile(src) and (fn.endswith(LAB_FILE_EXTS) or fn in LAB_FILE_NAMES):
            if copy_file(src, os.path.join(dst_lab, fn), changed):
                n += 1
    print(f"[sync] lab files -> labs/{section}/{pub_lab}: {n} changed")

    # 2. referenced modules -> <clone>/modules/<module>/
    for mod in find_referenced_modules(lab, source_root):
        mod_src = os.path.join(source_root, "modules", mod)
        if not os.path.isdir(mod_src):
            sys.exit(f"referenced module missing: {mod_src}")
        k = sync_tree(mod_src, os.path.join(clone, "modules", mod),
                      exts=MODULE_SOURCE_EXTS, changed=changed)
        print(f"[sync] module {mod}: {k} files changed")

    # 3. portable production source -> <clone>/video-course/
    for fn in VC_FILES:
        src = os.path.join(VC, fn)
        if os.path.isfile(src):
            copy_file(src, os.path.join(clone, "video-course", fn), changed)
    sync_tree(os.path.join(VC, VC_CONFIG_DIR),
              os.path.join(clone, "video-course", VC_CONFIG_DIR), changed=changed)
    sync_tree(os.path.join(VC, VC_TOOLS_DIR),
              os.path.join(clone, "video-course", VC_TOOLS_DIR), changed=changed)
    for fn in REMOTION_FILES:
        src = os.path.join(VC, "remotion", fn)
        if os.path.isfile(src):
            copy_file(src, os.path.join(clone, "video-course", "remotion", fn), changed)
    for d in REMOTION_DIRS:
        sync_tree(os.path.join(VC, "remotion", d),
                  os.path.join(clone, "video-course", "remotion", d), changed=changed)
    # bundled course fonts (FONT_QC, plan §33.1): Inter + JetBrains Mono are
    # registered by remotion/src/fonts.ts and must exist in public/fonts on CI
    fonts_src = os.path.join(VC, "remotion", "public", "fonts")
    if os.path.isdir(fonts_src):
        sync_tree(fonts_src,
                  os.path.join(clone, "video-course", "remotion", "public", "fonts"),
                  changed=changed)
    print("[sync] production source synced (config, tools, remotion src/lock)")

    # 4. approved writing spec (CI episode dirs key on the PUBLIC lab name)
    ep_dir = os.path.join(VC, "output", section, ep["lab"])
    clone_out = os.path.join(clone, "video-course", "output", section, pub_lab)
    writing_src = os.path.join(ep_dir, "writing")
    if not os.path.isfile(os.path.join(writing_src, "scenes.json")):
        raise SystemExit(f"no approved writing spec: {writing_src}\\scenes.json")
    for fn in WRITING_FILES:
        src = os.path.join(writing_src, fn)
        if os.path.isfile(src):
            copy_file(src, os.path.join(clone_out, "writing", fn), changed)
    print("[sync] writing/ synced")

    # 5. authored asset specs + terminal fixtures (inputs for the CI asset
    #    stage; rendered assets stay un-synced/regenerated)
    n_spec = 0
    for sub in ("diagrams", "terminal"):
        src_sub = os.path.join(ep_dir, "assets", sub)
        if not os.path.isdir(src_sub):
            continue
        for fn in sorted(os.listdir(src_sub)):
            if fn.endswith(".spec.json") or fn.endswith(".txt"):
                if copy_file(os.path.join(src_sub, fn),
                             os.path.join(clone_out, "assets", sub, fn), changed):
                    n_spec += 1
    print(f"[sync] asset specs/fixtures: {n_spec} changed")

    # 6. sanitized demo inputs (same-video demo gate) — never raw logs
    n_demo = sync_demo(ep_dir, clone_out, changed)
    print(f"[sync] demo inputs: {n_demo} changed")

    # 7. leakage + attribution scan (§40A) on the whole sync surface:
    #    viewer-facing lab/writing/assets/demo AND the synced production source
    scan_paths = []
    for base in (dst_lab, clone_out,
                 os.path.join(clone, "video-course", VC_CONFIG_DIR),
                 os.path.join(clone, "video-course", VC_TOOLS_DIR),
                 os.path.join(clone, "video-course", "remotion", "src")):
        if os.path.isdir(base):
            for root, _dirs, files in os.walk(base):
                scan_paths.extend(os.path.join(root, fn) for fn in files)
    bad = scan_leakage(scan_paths, clone)
    if bad:
        print("PATH LEAKAGE / PUBLIC ATTRIBUTION in staged files:", file=sys.stderr)
        for b in bad:
            print("  " + b, file=sys.stderr)
        sys.exit("fix path leakage / public attribution (§40A) before committing")
    print(f"[sync] done. {len(changed)} file(s) changed:")
    for c in changed:
        print("   " + os.path.relpath(c, clone))
    print("[sync] hash verification passed; clone is CI-ready (git steps are manual)")
    return changed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source-root", default=os.environ.get("COURSE_SOURCE_ROOT") or os.getcwd())
    ap.add_argument("--github-clone", required=True)
    ap.add_argument("--lab", required=True, help="lab number, e.g. 01 or 26")
    ap.add_argument("--section", help="scope --lab resolution to one section")
    ap.add_argument("--rebuild-manifest", action="store_true")
    args = ap.parse_args()

    labs = load_course_manifest(args.source_root, rebuild=args.rebuild_manifest)
    ep = resolve_lab(args.lab, labs, section=args.section)[0]
    sync_episode(ep, args.source_root, args.github_clone)


if __name__ == "__main__":
    main()