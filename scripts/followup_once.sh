#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/followup_once.sh [--copy|-c] "Recipient" "Sender" DAYS "Context text..."
#   FG_COPY=1 scripts/followup_once.sh "Recipient" "Sender" DAYS "Context"

copy=0
if [[ "${1:-}" == "--copy" || "${1:-}" == "-c" ]]; then
  copy=1
  shift
fi

recip="${1:?recipient}"; sender="${2:?sender}"; days="${3:?days}"; shift 3
ctx="$*"

# Trim trailing spaces
while [[ "$ctx" =~ [[:space:]]$ ]]; do ctx="${ctx% }"; done
# Trim trailing dots
while [[ "$ctx" =~ \.$ ]]; do ctx="${ctx%.}"; done

# Generate the message using your existing runner
out="$(scripts/followup "$recip" "$sender" "$days" "$ctx")"

# Always print to terminal
printf "%s\n" "$out"

# Save a quick artifact for convenience
mkdir -p tests/.runs
ts="$(date +%Y%m%d-%H%M%S)"
runfile="tests/.runs/${ts}_${recip// /_}.txt"
printf "%s\n" "$out" > "$runfile"
echo "🗂  Saved: $runfile"

# Optional clipboard copy (flag or env FG_COPY=1), macOS only
if [[ "$copy" -eq 1 || "${FG_COPY:-0}" -eq 1 ]]; then
  if command -v pbcopy >/dev/null 2>&1; then
    printf "%s" "$out" | pbcopy
    echo "📋 Copied to clipboard."
  else
    echo "ℹ️  Clipboard copy requested but pbcopy not found (non-macOS?)."
  fi
fi

