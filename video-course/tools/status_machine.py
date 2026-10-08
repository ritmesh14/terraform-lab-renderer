#!/usr/bin/env python3
"""One-way episode status machine (instruction §9).

    DRAFT -> VALIDATED -> APPROVED -> VOICE_COMPLETE -> MEDIA_READY
          -> RENDERED -> FINAL

Rules:
  - statuses only ever move forward through this order
  - MEDIA_READY = media inputs complete (audio + timing + SRT) but the MP4
    has not been rendered/QC-passed yet
  - FINAL requires ALL FOUR validation gates (source coverage, technical
    correctness, learning experience, media quality) — an MP4 existing is
    never sufficient
  - FINAL episodes are never auto-regenerated (explicit --force only)
  - legacy episodes (pre-refactor pipeline) are tagged, not trusted:
    legacy_pipeline: true, needs_revalidation: true
"""
import json
import os

ORDER = ["DRAFT", "VALIDATED", "APPROVED", "VOICE_COMPLETE",
         "MEDIA_READY", "RENDERED", "FINAL"]
RANK = {s: i for i, s in enumerate(ORDER)}


def can_transition(current, new):
    """True if current -> new is allowed (same rank = no-op, allowed)."""
    if current not in RANK or new not in RANK:
        return False
    return RANK[new] >= RANK[current]


def guard(current, new):
    """Raise SystemExit on a downgrade/illegal transition."""
    if not can_transition(current, new):
        raise SystemExit(
            f"illegal status transition {current} -> {new} "
            f"(one-way machine: {' -> '.join(ORDER)})")


def max_of(a, b):
    return a if RANK.get(a, -1) >= RANK.get(b, -1) else b


def migrate_legacy(rec):
    """Tag an episode record produced by the pre-refactor pipeline.

    Old FINAL/RENDERED statuses were granted by the older gates; under the new
    four-gate rules they are marked, not trusted, and never regenerated
    automatically."""
    rec.setdefault("pipeline", "legacy")
    if rec.get("pipeline") == "legacy":
        if rec.get("status") in ("RENDERED", "FINAL"):
            rec["legacy_pipeline"] = True
            rec["needs_revalidation"] = True
    return rec


def load_progress(progress_path):
    if os.path.isfile(progress_path):
        with open(progress_path, encoding="utf-8") as f:
            pr = json.load(f)
    else:
        pr = {"concepts_already_taught": [], "episodes": {}}
    migrated = False
    for rec in pr.get("episodes", {}).values():
        if rec.get("status") in ("RENDERED", "FINAL") and "legacy_pipeline" not in rec:
            migrate_legacy(rec)
            migrated = True
    if migrated and os.path.isfile(progress_path):
        save_progress(progress_path, pr)
    return pr


def save_progress(progress_path, pr):
    with open(progress_path, "w", encoding="utf-8") as f:
        json.dump(pr, f, indent=2)


def get_status(pr, ep):
    return pr["episodes"].get(ep["path"], {}).get("status", "DRAFT")


def set_status(pr, progress_path, ep, status, **fields):
    rec = pr["episodes"].setdefault(ep["path"], {})
    cur = rec.get("status", "DRAFT")
    guard(cur, status)
    rec.update(status=status, pipeline=rec.get("pipeline", "new"),
               **fields)
    save_progress(progress_path, pr)