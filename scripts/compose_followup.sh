#!/usr/bin/env bash
set -euo pipefail
recip="${1:?recipient name}"; shift
sender="${1:?sender name}"; shift
days="${1:?days since last contact}"; shift
context="${*:-}"
if ! command -v jq >/dev/null 2>&1; then echo "❌ jq required"; exit 1; fi
tmpcase="$(mktemp -t fg_case_XXXX).json"
jq -n --arg r "$recip" --arg s "$sender" --argjson d "$days" --arg c "$context" '{recipient:$r, sender:$s, last_contact_days:$d, context:$c}' > "$tmpcase"
echo "▶︎ Case: $tmpcase"
[ -x scripts/run_followup.sh ] || { echo "❌ scripts/run_followup.sh missing or not executable"; exit 2; }
scripts/run_followup.sh "$tmpcase" > /tmp/fg_msg.txt
mkdir -p tests/.runs
ts="$(date +%Y%m%d-%H%M%S)"
out="tests/.runs/${ts}_${recip// /_}.out"
cp /tmp/fg_msg.txt "$out"
echo "▶︎ Wrote $out"
command -v pbcopy >/dev/null && pbcopy < "$out" && echo "📋 Copied to clipboard."
echo "------"
cat "$out"
echo "------"
