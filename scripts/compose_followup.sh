#!/usr/bin/env bash
set -euo pipefail
recip="${1:?recipient name}"; shift
sender="${1:?sender name}"; shift
days="${1:?last_contact_days int}"; shift
context="${*:-}"

tmpcase="$(mktemp -t fg_case_XXXX).json"
printf '{"context":%s,"recipient":%s,"sender":%s,"last_contact_days":%s}\n' \
  "$(jq -Rs . <<<"$context")" \
  "$(jq -Rs . <<<"$recip")" \
  "$(jq -Rs . <<<"$sender")" \
  "$days" > "$tmpcase"

scripts/run_followup.sh "$tmpcase" | tee /tmp/followup.out
command -v pbcopy >/dev/null && pbcopy < /tmp/followup.out && echo "📋 Copied to clipboard."
