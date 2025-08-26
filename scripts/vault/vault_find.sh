#!/usr/bin/env bash
set -euo pipefail

# Find repo root: git if available, else script dir, else CWD
if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  # script directory fallback
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  root="$script_dir/../.."
fi

cd "$root" 2>/dev/null || { echo "ERROR: cannot cd to repo root: $root"; exit 1; }
[ -d Vault ] || { echo "ERROR: Vault/ directory not found at: $root"; exit 1; }

# require at least one search term
[ $# -ge 1 ] || { echo "usage: vault_find.sh <pattern>"; exit 2; }
q="$*"

if command -v rg >/dev/null 2>&1; then
  rg --hidden --no-ignore -n --glob 'Vault/**' --line-number --color=never "$q"
else
  grep -RIn --exclude-dir='.git' -e "$q" Vault || true
fi
