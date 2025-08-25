#!/usr/bin/env python3
"""
Catalog builder: scans Vault/Prompt_Library and writes Vault/Prompt_Catalog.json

Usage:
  python3 Vault/tools/build_catalog.py

Also exposes:
  from Vault.tools.build_catalog import build_catalog
  result = build_catalog()
"""
from __future__ import annotations
import hashlib, json, sys
from pathlib import Path
from typing import Dict, List

THIS_FILE = Path(__file__).resolve()
REPO_ROOT = THIS_FILE.parents[2]
VAULT_ROOT = REPO_ROOT / "Vault"
LIB_ROOT   = VAULT_ROOT / "Prompt_Library"
OUT_PATH   = VAULT_ROOT / "Prompt_Catalog.json"

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def build_catalog() -> Dict:
    packs: List[Dict] = []
    issues: List[str] = []

    for bucket in ("active", "sandbox"):
        root = LIB_ROOT / bucket
        if not root.exists():
            continue
        for meta in sorted(root.glob("*/meta.json")):
            try:
                meta_data = json.loads(meta.read_text(encoding="utf-8"))
            except Exception as e:
                issues.append(f"{bucket}/{meta.parent.name}: invalid JSON ({e})")
                continue

            slug = meta_data.get("slug", meta.parent.name)
            prompt_path = REPO_ROOT / meta_data.get("path", "")
            if not prompt_path.exists():
                sibling = meta.parent / "prompt.md"
                if sibling.exists():
                    prompt_path = sibling
                else:
                    issues.append(f"{bucket}/{slug}: prompt.md missing")
                    continue

            actual = sha256_file(prompt_path)
            declared = str(meta_data.get("checksum_sha256", "")).strip()
            meta_data["checksum_verified"] = (declared == actual)

            pack = {
                **meta_data,
                "bucket": bucket,
                "checksum_sha256": actual,
            }
            packs.append(pack)

    catalog = {
        "catalog_version": 1,
        "generated_at": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "root": str(LIB_ROOT),
        "packs": packs,
        "summary": {
            "total": len(packs),
            "by_bucket": {
                "active": sum(1 for p in packs if p["bucket"] == "active"),
                "sandbox": sum(1 for p in packs if p["bucket"] == "sandbox"),
            },
            "checksum_ok": sum(1 for p in packs if p.get("checksum_verified")),
            "checksum_bad": sum(1 for p in packs if not p.get("checksum_verified")),
        },
        "notes": { "issues": issues }
    }

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(f"[OK] Wrote catalog -> {OUT_PATH}")
    if issues:
        print("[WARN] Some packs had issues:")
        for i in issues:
            print(" -", i)

    return catalog

def main() -> int:
    build_catalog()
    return 0

if __name__ == "__main__":
    sys.exit(main())
