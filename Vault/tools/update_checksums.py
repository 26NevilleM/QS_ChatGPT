#!/usr/bin/env python3
import json, hashlib, pathlib, shutil

ROOT = pathlib.Path(__file__).resolve().parents[2]
PL = ROOT / "Vault" / "Prompt_Library"
SETTINGS = [PL / "active", PL / "sandbox"]

def sha256_bytes(p: pathlib.Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()

def process_dir(d: pathlib.Path):
    if not d.is_dir(): return
    pmd = d / "prompt.md"
    meta = d / "meta.json"
    if not (pmd.exists() and meta.exists()): return
    chk = sha256_bytes(pmd)

    data = json.loads(meta.read_text(encoding="utf-8"))
    old = data.get("checksum_sha256")
    if old == chk:
        print(f"[OK]  {d.name} checksum already up to date")
        return

    shutil.copy2(meta, meta.with_suffix(".json.bak"))
    data["checksum_sha256"] = chk
    meta.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"[FIX] {d.name} -> checksum_sha256 updated")

def main():
    for bucket in SETTINGS:
        if not bucket.exists(): continue
        for child in sorted(bucket.iterdir()):
            process_dir(child)

if __name__ == "__main__":
    main()
