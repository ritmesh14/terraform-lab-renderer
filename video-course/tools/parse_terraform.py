#!/usr/bin/env python3
"""Parse terraform files in a directory into a rich terraform-inventory.json.

python-hcl2 is REQUIRED for normal production (instruction §5); the regex pass
is an emergency fallback only — it emits parser:"regex-fallback" plus
"confidence":"reduced" and the pipeline treats reduced confidence as a
validation warning (never silently lower quality).

Extracts: files, resources, data_sources, variables, locals, outputs, modules
(with source + inputs), terraform constraints, required_providers, provider
blocks, backends, references (var/local/module/data/resource refs) and
dependency_edges (what each block depends on) — the dependency graph the
narration and Gate 2 treat as authoritative.

Usage: parse_terraform.py <lab-dir> [--out inventory.json]
"""
import argparse
import glob
import json
import os
import re

RE_REF = re.compile(
    r"\b(var|local|module|data)\.([A-Za-z_][A-Za-z0-9_-]*)"
    r"(?:\.([A-Za-z_][A-Za-z0-9_-]*))?")
# provider-type references ("azurerm_resource_group.rg.id") — verified against
# declared addresses afterwards, so attribute chains never become fake deps
RE_TYPED_REF = re.compile(r"(?<![\w.])"
                          r"([a-z][a-z0-9]*(?:_[a-z0-9]+)+)"
                          r"\.([A-Za-z_][A-Za-z0-9_-]*)")
RE_BACKEND = re.compile(r'(?ms)^\s*backend\s+"([^"]+)"\s*\{(.*?)^\s*\}')
RE_REQUIRED_PROVIDER = re.compile(
    r'(?ms)^\s*([a-z0-9_-]+)\s*=\s*\{(.*?)^\s*\}')
RE_PROVIDER_VERSION = re.compile(r'source\s*=\s*"([^"]+)"')
RE_PROVIDER_BLOCK = re.compile(r'(?ms)^\s*provider\s+"([^"]+)"\s*\{(.*?)^\s*\}')
RE_MODULE = re.compile(r'(?ms)^\s*module\s+"([^"]+)"\s*\{(.*?)\}')
RE_MODULE_SOURCE = re.compile(r'source\s*=\s*"([^"]+)"')


def _first_str(d, *keys):
    for k in keys:
        v = d.get(k)
        if isinstance(v, str):
            return v
        if isinstance(v, list) and v and isinstance(v[0], str):
            return v[0]
    return None


