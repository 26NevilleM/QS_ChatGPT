#!/usr/bin/env bash
set -euo pipefail

scripts/guard_prompt.sh "Vault/Prompt_Library/active/followup_generator/prompt.md"

fails=0
run_and_check () {
  local label="$1"; shift
  local out
  if ! out="$("$@" 2>&1)"; then
    echo "❌ $label failed to run"
    echo "── stderr/stdout ─────────────────────────"
    echo "$out"
    echo "──────────────────────────────────────────"
    return 1
  fi
  if ! grep -q '[[:alnum:]]' <<<"$out"; then
    echo "❌ $label produced empty output"
    return 1
  fi
  echo "✅ $label ok"
}

run_and_check "neutral" scripts/followup_once.sh "Alex"   "Neville" 2 "Schedule a quick review" || fails=$((fails+1))
run_and_check "warm"    scripts/followup_once.sh --tone warm  "Jordan" "Neville" 5 "Lock scope and dates" || fails=$((fails+1))
run_and_check "soft"    scripts/followup_once.sh --tone soft  "Taylor" "Neville" 3 "Confirm kickoff timing" || fails=$((fails+1))
run_and_check "direct"  scripts/followup_once.sh --tone direct "Rory"   "Neville" 1 "Send agenda" || fails=$((fails+1))

if ((fails>0)); then
  echo "❌ Smoke test had $fails failure(s)."
  exit 1
fi

echo "✅ Smoke tests passed."
