#!/bin/sh
set -u

# Resolve repo root relative to this script (portable)
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)" || exit 1
root="$(CDPATH= cd -- "$script_dir/../.." 2>/dev/null && pwd)" || exit 1
cd "$root" || exit 1
[ -d Vault ] || { echo "ERROR: Vault/ not found at $root" >&2; exit 2; }

pattern="$*"
[ -n "$pattern" ] || { echo "usage: vf_min.sh <pattern>" >&2; exit 2; }

if command -v rg >/dev/null 2>&1; then
  # ripgrep, restricted to Vault/** and quiet about permission noise
  rg -n -S --no-messages --color=never -g 'Vault/**' -- "$pattern"
else
  # grep fallback
  grep -RIn --exclude-dir='.git' -e "$pattern" Vault 2>/dev/null
fi

exit 0
