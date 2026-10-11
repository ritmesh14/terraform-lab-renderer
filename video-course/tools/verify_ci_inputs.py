#!/usr/bin/env python3
"""Pre-dispatch verification: the render clone must match the authoring source.

Closes the one way video CI can silently render stale input: a render clone
that is dirty, has unpushed commits, or drifted from the authoring source
while a workflow is dispatched anyway. run_video.py / cloud_render.py call
this before every dispatch; it can also be used standalone.

Checks (all must pass):
  1. clone exists and is a git checkout on a real branch (not detached HEAD)
  2. clone's origin points at the expected render repository
  3. local branch == origin branch after a fetch (nothing unpushed, nothing
     pushed-but-never-fetched)
  4. worktree has no uncommitted changes to the sync surface
  5. every file the sync copies for this episode is byte-identical to the
     authoring source after CRLF normalisation (Windows checkouts silently
     convert line endings; the blobs are what CI actually renders), and the
     per-lab targets hold no stale files the source no longer has

Exit 0 = CI-ready (safe to dispatch). Exit 3 = mismatches, printed with the
exact fix for each. Never renders, never commits, never pushes.

Usage:
  verify_ci_inputs.py --lab 26 [--section section-02-meta-arguments]
                      [--source-root <...>] [--clone <path>] [--repo <owner/name>]
"""
import argparse
import hashlib
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from course_index import load_course_manifest, public_rel_path, resolve_lab  # noqa: E402
from sync_ci_inputs import (  # noqa: E402
    LAB_FILE_EXTS, LAB_FILE_NAMES, MODULE_SOURCE_EXTS, REMOTION_DIRS,
    REMOTION_FILES, VC_FILES, VC_CONFIG_DIR, VC_TOOLS_DIR, VC,
    WRITING_FILES, DEMO_FILES, DEMO_DIRS, DEMO_EXTS,
    find_referenced_modules,
)

EXIT_OK = 0
EXIT_MISMATCH = 3

# files intentionally allowed to drift (repo keeps its version, local keeps
# the user's edits): repo-path relative to <clone>, reason. Documented
# exception - the whole-surface check skips these.
ALLOWED_DRIFT = {
    "labs/section-01-foundations/10-types-map/main.tf":
        "user's local slimmed copy is intentional (2026-10-11); repo keeps "
        "the commented teaching version; episode 10 renders from the repo "
        "version - re-syncing would need an explicit re-render decision",
}


def _norm(path):
    """File bytes with CRLF folded to LF (what the git blob stores on repo)."""
    if isinstance(path, bytes):
        return path.replace(b"\r\n", b"\n")
    with open(path, "rb") as f:
        return f.read().replace(b"\r\n", b"\n")


def _sha(path_or_bytes):
    if isinstance(path_or_bytes, bytes):
        data = path_or_bytes
    else:
        data = _norm(path_or_bytes)
    return hashlib.sha256(data).hexdigest()


