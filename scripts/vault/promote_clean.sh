#!/bin/bash
set -euo pipefail

auto=0
if [[ "${1:-}" == "-y" ]]; then auto=1; shift; fi
slug="${1:?Usage: promote_clean.sh [-y] <slug>}"

base="$HOME/Library/CloudStorage/GoogleDrive-design@qsurgical.co.za/My Drive/QS_ChatGPT/Vault/Prompt_Library"
active="$base/active/$slug/prompt.md"
sandbox="$base/sandbox/$slug/prompt.md"

echo "🔍 Diff between sandbox and active ($slug):"
diff -u "$active" "$sandbox" || true
echo

if [[ $auto -eq 1 ]]; then
  resp="y"
else
  read -r -p "Promote cleaned sandbox → active? (y/N) " resp
fi

if [[ "$resp" =~ ^[Yy]$ ]]; then
  cp -v "$sandbox" "$active"
  echo "✅ Promoted $slug (sandbox → active)"
else
  echo "❌ Aborted promotion."
  exit 2
fi

# Optional: quick smoke (won't fail the script if unavailable)
if command -v run_prompt >/dev/null 2>&1; then
  echo "---- SMOKE TEST ----"
  run_prompt "$slug" --input '{"context":"post-promo","recipient":"QA","sender":"Neville"}' >/dev/null || true
fi
