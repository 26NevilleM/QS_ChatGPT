#!/usr/bin/env python3
import json, sys, hashlib, os
from pathlib import Path
from datetime import datetime, timezone

REPO_ROOT = Path(__file__).resolve().parents[2]
LIB_ROOT  = REPO_ROOT / "Vault" / "Prompt_Library"
OUT_PATH  = REPO_ROOT / "Vault" / "Prompt_Catalog.json"

def sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()

def list_packs():
    packs = []
    for bucket in ("active", "sandbox"):
        bdir = LIB_ROOT / bucket
        if not bdir.exists():
            continue
        for d in sorted(p for p in bdir.iterdir() if p.is_dir()):
            meta = d / "meta.json"
            prompt = d / "prompt.md"
            if not meta.exists() or not prompt.exists():
                continue
            try:
                m = json.loads(meta.read_text(encoding="utf-8"))
            except Exception:
                continue
            # Normalize minimal shape we need in the catalog
            entry = {
                "slug": m.get("slug") or d.name,
                "title": m.get("title") or d.name,
                "id": m.get("id") or d.name,
                "path": str((Path("Vault") / "Prompt_Library" / bucket / d.name / "prompt.md").as_posix()),
                "bucket": bucket,
                "owner": m.get("owner"),
                "persona": m.get("persona") or [],
                "use_case": m.get("use_case") or [],
                "version": m.get("version"),
                "status": m.get("status") or ("active" if bucket=="active" else "sandbox"),
                "tags": m.get("tags") or [],
                "created": m.get("created"),
                "updated": m.get("updated"),
                "checksum_sha256": m.get("checksum_sha256") or "",
            }
            # Verify checksum against prompt content
            try:
                chk = sha256_bytes(prompt.read_bytes())
                entry["checksum_verified"] = (chk == entry["checksum_sha256"])
            except Exception:
                entry["checksum_verified"] = False
            packs.append(entry)
    return packs

def compute_fingerprint(packs):
    # Remove volatile fields
    stable = []
    for p in packs:
        q = {k: v for k, v in p.items() if k not in ("checksum_verified",)}
        stable.append(q)
    payload = json.dumps({"root":"Vault/Prompt_Library","packs":stable}, sort_keys=True, ensure_ascii=False).encode("utf-8")
    return sha256_bytes(payload)

def build_catalog():
    packs = list_packs()
    fingerprint = compute_fingerprint(packs)

    # If existing file has same fingerprint, do nothing (keep generated_at stable)
    if OUT_PATH.exists():
        try:
            current = json.loads(OUT_PATH.read_text(encoding="utf-8"))
            if current.get("fingerprint") == fingerprint:
                print("[OK] Catalog unchanged; skipped rewrite")
                return current
        except Exception:
            pass

    catalog = {
        "catalog_version": 1,
        "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00","Z"),
        "root": "Vault/Prompt_Library",
        "packs": packs,
        "summary": {
            "total": len(packs),
            "by_bucket": {
                "active": sum(1 for p in packs if p["bucket"]=="active"),
                "sandbox": sum(1 for p in packs if p["bucket"]=="sandbox"),
            },
            "checksum_ok": sum(1 for p in packs if p.get("checksum_verified")),
            "checksum_bad": sum(1 for p in packs if not p.get("checksum_verified")),
        },
        "notes": {"issues": []},
        "fingerprint": fingerprint,
    }

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"[OK] Wrote catalog -> {OUT_PATH}")
    return catalog

def main() -> int:
    build_catalog()
    return 0

if __name__ == "__main__":
    sys.exit(main())
