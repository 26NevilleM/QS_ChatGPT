#!/usr/bin/env python3
import hashlib, json, sys
from pathlib import Path
from datetime import datetime

REPO_ROOT = Path(__file__).resolve().parents[2]  # .../QS_ChatGPT
LIB_ROOT  = REPO_ROOT / "Vault" / "Prompt_Library"
BUCKETS   = ["active", "sandbox"]
OUT_PATH  = REPO_ROOT / "Vault" / "Prompt_Catalog.json"

def sha256_text(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def load_pack(dir_path: Path):
    meta = dir_path / "meta.json"
    prompt = dir_path / "prompt.md"
    if not (meta.exists() and prompt.exists()):
        return None, f"skip: missing files ({'meta' if not meta.exists() else ''}{'+' if (not meta.exists() and not prompt.exists()) else ''}{'prompt' if not prompt.exists() else ''})"

    try:
        data = json.loads(meta.read_text(encoding="utf-8"))
    except Exception as e:
        return None, f"bad meta.json: {e}"

    # verify checksum
    calc = sha256_text(prompt)
    meta_sum = data.get("checksum_sha256") or ""
    checksum_ok = (calc == meta_sum)

    entry = {
        "slug": data.get("slug"),
        "title": data.get("title"),
        "id": data.get("id"),
        "path": str(prompt.relative_to(REPO_ROOT)),
        "bucket": dir_path.parent.name,  # active/sandbox
        "owner": data.get("owner"),
        "persona": data.get("persona", []),
        "use_case": data.get("use_case", []),
        "version": data.get("version"),
        "status": data.get("status"),
        "tags": data.get("tags", []),
        "created": data.get("created"),
        "updated": data.get("updated"),
        "checksum_sha256": meta_sum,
        "checksum_verified": checksum_ok,
    }
    # Fill any obvious missing identifiers
    if not entry["slug"]:
        entry["slug"] = dir_path.name
    if not entry["id"]:
        entry["id"] = entry["slug"]
    if not entry["title"]:
        entry["title"] = entry["slug"].replace("_", " ").title()

    return entry, None

def main():
    packs = []
    issues = []

    for bucket in BUCKETS:
        bucket_dir = LIB_ROOT / bucket
        if not bucket_dir.exists():
            continue
        for child in sorted(p for p in bucket_dir.iterdir() if p.is_dir()):
            entry, err = load_pack(child)
            if entry:
                packs.append(entry)
            else:
                issues.append(f"[{bucket}/{child.name}] {err}")

    catalog = {
        "catalog_version": 1,
        "generated_at": datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "root": str(LIB_ROOT.relative_to(REPO_ROOT)),
        "packs": packs,
        "summary": {
            "total": len(packs),
            "by_bucket": {
                b: sum(1 for p in packs if p["bucket"] == b) for b in BUCKETS
            },
            "checksum_ok": sum(1 for p in packs if p["checksum_verified"]),
            "checksum_bad": sum(1 for p in packs if not p["checksum_verified"]),
        },
        "notes": {
            "issues": issues
        }
    }

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    # friendly console output
    print(f"[OK] Wrote catalog -> {OUT_PATH}")
    if issues:
        print("[WARN] Some packs were skipped or have issues:")
        for i in issues:
            print(" -", i)
    bad = [p["slug"] for p in packs if not p["checksum_verified"]]
    if bad:
        print("[WARN] Checksum mismatches for:", ", ".join(bad))

if __name__ == "__main__":
    sys.exit(main())
