#!/usr/bin/env bash
set -euo pipefail
slug="${1:?usage: promote_clean.sh <slug>}"
base="Vault/Prompt_Library"
active="$base/active/$slug/prompt.md"
sandbox="$base/sandbox/$slug/prompt.md"

echo "🔍 Diff (ACTIVE vs SANDBOX):"
diff -u "$active" "$sandbox" || true

echo
echo "🔒 Guard checks:"
scripts/guard_prompt.sh "$sandbox"
scripts/guard_prompt.sh "$active" || true

echo
read -r -p "Promote SANDBOX → ACTIVE? (y/N) " resp
if [[ "$resp" =~ ^[yY]$ ]]; then
  cp -v "$sandbox" "$active"
  echo "✅ Promoted $slug"
else
  echo "❌ Aborted."
fi
