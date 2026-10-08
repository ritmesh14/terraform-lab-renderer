#!/usr/bin/env python3
"""Build source-manifest.json for a lab: the permitted source scope.

The manifest must match the REAL lab (instruction §6): every relevant
educational/source file — *.tf, README.md, *.tfvars.example, *.tftest.hcl,
*.yml, *.yaml — plus, for referenced local modules, their *.tf + README.md.
Every file gets a relative path, a category and a SHA-256 hash; relative
paths are the persistent identity (portable across authoring PC and CI),
absolute internal paths stay runtime metadata.

Also records the viewer-facing public GitHub location derived from the path
relative to the source root (the source root stays internal — viewers see the repo).

Usage: build_manifest.py <lab-dir> [--out source-manifest.json]
"""
import argparse
import hashlib
import json
import os
import re

RE_MODULE = re.compile(r'(?ms)^\s*module\s+"([^"]+)"\s*\{(.*?)\}')
RE_SOURCE = re.compile(r'source\s*=\s*"([^"]+)"')

SOURCE_ROOT = os.environ.get("COURSE_SOURCE_ROOT") or os.getcwd()
HERE = os.path.dirname(os.path.abspath(__file__))
VIDEO_COURSE_ROOT = os.path.dirname(HERE)  # tools/ -> video-course/
COURSE_CFG = os.path.join(VIDEO_COURSE_ROOT, "config", "course.json")

LAB_EXTS = (".tf", ".tfvars.example", ".tftest.hcl", ".yml", ".yaml")
LAB_NAMES = ("README.md",)
MODULE_EXTS = (".tf", ".md")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def collect_files(dirpath, exts, names):
    if not os.path.isdir(dirpath):
        return []
    out = []
    for f in sorted(os.listdir(dirpath)):
        if f.endswith(exts) or f in names:
            p = os.path.join(dirpath, f)
            if os.path.isfile(p):
                out.append(p)
    return out


def category_for(rel_path):
    base = os.path.basename(rel_path).lower()
    if base.endswith(".tf"):
        return "terraform"
    if base == "readme.md":
        return "documentation"
    if base.endswith(".tfvars.example"):
        return "variables_example"
    if base.endswith(".tftest.hcl"):
        return "tests"
    if base.endswith((".yml", ".yaml")):
        return "automation"
    return "other"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("lab_dir")
    ap.add_argument("--out", help="write JSON here (default: stdout)")
    args = ap.parse_args()

    lab_abs = os.path.abspath(args.lab_dir)
    course = json.load(open(COURSE_CFG, encoding="utf-8"))
    source_root = course.get("source_root", SOURCE_ROOT)
    rel = os.path.relpath(lab_abs, source_root).replace("\\", "/")

    files, module_entries, remote_modules = [], [], []
    visited = set()
    queue = collect_files(lab_abs, LAB_EXTS, LAB_NAMES)

    while queue:
        path = queue.pop()
        path = os.path.abspath(path)
        if path in visited or not os.path.isfile(path):
            continue
        visited.add(path)
        files.append(path)
        text = open(path, encoding="utf-8").read()
        if not path.endswith(".tf"):
            continue
        for name, body in RE_MODULE.findall(text):
            m = RE_SOURCE.search(body)
            if not m:
                continue
            source = m.group(1)
            if source.startswith((".", "..")):
                mod_dir = os.path.normpath(os.path.join(os.path.dirname(path), source))
                module_entries.append({"name": name, "source": source,
                                       "resolved": os.path.abspath(mod_dir)})
                queue.extend(collect_files(mod_dir, MODULE_EXTS, LAB_NAMES))
            else:
                remote_modules.append({"name": name, "source": source})

    # persistent identity = portable relative paths + content hashes
    def entry(abs_path):
        r = os.path.relpath(abs_path, lab_abs).replace("\\", "/")
        return {"relative_path": r, "category": category_for(r),
                "sha256": sha256(abs_path)}

    manifest = {
        "source_root_internal": source_root,
        "active_lab_internal": lab_abs,
        "active_lab_relative": rel,
        "public_repository": course["public_repository"],
        "public_labs_root": course["public_labs_root"],
        "public_lab_url": f"{course['public_labs_root']}/{rel}",
        "files": [entry(p) for p in files],
        # runtime scope (absolute, regenerated per-machine — never the
        # persistent identity):
        "source_root": source_root,
        "lab": lab_abs,
        "active_lab": lab_abs,
        "lab_path": rel,
        "permitted_source_files": files,
        "local_modules": module_entries,
        "remote_modules": remote_modules,
    }
    out = json.dumps(manifest, indent=2)
    if args.out:
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(out)
        print(f"-> {args.out} ({len(files)} files, "
              f"{len(module_entries)} local modules, {len(remote_modules)} remote)")
    else:
        print(out)


if __name__ == "__main__":
    main()