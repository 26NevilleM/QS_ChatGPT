#!/usr/bin/env bash
set -euo pipefail

# Accept either:
#  A) a plain topic string  -> we will wrap it into a temp JSON case
#  B) a path to a JSON case -> we will use it as-is
arg="${1:?topic string or path to case.json}"

make_case() {
  local topic="$1"
  local tmpcase
  tmpcase="$(mktemp -t beast_case_XXXX).json"

  # Use env vars if present; provide soft defaults
  : "${BEAST_CONTACT_NAME:=Jordan}"
  : "${BEAST_SENDER_NAME:=Neville}"
  : "${BEAST_LAST_CONTACT_DAYS:=5}"

  # Build minimal case JSON
  {
    printf '{'
    printf '"context":%s,' "$(printf %s "$topic" | jq -Rs .)"
    printf '"recipient":%s,' "$(printf %s "$BEAST_CONTACT_NAME" | jq -Rs .)"
    printf '"sender":%s,'    "$(printf %s "$BEAST_SENDER_NAME"   | jq -Rs .)"
    printf '"last_contact_days":%s' "${BEAST_LAST_CONTACT_DAYS}"
    printf '}\n'
  } > "$tmpcase"

  echo "$tmpcase"
}

casefile=""
if [ -f "$arg" ] && [ "${arg##*.}" = "json" ]; then
  casefile="$arg"
else
  casefile="$(make_case "$arg")"
fi

# Run your working runner
scripts/followup_cli.sh "$casefile"

# Find newest pair and inject research snippet into the follow-up
R="$(ls -t tests/.research_runs/*_research.txt 2>/dev/null | head -n 1 || true)"
F="$(ls -t tests/.runs/*_followup.out      2>/dev/null | head -n 1 || true)"
if [ -n "${R:-}" ] && [ -n "${F:-}" ]; then
  scripts/inject_research_into_followup.sh "$R" "$F" || true
fi
