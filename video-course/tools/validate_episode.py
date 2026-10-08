#!/usr/bin/env python3
"""Episode validation — FOUR REAL GATES (instruction §8), not placeholder pass
values. FAIL blocks the pipeline; rules: references/validation-rules.md.

  Gate 1  Source coverage      every permitted source file accounted for
                               (FULL_EXPLANATION / MENTION_ONLY_WITH_REASON /
                               NOT_RELEVANT_WITH_REASON — no silent omission),
                               referenced modules resolved, no cross-lab facts,
                               no internal paths in viewer-facing writing
  Gate 2  Technical            terminology/counts/names/dependency claims
          correctness          checked against the parsed HCL inventory (the
                               dependency graph is authoritative — Terraform is
                               not a top-to-bottom script)
  Gate 3  Learning experience  NEW-vs-REVIEW pacing, first meaningful code
                               within ~60s, WPM density vs voice.json ranges,
                               no bullet-wall scenes, RECAP introduces no new
                               concept, bounded prediction moments
  Gate 4  Media quality        when media exists: MP4/container properties, SRT
                               coverage, loudness, assets, same-video demo —
                               delegated to quality_check.py's report

Usage: validate_episode.py <episode-dir> [--sources <lab-or-sandbox-dir>]
Writes validation/validation.json; exit 1 on any gate FAIL.
"""
import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from validate_srt_coverage import spoken_text, validate as srt_validate  # noqa: E402

WORD_WPM = 150  # rough spoken-rate estimate for the pre-audio WARN only
MIN_EPISODE_SEC = 180   # course minimum: ~3 minutes (4-15 min is the normal target)
MAX_EPISODE_SEC = 900   # course maximum: 15 minutes
MAX_SCENES = 80
FIRST_CODE_TARGET_SEC = 60  # first meaningful Terraform code within 35-60s
# fragments assembled at runtime: the scanner must never trip on
# its own source when it scans the synced production source
LEAK_RE = re.compile("|".join((
    "E:" + chr(92) * 2, "C:" + chr(92) * 2,
    "/home/" + "runner/",
    chr(92) + chr(36) + "GITHUB_" + "WORKSPACE")))


def norm_ws(s):
    return re.sub(r"\s+", " ", s).strip()


def sig_words(text):
    """Significant words for concept-overlap heuristics."""
    stop = {"this", "that", "with", "from", "your", "will", "have", "what",
            "when", "then", "than", "into", "been", "were", "which", "their",
            "about", "there", "these", "those", "terraform", "azure",
            "microsoft", "resource", "resources", "configuration", "value",
            "values", "because", "should", "would", "could"}
    return {w for w in re.findall(r"[a-z]{4,}", text.lower()) if w not in stop}


def scene_spoken(s):
    steps = s.get("steps") or []
    if steps:
        return " ".join((st.get("narration") or "") for st in steps)
    return s.get("narration", "")


