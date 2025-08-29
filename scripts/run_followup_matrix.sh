#!/usr/bin/env bash
set -euo pipefail
matrix="${1:-tests/matrix.csv}"

if [ ! -f "$matrix" ]; then
  echo "❌ matrix file not found: $matrix"; exit 1
fi

mkdir -p tests/.runs

# read CSV lines: recipient,sender,days,context
while IFS=',' read -r recip sender days context; do
  # Trim whitespace
  recip="${recip#"${recip%%[![:space:]]*}"}"; recip="${recip%"${recip##*[![:space:]]}"}"
  sender="${sender#"${sender%%[![:space:]]*}"}"; sender="${sender%"${sender##*[![:space:]]}"}"
  days="${days#"${days%%[![:space:]]*}"}";   days="${days%"${days##*[![:space:]]}"}"
  context="${context#"${context%%[![:space:]]*}"}"; context="${context%"${context##*[![:space:]]}"}"

  # Skip empty or comment lines
  [ -z "$recip" ] && continue
  case "$recip" in \#*) continue ;; esac

  tmpcase="$(mktemp -t fg_case_XXXX).json"
  {
    printf '{'
    printf '"context":%s,'  "$(printf %s "$context" | jq -Rs .)"
    printf '"recipient":%s,' "$(printf %s "$recip"  | jq -Rs .)"
    printf '"sender":%s,'    "$(printf %s "$sender" | jq -Rs .)"
    printf '"last_contact_days":%s' "$(printf %s "$days")"
    printf '}\n'
  } > "$tmpcase"

  echo "▶︎ Running: $recip / $sender / $days"
  bash -x scripts/followup_cli.sh "$tmpcase" || { echo "❌ fail for $tmpcase"; exit 1; }

done < "$matrix"

# show latest few results
echo
echo "Last generated outputs:"
ls -lt tests/.runs | head -n 6 || true

# Copy the latest to clipboard for quick paste
last="$(ls -t tests/.runs/*.out | head -n 1 2>/dev/null || true)"
if [ -n "${last:-}" ] && command -v pbcopy >/dev/null; then
  pbcopy < "$last"
  echo "📋 Copied latest to clipboard: $last"
fi
echo "✅ Matrix run complete."