def episode_surface(ep, source_root):
    """(src_path, clone_relpath) for every file this episode's sync stages
    into the clone. Mirrors sync_ci_inputs.sync_episode exactly."""
    lab = ep["abs_path"]
    items = []
    pub_lab = os.path.basename(public_rel_path(ep).replace("\\", "/"))
    for fn in sorted(os.listdir(lab)):
        src = os.path.join(lab, fn)
        if os.path.isfile(src) and (fn.endswith(LAB_FILE_EXTS) or fn in LAB_FILE_NAMES):
            items.append((src, os.path.join("labs", ep["section"], pub_lab, fn)))

    from sync_ci_inputs import VC as _VC
    pub_lab = os.path.basename(public_rel_path(ep).replace("\\", "/"))
    for mod in find_referenced_modules(lab, source_root):
        base = ["", "modules", mod]
        mod_src = os.path.join(source_root, "modules", mod)
        if not os.path.isdir(mod_src):
            items.append((None, os.path.join(*base[1:]), True))
            continue
        for root, _dirs, files in os.walk(mod_src):
            for fn in files:
                if fn.endswith(MODULE_SOURCE_EXTS):
                    src = os.path.join(root, fn)
                    rel = os.path.join("modules", mod, os.path.relpath(src, mod_src))
                    items.append((src, rel))

    for fn in VC_FILES:
        src = os.path.join(_VC, fn)
        if os.path.isfile(src):
            items.append((src, os.path.join("video-course", fn)))
    for rel_base, exts in ((VC_CONFIG_DIR, None), (VC_TOOLS_DIR, None)):
        base = os.path.join(_VC, rel_base)
        for root, dirs, files in os.walk(base):
            dirs[:] = [d for d in dirs if d not in ("__pycache__", "node_modules")]
            for fn in files:
                src = os.path.join(root, fn)
                items.append((src, os.path.join("video-course",
                                                rel_base,
                                                os.path.relpath(src, base))))
    for fn in REMOTION_FILES:
        src = os.path.join(_VC, "remotion", fn)
        if os.path.isfile(src):
            items.append((src, os.path.join("video-course", "remotion", fn)))
    for d in REMOTION_DIRS:
        base = os.path.join(_VC, "remotion", d)
        if not os.path.isdir(base):
            continue
        for root, dirs, files in os.walk(base):
            dirs[:] = [dd for dd in dirs
                       if dd not in ("node_modules", ".terraform", ".remotion")]
            for fn in files:
                src = os.path.join(root, fn)
                items.append((src, os.path.join("video-course", "remotion", d,
                                                os.path.relpath(src, base))))
    fonts_src = os.path.join(_VC, "remotion", "public", "fonts")
    if os.path.isdir(fonts_src):
        for root, _dirs, files in os.walk(fonts_src):
            for fn in files:
                src = os.path.join(root, fn)
                items.append((src, os.path.join(
                    "video-course", "remotion", "public", "fonts",
                    os.path.relpath(src, fonts_src))))

    # episode-spec targets key on the PUBLIC lab name in the clone
    ep_dir = os.path.join(VC, "output", ep["section"], ep["lab"])
    for fn in WRITING_FILES:
        src = os.path.join(ep_dir, "writing", fn)
        if os.path.isfile(src):
            items.append((src, os.path.join("video-course", "output",
                                            ep["section"], pub_lab,
                                            "writing", fn)))
    for sub in ("diagrams", "terminal"):
        src_sub = os.path.join(ep_dir, "assets", sub)
        if os.path.isdir(src_sub):
            for fn in sorted(os.listdir(src_sub)):
                if fn.endswith(".spec.json") or fn.endswith(".txt"):
                    items.append((os.path.join(src_sub, fn),
                                  os.path.join("video-course", "output",
                                               ep["section"], pub_lab,
                                               "assets", sub, fn)))
    demo_src = os.path.join(ep_dir, "demo")
    if os.path.isdir(demo_src):
        for fn in DEMO_FILES:
            src = os.path.join(demo_src, fn)
            if os.path.isfile(src):
                items.append((src, os.path.join("video-course", "output",
                                                ep["section"], pub_lab,
                                                "demo", fn)))
        for sub in DEMO_DIRS:
            sub_dir = os.path.join(demo_src, sub)
            if os.path.isdir(sub_dir):
                for root, _dirs, files in os.walk(sub_dir):
                    for fn in files:
                        if fn.endswith(DEMO_EXTS):
                            src = os.path.join(root, fn)
                            items.append((src, os.path.join(
                                "video-course", "output", ep["section"],
                                pub_lab, "demo", sub,
                                os.path.relpath(src, sub_dir))))
    return items


def _git(clone, *args):
    return subprocess.run(["git", "-C", clone, *args],
                          capture_output=True, text=True)


def _clone_path(clone, rel):
    return os.path.join(clone, rel.replace("/", os.sep))


