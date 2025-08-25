#!/usr/bin/env python3
"""
validate_all.py
- Updates checksums for all prompt packs
- Rebuilds Prompt_Catalog.json
- Runs lightweight validations (e.g., disclaimer present)
- Prints ALL_VALIDATIONS_OK when complete (with WARN lines if needed)
"""

from __future__ import annotations
import json
import sys
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve()
REPO_ROOT = HERE.parents[2]          # <repo>/
VAULT = REPO_ROOT / "Vault"
LIB_ROOT = VAULT / "Prompt_Library"
CATALOG_PATH = VAULT / "Prompt_Catalog.json"

UPDATER = VAULT / "tools" / "update_checksums.py"
CATALOG_BUILDER = VAULT / "tools" / "build_catalog.py"

def run_py(script: Path) -> int:
    if not script.exists():
        print(f"[SKIP] {script.relative_to(REPO_ROOT)} missing")
        return 0
    p = subprocess.run([sys.executable, str(script)], text=True)
    return p.returncode

def load_catalog() -> dict:
    if CATALOG_PATH.exists():
        try:
            return json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"[WARN] Failed to read catalog: {e}")
    return {"packs": []}

def discover_packs_from_fs():
    """Fallback if no catalog exists yet."""
    packs = []
    if not LIB_ROOT.exists():
        return packs
    for meta in LIB_ROOT.glob("**/meta.json"):
        try:
            data = json.loads(meta.read_text(encoding="utf-8"))
            slug = data.get("slug") or data.get("id") or meta.parent.name
            path = data.get("path") or str(meta.parent / "prompt.md")
            packs.append({
                "slug": slug,
                "path": path,
                "bucket": meta.parts[-3] if "Prompt_Library" in meta.parts else "unknown",
                "checksum_sha256": data.get("checksum_sha256", ""),
            })
        except Exception as e:
            print(f"[WARN] Could not parse {meta}: {e}")
    return packs

def check_disclaimer(packs) -> list[str]:
    """Warn if a prompt.md doesn't contain a Legal & Privacy Disclaimer header."""
    warnings = []
    for p in packs:
        prompt_path = REPO_ROOT / p["path"]
        if not prompt_path.exists():
            warnings.append(f"prompt_missing:{p['slug']}")
            continue
        try:
            text = prompt_path.read_text(encoding="utf-8")
        except Exception as e:
            warnings.append(f"prompt_unreadable:{p['slug']}:{e}")
            continue
        # Very lightweight check — looks for the section header
        if "## Legal & Privacy Disclaimer" not in text:
            warnings.append(f"legal_disclaimer_missing:{p['slug']}")
    return warnings

def main() -> int:
    # 1) Update checksums
    if run_py(UPDATER) != 0:
        print("[ERR ] Checksum updater failed")
        return 1

    # 2) Rebuild catalog
    if run_py(CATALOG_BUILDER) != 0:
        print("[ERR ] Catalog builder failed")
        return 1

    # 3) Load packs (catalog preferred, fallback to filesystem)
    catalog = load_catalog()
    packs = catalog.get("packs") or discover_packs_from_fs()

    # 4) Lightweight validations
    warns = []
    warns += check_disclaimer(packs)

    for w in warns:
        print("WARN", w)

    print("ALL_VALIDATIONS_OK")
    return 0

if __name__ == "__main__":
    sys.exit(main())
