#!/usr/bin/env python3
"""Validate a course curriculum map (authoring-time gate; NOT a CI G-gate).

Checks course-maps/section-*.json files for:
  - required top-level keys and per-lab required keys
  - classification lists contain only known concept ids (or the section's
    concept_vocabulary / any taught concept from earlier maps)
  - `files` exist under the section source root
  - `prerequisites` are earlier labs (by local folder order) in the same section
  - `source_warnings` reference finding ids in the section source audit
  - `animations` are known transform scene types
  - lab numbering follows the global continuous sequence

Exit 0 = valid; nonzero = problems listed on stderr.

Usage: validate_course_map.py [course-maps/section-02-meta-arguments.json ...]
"""
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
VC = os.path.dirname(HERE)
MAPS = os.path.join(VC, "course-maps")
SOURCE_ROOT = os.environ.get("COURSE_SOURCE_ROOT") or os.getcwd()

KNOWN_ANIMATIONS = {
    "ITERATION_EXPANSION", "STATE_ADDRESS", "FOR_EACH_MAP", "DYNAMIC_BLOCK",
    "SPLAT", "PROVISIONER", "CONDITIONAL", "FLATTEN_MATRIX",
}

REQUIRED_LAB_KEYS = ["lab", "files", "new_concepts", "review_concepts",
                     "extension_concepts", "prerequisites", "source_warnings"]


def fail(msg, problems):
    problems.append(msg)


def taught_concepts():
    """All concept ids from every section map that exists so far."""
    out = set()
    for p in glob.glob(os.path.join(MAPS, "section-*.json")):
        try:
            with open(p, encoding="utf-8") as f:
                data = json.load(f)
            out.update(e["concept"] for e in data.get("taught_concepts", []))
            for lab in data.get("labs", []):
                for k in ("new_concepts", "review_concepts", "extension_concepts"):
                    out.update(c["concept"] for c in lab.get(k, []))
        except (OSError, KeyError, json.JSONDecodeError):
            continue
    return out


def audit_ids(section):
    path = os.path.join(MAPS, "source-audit", f"{section}.json")
    if not os.path.isfile(path):
        return set()
    with open(path, encoding="utf-8") as f:
        return {f_["id"] for f_ in json.load(f).get("findings", [])}


def validate(path, problems):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    section = data.get("section", "")
    base = os.path.join(SOURCE_ROOT, section)
    known = taught_concepts() | set(data.get("concept_vocabulary", []))
    audit = audit_ids(section)

    # two map shapes: taught-concepts maps (section-0N.json with
    # taught_concepts) and curriculum maps (with labs)
    if "taught_concepts" in data and "labs" not in data:
        if not data["taught_concepts"]:
            fail(f"{os.path.basename(path)}: empty taught_concepts", problems)
        for e in data["taught_concepts"]:
            if not e.get("concept") or not e.get("labs"):
                fail(f"{os.path.basename(path)}: taught_concept entry needs "
                     f"'concept' and 'labs'", problems)
        return 0

    labs = data.get("labs", [])
    if not labs:
        fail(f"{os.path.basename(path)}: no lab entries", problems)
    for lab in labs:
        name = lab.get("lab", "<missing>")
        for key in REQUIRED_LAB_KEYS:
            if key not in lab:
                fail(f"{name}: missing required key '{key}'", problems)

        # files exist under the section source root
        for fn in lab.get("files", []):
            if not os.path.isfile(os.path.join(SOURCE_ROOT, section, name, fn)):
                fail(f"{name}: file not found: {section}/{name}/{fn}", problems)

        # concept classification references known ids
        for kind in ("new_concepts", "review_concepts", "extension_concepts"):
            for c in lab.get(kind, []):
                if c["concept"] not in known:
                    fail(f"{name}: unknown concept '{c['concept']}' in {kind}",
                         problems)
            if kind == "new_concepts":
                for c in lab.get(kind, []):
                    if not c.get("teach_as"):
                        fail(f"{name}: new concept '{c['concept']}' lacks teach_as",
                             problems)

        # prerequisites must be earlier labs (numeric) in the same section
        own = int(re.match(r"(\d+)", name).group(1)) if re.match(r"\d", name) else 0
        for pre in lab.get("prerequisites", []):
            pre_num = int(re.match(r"(\d+)", pre).group(1)) if re.match(r"\d", pre) else -1
            if not (0 < pre_num < own):
                fail(f"{name}: prerequisite '{pre}' is not an earlier lab", problems)

        # source warnings reference audit findings
        for w in lab.get("source_warnings", []):
            if w not in audit:
                fail(f"{name}: source_warning '{w}' not in source audit", problems)

        # animations are known types
        for a in lab.get("animations", []):
            if a not in KNOWN_ANIMATIONS:
                fail(f"{name}: unknown animation '{a}'", problems)

    # global numbering continuity: labs keep their global prefix
    expected = None
    for lab in labs:
        m = re.match(r"(\d+)", lab["lab"])
        if not m:
            fail(f"{lab['lab']}: lab name lacks numeric prefix", problems)
            continue
        num = int(m.group(1))
        if expected is not None and num != expected:
            fail(f"{lab['lab']}: expected global number {expected:02d} "
                 f"(labs must be consecutive)", problems)
        expected = num + 1

    return len(labs)


def main():
    args = sys.argv[1:] or sorted(glob.glob(os.path.join(MAPS, "section-*.json")))
    problems = []
    total = 0
    for path in args:
        n = validate(path, problems)
        total += n
        print(f"[map] {os.path.basename(path)}: {n} labs")
    if problems:
        for p in problems:
            print("  FAIL:", p, file=sys.stderr)
        sys.exit(f"{len(problems)} problem(s) in {len(args)} map file(s)")
    print(f"[ok] {total} lab entries valid across {len(args)} map file(s)")


if __name__ == "__main__":
    main()