def verify(ep, source_root, clone, expected_repo=None):
    """Returns a list of problems (empty = CI-ready)."""
    problems = []

    if not os.path.isdir(os.path.join(clone, ".git")):
        return [f"not a git clone: {clone}"]
    clone = os.path.abspath(clone)

    # remote repo identity
    url = _git(clone, "remote", "get-url", "origin").stdout.strip()
    rem = url.replace("https://github.com/", "").rsplit(".git", 1)[0]
    if rem.startswith("git@github.com:"):
        rem = rem.split("git@github.com:", 1)[1].rsplit(".git", 1)[0]
    if expected_repo:
        exp = expected_repo.rsplit(".git", 1)[0]
        if rem != exp:
            problems.append(
                f"clone origin = {rem}, expected {exp} "
                f"({clone}); point origin at the render repo first")

    # branch: must not be detached
    branch = _git(clone, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
    if not branch or branch == "HEAD":
        return problems + ["clone is in detached-HEAD state; "
                           "checkout a branch before dispatching"]

    # fetch then compare local HEAD vs origin branch
    if _git(clone, "fetch", "origin", "--quiet").returncode != 0:
        problems.append("git fetch failed (network or credentials)")
    local = _git(clone, "rev-parse", "HEAD").stdout.strip()
    remote = _git(clone, "rev-parse", f"origin/{branch}").stdout.strip()
    if local != remote:
        if _git(clone, "rev-list", f"origin/{branch}..{local}").stdout.strip():
            problems.append(
                f"clone has UNPUSHED commits on {branch} - "
                f"CI renders origin/{branch}, so these would not reach the "
                f"run: commit+push (cloud_render.py push does this "
                f"automatically)")
        elif _git(clone, "rev-list", f"{local}..origin/{branch}").stdout.strip():
            problems.append(
                f"origin/{branch} is AHEAD of the clone - run: "
                f"git -C <clone> pull --ff-only")
        else:
            problems.append(f"HEAD vs origin/{branch} diverged")

    # worktree cleanliness (sync surface sanity)
    st = _git(clone, "status", "--porcelain")
    if st.returncode != 0:
        problems.append("git status failed in clone")
    else:
        lines = [l for l in st.stdout.splitlines() if l.strip()]
        if lines:
            problems.append(
                f"clone worktree is dirty ({len(lines)} entr"
                f"{'y' if len(lines) == 1 else 'ies'}) - commit or discard "
                f"before dispatching: e.g. {lines[0].strip()[:90]}")

    # content: every synced file byte-identical (CRLF-normalised) to source
    for src, rel in episode_surface(ep, source_root):
        if rel in ALLOWED_DRIFT:
            continue
        dst = _clone_path(clone, rel)
        if src is None:
            problems.append(f"missing source module: {rel}")
            continue
        if not os.path.isfile(dst):
            continue  # never-synced-yet file (e.g. fresh clone) - sync adds it
        try:
            if _sha(src) != _sha(dst):
                problems.append(f"DRIFT (clone != authoring source): {rel}")
        except OSError as e:
            problems.append(f"unreadable ({e}): {rel}")

    # stale files: present in a per-lab clone target but gone from source
    pub_lab = os.path.basename(public_rel_path(ep).replace("\\", "/"))
    lab = ep["abs_path"]
    dst_lab = os.path.join(clone, "labs", ep["section"], pub_lab)
    if os.path.isdir(dst_lab):
        for fn in os.listdir(dst_lab):
            src_names = {n for n in os.listdir(lab)}
            if fn not in src_names and (fn.endswith(LAB_FILE_EXTS)
                                        or fn in LAB_FILE_NAMES):
                problems.append(
                    f"STALE in clone (no longer in source): labs/{ep['section']}/{pub_lab}/{fn}")
    ep_dir = os.path.join(VC, "output", ep["section"], ep["lab"])
    dst_out = os.path.join(clone, "video-course", "output",
                           ep["section"], pub_lab)
    if os.path.isdir(dst_out):
        for sub, src_sub in (("writing", os.path.join(ep_dir, "writing")),
                             ("assets/diagrams", os.path.join(ep_dir, "assets", "diagrams")),
                             ("assets/terminal", os.path.join(ep_dir, "assets", "terminal"))):
            d = os.path.join(dst_out, sub.replace("/", os.sep))
            if os.path.isdir(d) and os.path.isdir(src_sub):
                src_names = set(os.listdir(src_sub))
                for fn in os.listdir(d):
                    if fn not in src_names:
                        problems.append(
                            f"STALE in clone (no longer in source): video-course/output/{ep['section']}/{pub_lab}/{sub}/{fn}")

    for p in problems:
        print(f"[verify] FAIL: {p}")
    for rel, why in ALLOWED_DRIFT.items():
        print(f"[verify] note: allowed drift skipped: {rel} ({why})")
    if not problems:
        print(f"[verify] CI-ready: clone matches authoring source, branch "
              f"{branch} in sync with origin, worktree clean")
    return problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lab", required=True)
    ap.add_argument("--section")
    ap.add_argument("--source-root", default=os.environ.get("COURSE_SOURCE_ROOT") or os.getcwd())
    ap.add_argument("--clone")
    ap.add_argument("--repo")
    args = ap.parse_args()
    if args.repo is None:
        import cloud_render
        args.repo = cloud_render.DEFAULT_REPO
        args.clone = args.clone or cloud_render.DEFAULT_CLONE
    labs = load_course_manifest(args.source_root)
    ep = resolve_lab(args.lab, labs, section=args.section)[0]
    if verify(ep, args.source_root, args.clone, expected_repo=args.repo):
        sys.exit(EXIT_MISMATCH)
    sys.exit(EXIT_OK)


if __name__ == "__main__":
    main()