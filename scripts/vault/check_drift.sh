#!/bin/bash
set -euo pipefail
slug="${1:?Usage: check_drift <slug>}"
base="$HOME/Library/CloudStorage/GoogleDrive-design@qsurgical.co.za/My Drive/QS_ChatGPT/Vault/Prompt_Library"
active="$base/active/$slug/prompt.md"
sandbox="$base/sandbox/$slug/prompt.md"

if diff -q "$active" "$sandbox" >/dev/null; then
  echo "✅ No drift: $slug active == sandbox"
  exit 0
else
  echo "❌ Drift detected: $slug active ≠ sandbox"
  diff -u "$active" "$sandbox" | head -n 50
  exit 1
fi
