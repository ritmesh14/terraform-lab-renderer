#!/usr/bin/env python3
"""Rebuild course-progress.json concepts_already_taught from the course maps.

Merges the curated section maps in <video-course>/course-maps/section-*.json
(each maps canonical concept ids -> labs that taught them) into the sorted,
deduped `concepts_already_taught` list in course-progress.json, and sets
`current_section` to the next section to produce.

Idempotent: running twice changes nothing. Never touches `episodes` entries —
statuses are owned by the status machine, not this tool.

Usage: build_concept_memory.py [--sections section-01-foundations,...]
"""
import argparse
import glob
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
VC = os.path.dirname(HERE)
MAPS = os.path.join(VC, "course-maps")
PROGRESS = os.path.join(VC, "course-progress.json")

SECTION_ORDER = [
    "section-01-foundations",
    "section-02-meta-arguments",
    "section-03-web-apps-and-databases",
    "section-04-modules-and-networking",
    "section-05-operations-and-landing-zones",
    "section-06-workflows-and-cicd",
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sections", help="comma-separated section map names "
                                       "(default: every section-*.json map)")
    args = ap.parse_args()

    wanted = (args.sections.split(",") if args.sections
              else [os.path.basename(p) for p in
                    glob.glob(os.path.join(MAPS, "section-*.json"))])

    concepts = set()
    for name in sorted(wanted):
        path = os.path.join(MAPS, name)
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        for entry in data["taught_concepts"]:
            concepts.add(entry["concept"])
        print(f"[map] {name}: {len(data['taught_concepts'])} concepts")

    # sections with a map count as taught; current_section = next in order
    taught_sections = sorted({name[:-len(".json")] for name in wanted})
    current = 1
    for i, sec in enumerate(SECTION_ORDER, start=1):
        if sec in taught_sections:
            current = i + 1

    with open(PROGRESS, encoding="utf-8") as f:
        progress = json.load(f)

    before = sorted(progress.get("concepts_already_taught") or [])
    after = sorted(concepts)
    if before == after and progress.get("current_section") == current:
        print(f"[ok] already up to date: {len(after)} concepts, "
              f"current_section={current}")
        return

    progress["concepts_already_taught"] = after
    progress["current_section"] = current
    with open(PROGRESS, "w", encoding="utf-8", newline="\n") as f:
        json.dump(progress, f, indent=1, ensure_ascii=False)
    print(f"[ok] concepts_already_taught: {len(before)} -> {len(after)}; "
          f"current_section -> {current} (episodes untouched)")


if __name__ == "__main__":
    main()