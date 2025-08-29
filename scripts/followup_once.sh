#!/usr/bin/env bash
set -euo pipefail

followup_once() {
  recip="$1"; sender="$2"; days="$3"; shift 3
  ctx="$*"
  # Trim trailing spaces
  while [[ "$ctx" =~ [[:space:]]$ ]]; do ctx="${ctx% }"; done
  # Trim trailing dots
  while [[ "$ctx" =~ \.$ ]]; do ctx="${ctx%.}"; done
  scripts/followup "$recip" "$sender" "$days" "$ctx"
}

followup_once "$@"
