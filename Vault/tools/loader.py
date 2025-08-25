#!/usr/bin/env python3
"""
Loader utility for Prompt Library.

Usage (from Python):
    from Vault.tools.loader import load_prompt

    data = load_prompt("demo_001_hello")
    print(data["meta"]["title"])
    print(data["text"])
"""

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
CATALOG_PATH = REPO_ROOT / "Vault" / "Prompt_Catalog.json"

def load_catalog() -> dict:
    if not CATALOG_PATH.exists():
        raise FileNotFoundError(f"Prompt catalog not found at {CATALOG_PATH}")
    return json.loads(CATALOG_PATH.read_text(encoding="utf-8"))

def load_prompt(slug: str) -> dict:
    catalog = load_catalog()
    matches = [p for p in catalog.get("packs", []) if p.get("slug") == slug]
    if not matches:
        raise KeyError(f"Prompt slug '{slug}' not found in catalog")

    pack = matches[0]
    prompt_path = REPO_ROOT / pack["path"]
    if not prompt_path.exists():
        raise FileNotFoundError(f"Prompt file missing: {prompt_path}")

    text = prompt_path.read_text(encoding="utf-8")
    return {
        "meta": pack,
        "text": text,
    }

if __name__ == "__main__":
    # Demo run
    try:
        demo = load_prompt("demo_001_hello")
        print(json.dumps(demo["meta"], indent=2, ensure_ascii=False))
        print("---")
        print(demo["text"])
    except Exception as e:
        print(f"[ERR] {e}")
