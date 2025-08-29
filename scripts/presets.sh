#!/usr/bin/env bash
set -euo pipefail
tone="${1:-neutral}"
case "$tone" in
  neutral)  opener="Just a quick note"; close="whatever is easiest on your side." ;;
  warmer)   opener="Hope you’re well—just a quick note"; close="happy to make this easy on your side." ;;
  direct)   opener="Following up to keep momentum"; close="can confirm next steps right away." ;;
  lighter)  opener="A quick nudge"; close="no rush at all." ;;
  *)        opener="Just a quick note"; close="whatever is easiest on your side." ;;
esac
printf '%s\n' "$opener" "$close"
