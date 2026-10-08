#!/usr/bin/env python3
"""Deterministic terraform validation in a sandbox dir. Never deploys.

Runs, in order: fmt -check -recursive; init -backend=false; validate.
Terraform binary resolution: LABS_TERRAFORM env -> shutil.which("terraform")
-> the project-local toolchain (Windows only, under the source root).

Usage: validate_terraform.py <sandbox-dir> [--out result.json]
Exit code 0 only when everything ran and passed. Code 2 = skipped/unavailable.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys

LOCAL_TF = os.path.join(os.environ.get("COURSE_SOURCE_ROOT") or os.getcwd(),
                        ".env", "bin", "terraform.exe")


def find_terraform():
    """LABS_TERRAFORM override -> PATH -> project-local toolchain (Windows)."""
    env_tf = os.environ.get("LABS_TERRAFORM")
    if env_tf and os.path.isfile(env_tf):
        return env_tf
    on_path = shutil.which("terraform")
    if on_path:
        return on_path
    if os.path.isfile(LOCAL_TF):
        return LOCAL_TF
    return None


def run(cmd, cwd):
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=600)
    return {"cmd": " ".join(cmd), "ok": p.returncode == 0,
            "stdout": p.stdout[-4000:], "stderr": p.stderr[-4000:]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dir")
    ap.add_argument("--out", help="write JSON result here")
    args = ap.parse_args()

    TF = find_terraform()
    if TF is None:
        print("terraform not found (LABS_TERRAFORM, PATH, project .env toolchain)",
              file=sys.stderr)
        sys.exit(2)
    # Provider-cache config is a project-local convenience: use it only when it
    # actually exists (on CI there is no project-local terraform.rc).
    if shutil.which("terraform") is None:
        rc = os.path.join(os.environ.get("COURSE_SOURCE_ROOT") or os.getcwd(),
                          ".env", "terraform.rc")
        if os.path.isfile(rc):
            os.environ.setdefault("TF_CLI_CONFIG_FILE", rc)

    results, ok_all = [], True
    for cmd in ([TF, "fmt", "-check", "-recursive"],
                [TF, "init", "-backend=false", "-input=false"],
                [TF, "validate"]):
        r = run(cmd, args.dir)
        results.append(r)
        if not r["ok"]:
            ok_all = False
            break  # no point validating when init failed, etc.

    result = {"dir": os.path.abspath(args.dir), "passed": ok_all, "steps": results}
    out = json.dumps(result, indent=2)
    if args.out:
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        open(args.out, "w", encoding="utf-8").write(out)
    else:
        print(out)
    sys.exit(0 if ok_all else 1)


if __name__ == "__main__":
    main()
