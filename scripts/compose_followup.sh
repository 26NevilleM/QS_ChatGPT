#!/usr/bin/env bash
set -euo pipefail

recip="${1:?Recipient name}"; shift
sender="${1:?Sender name}"; shift
days="${1:?Days since last contact (int)}"; shift
context="${*:-}"

casefile="$(mktemp -t fg_case_XXXX).json"
printf '{"context":%s,"recipient":%s,"sender":%s,"last_contact_days":%s}\n' \
  "$(jq -Rs . <<<"$context")" \
  "$(jq -Rs . <<<"$recip")" \
  "$(jq -Rs . <<<"$sender")" \
  "$days" > "$casefile"

scripts/run_followup.sh "$casefile" > /tmp/fg_out.txt

mkdir -p tests/.runs
outfile="tests/.runs/$(date +%Y%m%d-%H%M%S)_followup.out"
cp /tmp/fg_out.txt "$outfile"
command -v pbcopy >/dev/null && pbcopy < "$outfile" && echo "📋 Copied to clipboard."
echo "✅ Wrote: $outfile"
