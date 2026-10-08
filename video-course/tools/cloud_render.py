#!/usr/bin/env python3
"""Cloud render trigger (instruction §24): push the heavy render to the free
GitHub Actions ubuntu-latest runner for the public repository.

Responsibilities:
  resolve lab (shared course_index) -> sync CI inputs -> verify no
  secrets/internal paths -> trigger .github/workflows/render-course-video.yml
  -> show run URL -> optionally wait -> download the final artifact.

Uses the GitHub CLI (`gh`) when available. If gh is missing, prints the exact
commands instead of silently falling back to heavy local rendering.

Usage:
  cloud_render.py --lab 01 [--wait] [--clone C:/Users/.../GitHub/<repo>]
"""
import argparse
import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from course_index import (episode_dir, load_course_manifest, public_rel_path,
                          resolve_lab)  # noqa: E402
from sync_ci_inputs import sync_episode  # noqa: E402

WORKFLOW = "render-course-video.yml"
DEFAULT_REPO = "RIT-MESH/Terraform-Azure-Labs-and-Case_Studies"
DEFAULT_CLONE = os.path.join(os.path.expanduser("~"), "Documents", "GitHub",
                             "Terraform-Azure-Labs-and-Case_Studies")


def lab_number(ep):
    """Full numeric prefix of the lab folder. After the 2026-09-26 global
    renumbering this equals the canonical manifest number, which CI resolves
    against its own identically-ordered manifest (full digits — [:2] would
    truncate 100+)."""
    return re.match(r"(\d+)", ep["lab"]).group(1)


def gh(*gh_args, check=True):
    return subprocess.run(["gh", *gh_args], check=check)


def trigger(ep, source_root, section=None):
    """Sync CI inputs + dispatch the workflow. Returns the run id."""
    clone = DEFAULT_CLONE
    sync_episode(ep, source_root, clone)
    lab_ref = lab_number(ep)
    args = ["gh", "workflow", "run", WORKFLOW, "--repo", _origin_repo(),
            "-f", f"lab={lab_ref}"]
    if section:
        args += ["-f", f"section={section}"]
    p = subprocess.run(args, capture_output=True, text=True)
    if p.returncode != 0:
        extra = f" -f section={section}" if section else ""
        sys.exit(f"gh workflow run failed: {p.stderr.strip()}\n"
                 "Run it manually:\n"
                 f"  gh workflow run {WORKFLOW} -f lab={lab_ref}{extra}\n"
                 f"  gh run watch   # then download the artifact")
    # newest queued run for this workflow
    r = subprocess.run(["gh", "run", "list", "--workflow", WORKFLOW,
                        "--limit", "1", "--json", "databaseId,url"],
                       capture_output=True, text=True)
    try:
        import json as _json
        run = _json.loads(r.stdout)[0]
        print(f"[cloud] dispatched: {run['url']}")
        return run["databaseId"]
    except (ValueError, KeyError):
        print("[cloud] dispatched (run list unavailable)")
        return None


def _origin_repo():
    r = subprocess.run(["git", "-C", DEFAULT_CLONE, "remote", "get-url", "origin"],
                       capture_output=True, text=True)
    url = r.stdout.strip()
    if ".git" in url:
        url = url.rsplit(".git", 1)[0]
    return url.replace("https://github.com/", "")


def normalize_part_names(final_dir, ep):
    """Deliverable naming convention (user, 2026-09-27): final/ part files
    carry the LOCAL lab folder name (e.g. 27-multiple-containers-part1-main.mp4).
    CI artifacts arrive named after the public repo path — rename on download."""
    pub = os.path.basename(public_rel_path(ep).replace("\\", "/"))
    loc = ep["lab"]
    if not pub or pub == loc:
        return []
    renamed = []
    for name in sorted(os.listdir(final_dir)):
        if name.startswith(pub + "-"):
            src = os.path.join(final_dir, name)
            dst = os.path.join(final_dir, loc + name[len(pub):])
            os.replace(src, dst)
            renamed.append(f"{name} -> {os.path.basename(dst)}")
    return renamed


def wait_and_download(run_id, ep):
    # -R is required: the caller's cwd may not be a git repository, and gh
    # refuses to resolve a base repo outside a checkout.
    subprocess.run(["gh", "run", "watch", str(run_id), "--exit-status", "-R", DEFAULT_REPO])
    import shutil as _sh
    import tempfile
    ep_dir = episode_dir(ep)
    final_dir = os.path.join(ep_dir, "final")
    os.makedirs(final_dir, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix="ci-artifact-")
    subprocess.run(["gh", "run", "download", str(run_id), "-R", DEFAULT_REPO, "-D", tmp], check=True)
    # the artifact nests the episode dir as <artifact>/<section>/<lab-name>/;
    # find that dir and copy every tracked state subdir back (final plus, for
    # first-time renders that never ran locally, validation/ timing/ qc-frames).
    ep_roots = [root for root, _dirs, _files in os.walk(tmp)
                if os.path.basename(root) == ep["lab"]]
    if not ep_roots:
        sys.exit(f"no {ep['lab']} directory found in artifact")
    copied = 0
    for src_ep in ep_roots:
        for sub, dest in (("final", final_dir),
                          ("validation", os.path.join(ep_dir, "validation")),
                          ("timing", os.path.join(ep_dir, "timing")),
                          (os.path.join("preview", "qc-frames"),
                           os.path.join(ep_dir, "preview", "qc-frames"))):
            src_sub = os.path.join(src_ep, sub)
            os.makedirs(dest, exist_ok=True)
            for root, _dirs, files in os.walk(src_sub):
                rel = os.path.relpath(root, src_sub)
                for name in files:
                    dst_dir = dest if rel == "." else os.path.join(dest, rel)
                    os.makedirs(dst_dir, exist_ok=True)
                    _sh.copy2(os.path.join(root, name), os.path.join(dst_dir, name))
                    copied += 1
    for line in normalize_part_names(final_dir, ep):
        print(f"[cloud] renamed: {line}")
    _sh.rmtree(tmp, ignore_errors=True)
    print(f"[cloud] {copied} file(s) -> {ep_dir}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lab", required=True)
    ap.add_argument("--section", help="section name, e.g. section-02-meta-arguments "
                                      "(disambiguates numeric refs; passed to CI)")
    ap.add_argument("--source-root", default=os.environ.get("COURSE_SOURCE_ROOT") or os.getcwd())
    ap.add_argument("--wait", action="store_true", help="watch the run, then download")
    args = ap.parse_args()

    if not shutil_gh():
        repo = "RIT-MESH/Terraform-Azure-Labs-and-Case_Studies"
        print(f"gh CLI unavailable — run these exact commands:\n"
              f"  1. python video-course/tools/sync_ci_inputs.py --lab {args.lab}\n"
              f"     (then git add/commit/push the changed files)\n"
              f"  2. gh workflow run {WORKFLOW} -R {repo} -f lab={args.lab}\n"
              f"  3. gh run watch / gh run download  # artifact -> final/")
        return
    labs = load_course_manifest(args.source_root)
    ep = resolve_lab(args.lab, labs, section=args.section)[0]
    run_id = trigger(ep, args.source_root, section=args.section)
    if args.wait and run_id:
        wait_and_download(run_id, ep)


def shutil_gh():
    from shutil import which
    return which("gh")


if __name__ == "__main__":
    main()