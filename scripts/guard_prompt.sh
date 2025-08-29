#!/usr/bin/env bash
set -euo pipefail
file="${1:?path to prompt.md}"
req=( '{{recipient}}' '{{sender}}' '{{last_contact_days}}' '{{context}}' )
miss=()
for t in "${req[@]}"; do grep -qF -- "$t" "$file" || miss+=("$t"); done
((${#miss[@]})) && { echo "❌ Missing:"; printf '  - %s\n' "${miss[@]}"; exit 1; }
echo "✅ All required tokens present in $file"
