#!/usr/bin/env python3
"""
Bulk pack scaffolder.

Usage:
  python3 Vault/tools/new_packs.py --input packs.csv [--push]
  python3 Vault/tools/new_packs.py --input packs.json [--push]
  python3 Vault/tools/new_packs.py --dry-run --input packs.csv

Input formats (detects by extension):
- CSV with headers
- JSON array of objects

Common fields (case-insensitive headers/keys):
  bucket      : "active" | "sandbox"  (default: active)
  slug        : e.g., "my_prompt_slug"  (REQUIRED)
  title       : e.g., "Intake Triage"   (REQUIRED)
  owner       : e.g., "Neville"
  persona     : e.g., "Clinician"
  use_case    : e.g., "intake" (hyphen or underscore ok)
  version     : e.g., "1.0.0"           (default: 1.0.0)
  status      : e.g., "active"          (default: active)
  tags        : comma-separated e.g., "clinical,intake,v1"

Notes:
- Values may be missing per-row; defaults apply.
- Tags can also be a JSON array when input is JSON.

This script delegates the actual scaffolding to scripts/new-pack
so it stays consistent with your toolchain.
"""
import argparse, csv, json, subprocess, sys, shlex
from pathlib import Path

REPO = Path.cwd()
NEW_PACK = REPO / "scripts" / "new-pack"

def norm(s):
    return (s or "").strip()

def as_tags(v):
    if isinstance(v, list):
        return ",".join(str(x).strip() for x in v if str(x).strip())
    v = norm(v)
    if not v: return ""
    return ",".join(t.strip() for t in v.split(",") if t.strip())

def row_fields(row):
    # allow flexible keys
    key = {k.lower().replace("-", "_"): v for k,v in row.items()}
    return {
        "bucket":   norm(key.get("bucket") or "active"),
        "slug":     norm(key.get("slug")),
        "title":    norm(key.get("title")),
        "owner":    norm(key.get("owner") or ""),
        "persona":  norm(key.get("persona") or ""),
        "use_case": norm(key.get("use_case") or key.get("use-case") or ""),
        "version":  norm(key.get("version") or "1.0.0"),
        "status":   norm(key.get("status") or "active"),
        "tags":     as_tags(key.get("tags") or ""),
    }

def run(cmd, dry_run=False, env=None):
    print("[RUN ]", " ".join(shlex.quote(c) for c in cmd))
    if dry_run: return 0
    return subprocess.call(cmd, env=env)

def has_alias(alias):
    try:
        out = subprocess.check_output(["git","config","--global","--get",f"alias.{alias}"])
        return bool(out.strip())
    except subprocess.CalledProcessError:
        return False

def load_rows(path: Path):
    if path.suffix.lower() == ".csv":
        with path.open(newline="", encoding="utf-8") as f:
            rdr = csv.DictReader(f)
            return [dict(r) for r in rdr]
    elif path.suffix.lower() == ".json":
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, list):
            raise SystemExit("JSON must be an array of objects")
        return data
    else:
        raise SystemExit("Unsupported input type (use .csv or .json)")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True, help="CSV or JSON file")
    ap.add_argument("--no-push", action="store_true", help="Create packs without pushing")
    ap.add_argument("--push", action="store_true", help="Force push at the end (default behavior if gp alias exists)")
    ap.add_argument("--dry-run", action="store_true", help="Print actions only")
    args = ap.parse_args()

    inp = Path(args.input).resolve()
    if not inp.exists():
        raise SystemExit(f"Input not found: {inp}")

    if not NEW_PACK.exists():
        raise SystemExit("scripts/new-pack not found. Please ensure it exists and is executable.")

    rows = load_rows(inp)
    if not rows:
        print("[INFO] No rows found; nothing to do.")
        return 0

    created = []
    for i, r in enumerate(rows, 1):
        f = row_fields(r)
        if not f["slug"] or not f["title"]:
            print(f"[SKIP] Row {i} missing slug/title")
            continue
        cmd = [
            str(NEW_PACK),
            f["bucket"],
            f["slug"],
            f["title"],
        ]
        if f["owner"]:
            cmd += ["--owner", f["owner"]]
        if f["persona"]:
            cmd += ["--persona", f["persona"]]
        if f["use_case"]:
            cmd += ["--use-case", f["use_case"]]
        if f["version"]:
            cmd += ["--version", f["version"]]
        if f["status"]:
            cmd += ["--status", f["status"]]
        if f["tags"]:
            cmd += ["--tags", f["tags"]]
        if args.no_push:
            cmd += ["--no-push"]
        run(cmd, dry_run=args.dry_run)
        created.append(f["slug"])

    # If we didn't push per-row and a gp alias exists (or --push was given),
    # do a single consolidated push at the end for neat history.
    if (not args.no_push) and (args.push or has_alias("gp")):
        msg = f"new: add {len(created)} pack(s) from {inp.name}"
        if has_alias("gp"):
            run(["git","gp", msg], dry_run=args.dry_run)
        else:
            # vanilla fallback
            run(["python3","Vault/tools/update_checksums.py"], dry_run=args.dry_run)
            run(["python3","Vault/tools/build_catalog.py"], dry_run=args.dry_run)
            run(["python3","Vault/tools/validate_all.py"], dry_run=args.dry_run)
            run(["git","add","-A"], dry_run=args.dry_run)
            run(["git","commit","-m", msg, "--allow-empty"], dry_run=args.dry_run)
            run(["git","push"], dry_run=args.dry_run)

    print("[DONE]", ", ".join(created))
    return 0

if __name__ == "__main__":
    sys.exit(main())
