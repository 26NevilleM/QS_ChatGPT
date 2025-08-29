#!/usr/bin/env bash
set -euo pipefail
# Expects the generated body on STDIN; passes summary + extra through to style helper.
SUMMARY_LINE="${1:-}"   # first arg = summary string (optional)
EXTRA_LINE="${2:-}"     # second arg (optional)
BODY="$(cat -)"         # message body from pipeline
# We only replace the BODY if followup_style exists (otherwise pass-through)
if [ -x "scripts/followup_style.sh" ]; then
  scripts/followup_style.sh "${SUMMARY_LINE}" "${EXTRA_LINE}"
else
  printf "%s\n" "$BODY"
fi
