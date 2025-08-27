#!/usr/bin/env bash
set -euo pipefail
recip="${1:?recipient}"; shift
sender="${1:?sender}"; shift
days="${1:?days}"; shift
context="${*:-}"
tmp="$(mktemp -t fg_case_XXXX).json"
jq -n --arg r "$recip" --arg s "$sender" --argjson d "$days" --arg c "$context" \
  '{recipient:$r,sender:$s,last_contact_days:$d,context:$c}' > "$tmp"
scripts/run_followup.sh "$tmp"
