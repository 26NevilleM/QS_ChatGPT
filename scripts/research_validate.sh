#!/usr/bin/env bash
set -euo pipefail
f="${1:?json file}"
jq 'has("deliverables") and has("risks") and has("open_questions") and has("uncertainties")' "$f" | grep -q true || { echo "❌ Missing top-level keys"; exit 2; }
jq '.deliverables | type=="array"' "$f" | grep -q true || { echo "❌ deliverables not array"; exit 3; }
echo "✅ JSON shape looks good."
