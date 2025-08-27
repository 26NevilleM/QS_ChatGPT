#!/usr/bin/env bash
set -euo pipefail
file="${1:?path to prompt.md}"
required=( '{{recipient}}' '{{sender}}' '{{last_contact_days}}' '{{context}}' )
missing=()
for t in "${required[@]}"; do
  if ! grep -qF -- "$t" "$file"; then
    missing+=("$t")
  fi
done
if ((${#missing[@]})); then
  echo "❌ Missing required tokens in: $file"
  printf '   - %s\n' "${missing[@]}"
  exit 1
fi
echo "✅ Tokens present in $file"