def parse_with_hcl2(tf_files):
    """Full hcl2 inventory. Returns the result dict."""
    import hcl2  # noqa
    files, resources, data, variables, locals_, outputs = [], [], [], [], [], []
    modules, providers, required_providers, backends, constraints = [], [], [], [], []
    raw, dependency_edges = [], []

    def resolve_edges():
        """raw refs -> dependency edges, verified against declared addresses.
        The parsed dependency graph is the authoritative order for narration
        (Terraform is NOT a top-to-bottom script)."""
        resource_addr = {r["address"] for r in resources}
        resource_names = {r["address"].split(".", 1)[1] for r in resources}
        data_addr = {d.get("address", "") for d in data}
        data_names = {d["name"] for d in data}
        var_names = {v["name"] for v in variables}
        local_names = {l["name"] for l in locals_}
        module_names = {m["name"] for m in modules}
        for e in raw:
            owner, ot, ref, kind, key = (e["owner"], e["owner_type"],
                                         e["ref"], e["kind"], e["key"])
            if kind == "var" and key in var_names:
                dep = f"variable:{key}"
            elif kind == "local" and key in local_names:
                dep = f"local:{key}"
            elif kind == "module" and key in module_names:
                dep = f"module:{key}"
            elif kind == "data" and (key in data_names or ref.split(".")[1] in data_names):
                dep = f"data:{ref.split('.')[1]}"
            elif kind == "typed" and ref in resource_addr:
                dep = f"resource:{ref}"
            elif kind == "typed" and key in data_names:
                dep = f"data:{ref}"
            else:
                continue  # unresolvable attribute chain — not a dependency
            if dep == f"{ot}:{owner}" or (ot == "resource" and dep == f"resource:{owner}"):
                continue  # self-reference
            dependency_edges.append({"from": f"{ot}:{owner}", "to": dep,
                                     "ref": ref, "file": e["file"]})

    def finish():
        resolve_edges()
        return {"files": files, "resources": resources, "data_sources": data,
                "variables": variables, "locals": locals_, "outputs": outputs,
                "modules": modules, "providers": providers,
                "required_providers": required_providers,
                "terraform_constraints": constraints, "backends": backends,
                "dependency_edges": dependency_edges}

    def refs_of(text, owner, owner_type, f):
        """Raw reference scan for one block body (post-filtered against the
        declared addresses once every file has been parsed)."""
        seen = set()
        for kind, name, attr in RE_REF.findall(text):
            ref = {"var": f"var.{name}", "local": f"local.{name}",
                   "module": f"module.{name}",
                   "data": f"data.{name}" + (f".{attr}" if attr else "")}[kind]
            if ref in seen:
                continue
            seen.add(ref)
            raw.append({"owner": owner, "owner_type": owner_type,
                        "ref": ref, "kind": kind, "key": name, "file": f})
        for rtype, name in RE_TYPED_REF.findall(text):
            # skip the keywords the kind-regex already owns
            ref = f"{rtype}.{name}"
            if ref in seen or rtype in ("var", "local", "module", "data"):
                continue
            seen.add(ref)
            raw.append({"owner": owner, "owner_type": owner_type,
                        "ref": ref, "kind": "typed", "key": name, "file": f})
        return seen

    for path in tf_files:
        base = os.path.basename(path)
        text = open(path, encoding="utf-8").read()
        files.append(os.path.basename(path))
        with open(path, encoding="utf-8") as f:
            parsed = hcl2.load(f)

        for block in parsed.get("terraform", []):
            rv = block.get("required_version")
            if rv:
                constraints.append({"required_version": rv, "file": base})
            for rp in block.get("required_providers", []):
                for pname, body in rp.items():
                    if isinstance(body, list):
                        body = body[0] if body and isinstance(body[0], dict) else None
                    if isinstance(body, dict):
                        src = _first_str(body, "source")
                        ver = _first_str(body, "version")
                    else:
                        src, ver = None, None
                    required_providers.append(
                        {"name": pname, "source": src, "version": ver, "file": base})
            for bk in block.get("backend", []):
                for bname, _body in bk.items():
                    backends.append({"type": bname, "file": base})

        for block in parsed.get("provider", []):
            for pname, body in block.items():
                providers.append({"name": pname, "file": base})

        for block in parsed.get("locals", []):
            for name, value in block.items():
                if name.startswith("__"):
                    continue
                locals_.append({"name": name, "file": base})
                refs_of(json.dumps(value), name, "local", base)

        for block in parsed.get("resource", []):
            for rtype, named in block.items():
                for name, body in named.items():
                    addr = f"{rtype}.{name}"
                    resources.append({"type": rtype, "name": name,
                                      "address": addr, "file": base})
                    refs_of(json.dumps(body), addr, "resource", base)
        for block in parsed.get("data", []):
            for dtype, named in block.items():
                for name, body in named.items():
                    addr = f"data.{dtype}.{name}"
                    data.append({"type": dtype, "name": name,
                                 "address": addr, "file": base})
                    refs_of(json.dumps(body), addr, "data", base)
        for block in parsed.get("variable", []):
            for name, body in block.items():
                body = body[0] if isinstance(body, list) else body
                variables.append({
                    "name": name, "file": base,
                    "type": _first_str(body or {}, "type"),
                    "default": (body or {}).get("default"),
                    "sensitive": bool((body or {}).get("sensitive")),
                })
        for block in parsed.get("output", []):
            for name, body in block.items():
                body = body[0] if isinstance(body, list) else body
                outputs.append({
                    "name": name, "file": base,
                    "value": _first_str(body or {}, "value"),
                    "sensitive": bool((body or {}).get("sensitive")),
                })
        for block in parsed.get("module", []):
            for name, body in block.items():
                src = (body or {}).get("source")
                src = src[0] if isinstance(src, list) else src
                inputs = {k: v for k, v in (body or {}).items()
                          if k not in ("source", "version", "count",
                                       "for_each", "providers", "__start_line__")}
                modules.append({"name": name, "source": src, "inputs": inputs,
                                "file": base})
                refs_of(json.dumps(body), name, "module", base)

    return finish()


