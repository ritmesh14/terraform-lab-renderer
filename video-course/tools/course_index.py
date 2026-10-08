#!/usr/bin/env python3
"""Shared course index: THE one lab resolver for every tool.

All scripts that need to turn "Lab 17" (or "17", or a folder name) into
ACTIVE_LAB must use this module — never a private prefix-matching heuristic
(generate_course.py and sync_ci_inputs.py used to disagree; that is the bug
this module removes).

Resolution order (course policy):
  1. numeric directory prefix   "NN-…" under any section-*
  2. course-manifest.json mapping (canonical global numbering)
  3. ordered discovery index (discover_labs.py order)
Ambiguity fails loudly; nothing is ever guessed.

Importable (from generate_course.py, sync_ci_inputs.py, cloud_render.py,
tests, …) AND runnable as a CLI for debugging:

    course_index.py resolve --lab 17 [--root <source-root>]
    course_index.py discover [--root <source-root>]
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
VC = os.path.dirname(HERE)  # tools/ -> video-course/
MANIFEST = os.path.join(VC, "course-manifest.json")
COURSE_CFG = os.path.join(VC, "config", "course.json")


def course_cfg():
    with open(COURSE_CFG, encoding="utf-8") as f:
        return json.load(f)


def renumber_map():
    """old<->new lab-name mapping (2026-09-26 global renumbering). Local
    folders carry the global number; the public GitHub repo keeps OLD names."""
    path = os.path.join(VC, "course-maps", "renumber-map.json")
    if not os.path.isfile(path):
        return {}
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    out = {}
    for r in data.get("renames", []):
        out.setdefault(r["section"], {})[r["new"]] = r["old"]
    return out


def public_rel_path(ep):
    """Repo-relative lab path as it exists in the PUBLIC repo. After the
    2026-09-26 renumbering the local folder name and the public folder name
    differ for sections 02+; the public name is what viewers' URLs use."""
    if ep.get("public_path"):
        return ep["public_path"].replace("\\", "/")
    sec_map = renumber_map().get(ep["section"], {})
    old = sec_map.get(ep["lab"])
    if old:
        return f"{ep['section']}/{old}"
    return ep["path"].replace("\\", "/")


def public_lab_url(ep, course=None):
    """Viewer-facing GitHub URL for a lab episode record (never a local path)."""
    course = course or course_cfg()
    return f"{course['public_labs_root']}/{public_rel_path(ep)}"


def discover_labs(root):
    """Ordered discovery index (section-*, NN- name, contains .tf)."""
    sys.path.insert(0, HERE)
    from discover_labs import discover  # single source of ordering truth
    return discover(root)


def load_course_manifest(root, rebuild=False, manifest_path=None):
    """Canonical lab-number -> lab mapping. rebuild=True re-discovers against
    `root` (CI: the committed manifest records authoring-PC paths)."""
    manifest_path = manifest_path or MANIFEST
    if not rebuild and os.path.isfile(manifest_path):
        with open(manifest_path, encoding="utf-8") as f:
            return json.load(f)["labs"]
    labs = discover_labs(root)
    course = course_cfg()
    rmap = renumber_map()
    doc = {"labs": []}
    for i, ep in enumerate(labs):
        ep = dict(ep)
        old = rmap.get(ep["section"], {}).get(ep["lab"])
        if old:
            ep["public_path"] = f"{ep['section']}/{old}"
        doc["labs"].append({**ep, "number": i + 1,
                            "public_lab_url": public_lab_url(ep, course)})
    os.makedirs(os.path.dirname(manifest_path), exist_ok=True)
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(doc, f, indent=2)
    return doc["labs"]


def resolve_lab(lab_ref, labs, section=None):
    """'01' / '1' / exact dir name / unique substring, optionally scoped to a
    section. Ambiguous -> SystemExit; nothing is ever guessed.

    section=None keeps the legacy behavior (section-01 CI stays green): a bare
    'NN' prefix that matches several sections falls through to the canonical
    manifest number, with a stderr warning so the trap is visible."""
    if lab_ref in (None, "all"):
        return list(labs)
    ref = str(lab_ref)

    # 0. exact path match ("section-02-meta-arguments/26-count-meta-argument")
    norm = ref.replace("\\", "/").strip("/")
    if "/" in norm:
        path_hits = [l for l in labs
                     if l["path"].replace("\\", "/") == norm]
        if len(path_hits) == 1:
            return path_hits
        if not path_hits:
            raise SystemExit(f"lab '{lab_ref}': no lab with that exact path")

    # optional section scoping (exact section name only — no fuzzy match)
    scoped = labs
    if section is not None:
        scoped = [l for l in labs if l["section"] == section]
        if not scoped:
            raise SystemExit(f"section '{section}' has no labs")

    prefix_hits = [l for l in scoped if l["lab"].startswith(ref.zfill(2) + "-")]
    name_hits = [l for l in scoped if ref.lower() in l["lab"].lower()]
    number_hits = [l for l in scoped if ref.lstrip("0").isdigit()
                   and l.get("number") == int(ref.lstrip("0"))]
    if len(prefix_hits) == 1:
        return prefix_hits
    if number_hits:
        if section is None and len(prefix_hits) > 1:
            # bare NN matches NN- folders in several sections: the manifest
            # number decides (legacy fallback), but say so loudly.
            print(f"warning: lab '{ref}' matches NN- prefixes in "
                  f"{len(prefix_hits)} sections; using manifest global number "
                  f"{number_hits[0]['number']} — pass --section to disambiguate",
                  file=sys.stderr)
        return number_hits[:1]  # canonical global numbering from the manifest
    if len(name_hits) == 1:
        return name_hits
    cand = (prefix_hits or name_hits)[:5]
    hint = f" (within section '{section}')" if section else ""
    raise SystemExit(
        f"lab '{lab_ref}'{hint} is unknown or ambiguous. "
        f"Candidates: {[c['path'] for c in cand]}")


def episode_dir(ep, video_course_root=None):
    """Episode folder: <video-course>/output/<section>/<lab> (portable: same on
    the authoring PC and the CI runner)."""
    vc = video_course_root or VC
    return os.path.join(vc, "output", ep["section"], ep["lab"])


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("cmd", choices=["resolve", "discover"])
    ap.add_argument("--lab")
    ap.add_argument("--section", help="scope resolution to one section")
    ap.add_argument("--root", default=os.environ.get("COURSE_SOURCE_ROOT") or os.getcwd())
    ap.add_argument("--rebuild-manifest", action="store_true")
    args = ap.parse_args()
    labs = load_course_manifest(args.root, rebuild=args.rebuild_manifest)
    if args.cmd == "discover":
        print(json.dumps(labs, indent=2))
        return
    hits = resolve_lab(args.lab, labs, section=args.section)
    print(json.dumps(hits, indent=2))


if __name__ == "__main__":
    main()