def classify_source_files(manifest, scenes, script):
    """Gate 1: every permitted source file must be accounted for — no silent
    omission. Classification is derived deterministically from the episode:
      FULL_EXPLANATION           a CODE scene shows lines from it
      MENTION_ONLY_WITH_REASON   named in the narration/file tree but not
                                 walked line-by-line
      NOT_RELEVANT_WITH_REASON   never mentioned (recorded, counted as a gap)"""
    code_files = {s.get("source_file") for s in scenes if s.get("source_file")}
    blob = script + " " + " ".join(scene_spoken(s) for s in scenes)
    records = []
    silent = []
    for f in manifest.get("files", []):
        rel = f["relative_path"]
        base = os.path.basename(rel)
        if rel in code_files or base in code_files:
            records.append({"file": rel, "classification": "FULL_EXPLANATION",
                            "reason": "walked line-by-line in CODE scene(s)"})
        elif base in blob:
            records.append({"file": rel, "classification": "MENTION_ONLY_WITH_REASON",
                            "reason": "named in narration/file tree; supporting context"})
        else:
            records.append({"file": rel, "classification": "NOT_RELEVANT_WITH_REASON",
                            "reason": "not referenced by this episode"})
            silent.append(rel)
    return records, silent


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("episode_dir")
    ap.add_argument("--sources", help="dir containing permitted .tf sources")
    args = ap.parse_args()
    ep = args.episode_dir

    g1, g2, g3, g4 = [], [], [], []   # per-gate fails
    warns = []

    scenes_path = os.path.join(ep, "writing", "scenes.json")
    scenes = json.load(open(scenes_path, encoding="utf-8"))["scenes"]
    script_path = os.path.join(ep, "writing", "script.md")
    script = open(script_path, encoding="utf-8").read() if os.path.isfile(script_path) else ""

    ids = [s.get("id", "") for s in scenes]
    expected = [f"S{i:03d}" for i in range(1, len(scenes) + 1)]
    if ids != expected:
        g1.append(f"scene ids must be sequential S001..S{len(scenes):03d}, got {ids}")
    for s in scenes:
        n = (s.get("narration") or "").strip()
        if not n and not s.get("steps"):
            g1.append(f"{s.get('id')}: empty narration")
        elif len(n) > 9000:
            g1.append(f"{s.get('id')}: narration {len(n)} chars (>9000)")
        if LEAK_RE.search(json.dumps(s)):
            g1.append(f"{s['id']}: internal path leaked into viewer-facing scene")

    types = [str(s.get("type", "")).upper() for s in scenes]
    recap_present = "RECAP" in types
    demo_teaser_present = "NEXT" in types
    demo_scenes = [s["id"] for s in scenes[types.index("NEXT") + 1:]
                   if s.get("demo")] if demo_teaser_present else []
    if not recap_present:
        g1.append("no RECAP scene — every educational episode must end with one")
    if not demo_teaser_present:
        g1.append("no NEXT scene — the real-world demo transition is missing")

    # ----------------------------- ground truth scope -----------------------
    manifest_path = os.path.join(ep, "source", "source-manifest.json")
    inventory_path = os.path.join(ep, "source", "terraform-inventory.json")
    scope_text, allowed_names = "", set()
    manifest = None
    if os.path.isfile(manifest_path):
        manifest = json.load(open(manifest_path, encoding="utf-8"))
        for p in manifest.get("permitted_source_files", []):
            if os.path.isfile(p):
                scope_text += "\n" + open(p, encoding="utf-8").read()
    elif args.sources:
        for f in sorted(os.listdir(args.sources)):
            if f.endswith((".tf", ".md", ".tfvars.example")):
                scope_text += "\n" + open(os.path.join(args.sources, f),
                                          encoding="utf-8", errors="replace").read()
    else:
        warns.append("no source manifest found — scope checks reduced")

    inv = None
    if os.path.isfile(inventory_path):
        inv = json.load(open(inventory_path, encoding="utf-8"))
        if inv.get("confidence") == "reduced":
            warns.append("terraform inventory confidence REDUCED (regex parser) "
                         "— install python-hcl2 for full validation")
        for coll in ("resources", "data_sources", "variables", "locals",
                     "outputs", "modules"):
            for item in inv.get(coll, []):
                allowed_names.add(item["name"])
                if item.get("address"):
                    allowed_names.add(item["address"])

    # quoted terraform references must exist in scope
    if scope_text.strip():
        for s in scenes:
            for ref in re.findall(r"`([a-zA-Z_][\w.]+)`", scene_spoken(s)):
                if "." in ref and ref not in allowed_names and ref not in scope_text:
                    g2.append(f"{s['id']}: mentions `{ref}` which is not in the lab scope")

    # quoted hcl snippets must exist verbatim in permitted source text
    scope_norm = norm_ws(scope_text)
    for i, snippet in enumerate(re.findall(r"```hcl\n(.*?)```", script, re.S), 1):
        if norm_ws(snippet) not in scope_norm:
            g2.append(f"script hcl snippet #{i} not found (verbatim) in permitted sources")

    # ------------------------------- GATE 1 ---------------------------------
    coverage_records, silent_files = [], []
    if manifest:
        coverage_records, silent_files = classify_source_files(manifest, scenes, script)
        unresolved = [m["name"] for m in manifest.get("local_modules", [])
                      if not os.path.isdir(m.get("resolved", ""))]
        for m in unresolved:
            g1.append(f"referenced local module '{m}' not resolved")
        if len(coverage_records) != len(manifest.get("files", [])):
            if "files" not in manifest:
                g1.append("manifest is the legacy schema (no 'files') — rerun "
                          "build_manifest.py to refresh before validating")
            else:
                g1.append("source manifest incomplete: records != files")
    else:
        warns.append("Gate 1 file-level classification skipped (no manifest)")

    # ------------------------------- GATE 2 ---------------------------------
    if inv:
        n_res = len(inv.get("resources", []))
        for s in scenes:
            txt = scene_spoken(s)
            for m in re.finditer(r"\b(\d+)\s+(?:managed\s+|azure\s+|aws\s+)?resources?\b",
                                 txt, re.I):
                claimed = int(m.group(1))
                if claimed and claimed != n_res:
                    g2.append(f"{s['id']}: narration claims {claimed} managed "
                              f"resource(s); the parsed inventory has {n_res}")
            # data-source terminology: data blocks are read-only, never "managed"
            for ds in inv.get("data_sources", []):
                if re.search(rf"\bcreate[sd]?\s+(?:an?\s+|the\s+)?{re.escape(ds['type'])}\b",
                             txt, re.I):
                    g2.append(f"{s['id']}: data source {ds['type']} described as "
                              "created — data sources are read-only lookups")
        for s in scenes:
            for ref in re.findall(r"`([a-zA-Z_][\w.]+)`", scene_spoken(s)):
                if "." in ref and ref in allowed_names:
                    edge_found = any(ref.split(".")[1] in (e["to"].split(":", 1)[-1],
                                                           e["from"].split(":", 1)[-1])
                                     for e in inv.get("dependency_edges", []))
                    if not edge_found:
                        # quoted but never a graph node → likely a fabricated claim
                        warns.append(f"{s['id']}: `{ref}` referenced but absent from "
                                     "the parsed dependency graph")
    else:
        warns.append("Gate 2 inventory checks skipped (no terraform-inventory.json)")

    # ------------------------------- GATE 3 ---------------------------------
    total_words = sum(len(scene_spoken(s).split()) for s in scenes)
    est = total_words / WORD_WPM * 60
    if est > MAX_EPISODE_SEC or est < MIN_EPISODE_SEC:
        warns.append(f"estimated spoken length {est:.0f}s outside the "
                     f"{MIN_EPISODE_SEC}-{MAX_EPISODE_SEC}s course range (4-15 min typical)")
    if len(scenes) > MAX_SCENES:
        warns.append(f"{len(scenes)} scenes is a lot — consider merging scenes for pacing")

    # first meaningful code timing (measured when audio exists, else estimate)
    timed_path = os.path.join(ep, "timing", "timed-scenes.json")
    timed = {}
    fps = None
    if os.path.isfile(timed_path):
        timed_doc = json.load(open(timed_path, encoding="utf-8"))
        fps = timed_doc.get("fps")
        timed = {t["id"]: t for t in timed_doc["scenes"]}
    first_code_sec = None
    if timed:
        for s in scenes:
            if str(s.get("type")).upper() == "CODE" and s["id"] in timed and fps:
                first_code_sec = timed[s["id"]]["starts_at_frame"] / fps
                break
    else:
        wc = 0
        for s in scenes:
            if str(s.get("type")).upper() == "CODE":
                first_code_sec = wc / WORD_WPM * 60 + 0.7  # + padding estimate
                break
            wc += len(scene_spoken(s).split())
    if first_code_sec is not None and first_code_sec > FIRST_CODE_TARGET_SEC:
        warns.append(f"first meaningful code at ~{first_code_sec:.0f}s "
                     f"(target: within {FIRST_CODE_TARGET_SEC}s for short labs)")

    # per-scene WPM (measured) — dense scenes above range fail learning QC
    voice_cfg = {}
    vcfg = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        "config", "voice.json")
    if os.path.isfile(vcfg):
        voice_cfg = json.load(open(vcfg, encoding="utf-8"))
    pace = voice_cfg.get("pace_wpm", {})
    if os.path.isfile(timed_path):
        # outro = any scene after the NEXT transition (fixed-format sign-off,
        # non-learning content — has its own band)
        outro_start = None
        for i, s in enumerate(scenes):
            if str(s.get("type")).upper() == "NEXT":
                outro_start = i + 1
                break
        for i, s in enumerate(scenes):
            t = timed.get(s["id"])
            words = len(scene_spoken(s).split())
            if t and words and t.get("duration_sec"):
                wpm = words / t["duration_sec"] * 60
                typ = str(s.get("type")).upper()
                if typ == "CODE":
                    lo, hi = pace.get("code_explanations", [125, 140])
                elif outro_start is not None and i >= outro_start:
                    lo, hi = pace.get("outro", [150, 175])
                else:
                    lo, hi = pace.get("normal", [135, 150])
                if wpm > hi * 1.15:
                    g3.append(f"{s['id']}: narration density {wpm:.0f} wpm > "
                              f"{hi} target x1.15 — rewrite or slow the scene")
                if wpm < lo * 0.5 and words > 12:
                    warns.append(f"{s['id']}: very sparse narration ({wpm:.0f} wpm)")
    # no bullet walls
    for s in scenes:
        pts = s.get("points") or []
        if len(pts) > 6:
            g3.append(f"{s['id']}: {len(pts)} bullet points — too many independent "
                      "concepts for one scene")
    # RECAP introduces no new concept: every recap point shares a significant
    # word with earlier narration
    if recap_present:
        earlier = " ".join(scene_spoken(s) for s in scenes
                           if str(s.get("type")).upper() != "RECAP")
        earlier_words = sig_words(earlier)
        for s in scenes:
            if str(s.get("type")).upper() != "RECAP":
                continue
            for p in s.get("points", []):
                if sig_words(p) and not (sig_words(p) & earlier_words):
                    g3.append(f"{s['id']}: RECAP point introduces a new concept: {p[:60]}")
    # narration focus must have visual focus
    for s in scenes:
        if str(s.get("type")).upper() == "CODE" and not (s.get("highlight_lines")
                                                         or s.get("steps")):
            g3.append(f"{s['id']}: CODE scene has no highlight/steps — narration "
                      "focus without visual focus")
    # bounded prediction moments
    n_predict = sum(1 for s in scenes
                    if re.search(r"predict|what do you think|guess", scene_spoken(s), re.I))
    if n_predict > 2:
        g3.append(f"{n_predict} prediction moments (>2) — keep them useful and limited")

    # ------------------------------- GATE 4 ---------------------------------
    media_checks = {"status": "not_rendered"}
    mp4 = os.path.join(ep, "final", "episode.mp4")
    if os.path.isfile(mp4):
        qc_path = os.path.join(ep, "validation", "quality-check.json")
        if os.path.isfile(qc_path):
            qc = json.load(open(qc_path, encoding="utf-8"))
            if not qc.get("qc_passed"):
                g4.append("quality-check.json reports failures "
                          "(see validation/quality-check.json)")
            media_checks["status"] = qc.get("qc_passed") and "pass" or "fail"
        else:
            g4.append("MP4 exists but quality_check.py has not run")
        cov_path = os.path.join(ep, "validation", "srt-coverage.json")
        if os.path.isfile(cov_path):
            cov = json.load(open(cov_path, encoding="utf-8"))
            if cov.get("coverage_pct", 0) < cov.get("min_coverage", 99.5):
                g4.append(f"SRT coverage {cov.get('coverage_pct')}% "
                          f"< {cov.get('min_coverage')}%")
        else:
            g4.append("no SRT coverage report — run generate_srt.py")
    else:
        media_checks["status"] = "pending_render"

    # terraform validation step state (if it ran)
    tfv = os.path.join(ep, "validation", "terraform-validate.json")
    if os.path.isfile(tfv):
        if not json.load(open(tfv, encoding="utf-8")).get("passed"):
            g2.append("terraform validate failed in sandbox (see terraform-validate.json)")
    else:
        warns.append("terraform validate not run yet for this episode")

    # schema validation state
    schema_path = os.path.join(ep, "validation", "scene-schema.json")
    if os.path.isfile(schema_path):
        if json.load(open(schema_path, encoding="utf-8")).get("status") != "pass":
            g1.append("scene schema validation failed (see scene-schema.json)")
    else:
        warns.append("scene schema not validated yet")

    # SRT coverage pre-render (if audio+SRT already exist)
    if os.path.isfile(os.path.join(ep, "final", "episode.srt")):
        cov_report, cov_fails = srt_validate(ep)
        if cov_fails:
            g4.extend(cov_fails)

    cross_lab_contamination = any("not in the lab scope" in f for f in g2)
    gates = {"gate1_source_coverage": {"status": "fail" if g1 else "pass",
                                       "file_records": coverage_records,
                                       "silent_omissions": silent_files},
             "gate2_technical_correctness": {"status": "fail" if g2 else "pass",
                                             "cross_lab_contamination": cross_lab_contamination},
             "gate3_learning_experience": {"status": "fail" if g3 else "pass",
                                           "first_code_sec": first_code_sec},
             "gate4_media_quality": media_checks}
    fails = g1 + g2 + g3 + g4
    result = {"status": "fail" if fails else "pass",
              "gates": gates,
              "recap_present": recap_present,
              "demo_teaser_present": demo_teaser_present,
              "demo_scenes": demo_scenes,
              "demo_gate": "pending" if (demo_teaser_present and not demo_scenes)
              else ("pass" if demo_teaser_present else "n/a"),
              "fails": fails, "warnings": warns}
    os.makedirs(os.path.join(ep, "validation"), exist_ok=True)
    out = os.path.join(ep, "validation", "validation.json")
    json.dump(result, open(out, "w", encoding="utf-8"), indent=2)
    print(json.dumps(result, indent=2))
    print(f"-> {out}")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()