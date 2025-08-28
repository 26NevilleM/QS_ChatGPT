#!/usr/bin/env bash
set -euo pipefail
recip="${1:?recipient name}"; shift
sender="${1:?sender name}"; shift
days="${1:?last_contact_days int}"; shift
context="${*:-}"

tmpcase="$(mktemp -t fg_case_XXXX).json"
jq -n \
  --arg r "$recip" \
  --arg s "$sender" \
  --argjson d "$days" \
  --arg c "$context" \
  '{recipient:$r, sender:$s, last_contact_days:$d, context:$c}' > "$tmpcase"

out="tests/.runs/$(date +%Y%m%d-%H%M%S)_followup.out"
scripts/run_followup.sh "$tmpcase" | tee "$out"
command -v pbcopy >/dev/null && pbcopy < "$out" && echo "📋 Copied to clipboard: $out"
