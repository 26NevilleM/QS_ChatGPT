#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"
dir="Vault/Packs"
[ -d "$dir" ] || { echo "No Packs dir"; exit 0; }
find "$dir" -type f -name '*.zip' -print0 | xargs -0 ls -lt || true
