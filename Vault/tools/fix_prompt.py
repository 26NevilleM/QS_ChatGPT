#!/usr/bin/env python3
"""
Quick fixer for prompt.md packs:
1. Recompute checksum
2. Rebuild catalog
3. Run validator
4. Stage + commit + push changes
"""

import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
CATALOG = REPO_ROOT / "Vault" / "Prompt_Catalog.json"

def run(cmd, check=True):
    print(f"[RUN ] {' '.join(cmd)}")
    return subprocess.run(cmd, check=check)

def main():
    # 1) Update checksums
    run(["python3", "Vault/tools/update_checksums.py"])

    # 2) Rebuild catalog
    run(["python3", "Vault/tools/build_catalog.py"])

    # 3) Run validator
    run(["python3", "Vault/tools/validate_all.py"])

    # 4) Git add + commit + push
    run(["git", "add", "-A"])
    msg = sys.argv[1] if len(sys.argv) > 1 else "chore: auto-fix prompt pack"
    run(["git", "commit", "-m", msg, "--allow-empty"])
    run(["git", "push"])

    print("[OK] Prompt pack fix complete.")

if __name__ == "__main__":
    main()
