#!/usr/bin/env bash
set -euo pipefail
recipient="${1:?recipient}"; sender="${2:?sender}"; days="${3:?days}"; shift 3
context="${*:-}"
tmp="$(mktemp -t fg_case_XXXX).json"
printf '{"context":%s,"recipient":%s,"sender":%s,"last_contact_days":%s}\n' \
  "$(jq -Rn --arg s "$context" '$s')" \
  "$(jq -Rn --arg s "$recipient" '$s')" \
  "$(jq -Rn --arg s "$sender" '$s')" \
  "$(jq -Rn --arg s "$days" '$s')" > "$tmp"
bash scripts/followup_cli.sh "$tmp"
