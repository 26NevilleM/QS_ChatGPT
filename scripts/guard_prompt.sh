#!/usr/bin/env bash
set -euo pipefail
file="${1:?path to prompt.md}"
need=( '{{recipient}}' '{{sender}}' '{{last_contact_days}}' '{{context}}' )
miss=(); for t in "${need[@]}"; do grep -qF -- "$t" "$file" || miss+=("$t"); done
((${#miss[@]})) && { printf "❌ Missing tokens in %s:\n" "$file"; printf "  - %s\n" "${miss[@]}"; exit 1; }
echo "✅ Tokens present in $file"
