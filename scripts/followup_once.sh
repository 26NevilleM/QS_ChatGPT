#!/usr/bin/env bash
set -euo pipefail

followup_once() {
  recip="$1"; sender="$2"; days="$3"; shift 3
  ctx="$*"
  # Trim trailing spaces and periods (one or many); DO NOT add a period here.
  ctx="$(printf %s "$ctx" | sed -E 's/[[:space:]]+$//; s/[.]+$//'')"
  scripts/followup "$recip" "$sender" "$days" "$ctx"
}

# pass-through so you can also call this file directly
followup_once "$@"