# ------------------------------------------------------- regex fallback ONLY

RE_RESOURCE = re.compile(r'(?m)^\s*resource\s+"([^"]+)"\s+"([^"]+)"')
RE_DATA = re.compile(r'(?m)^\s*data\s+"([^"]+)"\s+"([^"]+)"')
RE_VARIABLE = re.compile(r'(?m)^\s*variable\s+"([^"]+)"')
RE_LOCAL = re.compile(r'(?m)^\s*([a-zA-Z_][\w-]*)\s*=', )
RE_OUTPUT = re.compile(r'(?m)^\s*output\s+"([^"]+)"')


def parse_with_regex(tf_files):
    """EMERGENCY FALLBACK ONLY — deterministic, reduced confidence, warns."""
    resources, data, variables, locals_, outputs, modules = [], [], [], [], [], []
    refs = []
    for path in tf_files:
        text = open(path, encoding="utf-8").read()
        base = os.path.basename(path)
        for rtype, name in RE_RESOURCE.findall(text):
            resources.append({"type": rtype, "name": name,
                              "address": f"{rtype}.{name}", "file": base})
        for dtype, name in RE_DATA.findall(text):
            data.append({"type": dtype, "name": name, "file": base})
        for name in RE_VARIABLE.findall(text):
            variables.append({"name": name, "file": base})
        for name in RE_OUTPUT.findall(text):
            outputs.append({"name": name, "file": base})
        m = re.search(r'(?ms)^\s*locals\s*\{(.*?)^\s*\}', text)
        if m:
            for ln in m.group(1).splitlines():
                lm = RE_LOCAL.match(ln.strip())
                if lm and lm.group(1) not in ("resource", "data", "output",
                                              "module", "variable"):
                    locals_.append({"name": lm.group(1), "file": base})
        for name, body in RE_MODULE.findall(text):
            sm = RE_MODULE_SOURCE.search(body)
            modules.append({"name": name,
                            "source": sm.group(1) if sm else None,
                            "inputs": {}, "file": base})
        for kind, name, _attr in RE_REF.findall(text):
            refs.append(f"{kind}.{name}")
    return {"files": [os.path.basename(f) for f in tf_files],
            "resources": resources, "data_sources": data,
            "variables": variables, "locals": locals_, "outputs": outputs,
            "modules": modules, "providers": [], "required_providers": [],
            "terraform_constraints": [], "backends": [],
            "dependency_edges": []}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("lab_dir")
    ap.add_argument("--out", help="write JSON here (default: stdout)")
    args = ap.parse_args()

    tf_files = sorted(glob.glob(os.path.join(args.lab_dir, "*.tf")))
    warns = []
    try:
        inventory = parse_with_hcl2(tf_files)
        parser, confidence = "python-hcl2", "full"
    except ImportError:
        inventory = parse_with_regex(tf_files)
        parser, confidence = "regex-fallback", "reduced"
        warns.append("python-hcl2 NOT installed — regex fallback used; "
                     "inventory completeness and validation confidence are "
                     "REDUCED (pip install python-hcl2)")

    result = {
        "lab_dir": os.path.abspath(args.lab_dir),
        "parser": parser,
        "confidence": confidence,
        "files": inventory["files"],
        "resources": inventory["resources"],
        "data_sources": inventory["data_sources"],
        "variables": inventory["variables"],
        "locals": inventory["locals"],
        "outputs": inventory["outputs"],
        "modules": inventory["modules"],
        "providers": inventory["providers"],
        "required_providers": inventory["required_providers"],
        "terraform_constraints": inventory["terraform_constraints"],
        "backends": inventory["backends"],
        "references": sorted({r for r in
                              [e["ref"] for e in inventory["dependency_edges"]]
                              + inventory.get("references", [])}),
        "dependency_edges": inventory["dependency_edges"],
        "warnings": warns,
    }
    out = json.dumps(result, indent=2)
    if args.out:
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(out)
        print(f"-> {args.out} (parser: {parser}, {len(result['resources'])} resources, "
              f"{len(result['modules'])} modules, "
              f"{len(result['dependency_edges'])} dependency edges, "
              f"confidence: {confidence})")
        for w in warns:
            print(f"WARNING: {w}")
    else:
        print(out)


if __name__ == "__main__":
    main()