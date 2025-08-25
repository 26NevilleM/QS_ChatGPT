#!/usr/bin/env python3
"""
Update checksum_sha256 in every meta.json that sits next to a prompt.md,
no matter where it lives in the repo.

Usage:
  python3 Vault/tools/update_checksums.py
"""

from __future__ import annotations

import hashlib
import json
import shutil
from pathlib import Path
from typing import Iterable

# Globs we’ll scan for meta.json files. Add more if you use other layouts.
META_GLOBS: list[str] = [
    "Vault/**/meta.json",
    "Packs/**/meta.json",
    "**/Prompt_Library/**/meta.json",
    # fallback for any other folders — this is wide but filtered later
    "**/meta.json",
]

REPO_ROOT = Path.cwd()


def sha256_of(file: Path) -> str:
    h = hashlib.sha256()
    with file.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def discover_meta_files(root: Path) -> Iterable[Path]:
    seen: set[Path] = set()
    for pattern in META_GLOBS:
        for p in root.glob(pattern):
            # Only keep files actually named meta.json
            if p.name != "meta.json":
                continue
            # De-dup in case multiple globs hit the same file
            if p.resolve() in seen:
                continue
            seen.add(p.resolve())
            yield p


def process_dir(meta_path: Path) -> None:
    """Given path to meta.json, update checksum if sibling prompt.md exists."""
    d = meta_path.parent
    prompt = d / "prompt.md"
    if not prompt.is_file():
        print(f"[SKIP] {d} — no prompt.md")
        return

    # Load meta.json (tolerate UTF-8)
    try:
        data = json.loads(meta_path.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[ERR ] {meta_path}: cannot read/parse JSON: {e}")
        return

    # Compute checksum for prompt.md
    chk = sha256_of(prompt)
    old = data.get("checksum_sha256")

    if old == chk:
        print(f"[OK  ] {d.name} — checksum up to date")
        return

    # Backup and write
    try:
        shutil.copy2(meta_path, meta_path.with_suffix(".json.bak"))
    except Exception as e:
        print(f"[WARN] Could not create backup for {meta_path}: {e}")

    data["checksum_sha256"] = chk
    try:
        meta_path.write_text(
            json.dumps(data, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        action = "added" if old in (None, "") else "updated"
        print(f"[FIX ] {d.name} — checksum {action}")
    except Exception as e:
        print(f"[ERR ] {meta_path}: failed to write: {e}")


def main() -> None:
    any_found = False
    for meta in discover_meta_files(REPO_ROOT):
        any_found = True
        # Only process when there is a sibling prompt.md to hash
        if (meta.parent / "prompt.md").exists():
            process_dir(meta)
    if not any_found:
        print("[INFO] No meta.json files found. Nothing to do.")


if __name__ == "__main__":
    main()
