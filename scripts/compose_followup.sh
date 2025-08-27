#!/usr/bin/env bash
# usage: scripts/compose_followup.sh "Recipient Name" "Sender Name" DAYS "context text..."
recip="${1:?recipient name}"; shift
sender="${1:?sender name}";   shift
days="${1:?last_contact_days int}"; shift
context="${*:-}"

tmpcase="$(mktemp -t fg_case_XXXX).json"
printf '{"context":%s,"recipient":%s,"sender":%s,"last_contact_days":%s}\n' \
  "$(jq -Rs . <<<"$context")" \
  "$(jq -Rs . <<<"$recip")" \
  "$(jq -Rs . <<<"$sender")" \
  "$(jq -nr --arg d "$days" '$d|tonumber')" > "$tmpcase"

scripts/run_followup.sh "$tmpcase"
