#!/usr/bin/env bash
set -euo pipefail
style="${1:?style: neutral|direct|casual}"
recipient="${2:?recipient}"; sender="${3:?sender}"; days="${4:?days}"; shift 4 || true
context="${*:-}"
scripts/filter_followup.sh --style="$style" "$recipient" "$sender" "$days" "$context"
