#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/test_styles.sh "Recipient" "Sender" DAYS
recip=${1:-"Alex"}
sender=${2:-"Neville"}
days=${3:-5}

echo "== Formal ==";
scripts/filter_followup.sh "$recip" "$sender" "$days" "FORMAL: Following up regarding last week’s discussion. I would appreciate any guidance on appropriate next steps and timing." || true

echo "== Neutral ==";
scripts/filter_followup.sh "$recip" "$sender" "$days" "NEUTRAL: Checking in to keep things moving. Happy to clarify anything or suggest a next step if helpful." || true

echo "== Casual ==";
scripts/filter_followup.sh "$recip" "$sender" "$days" "CASUAL: Just circling back to see how things are landing and whether you want me to line up the next step." || true

echo "== Direct ==";
scripts/filter_followup.sh "$recip" "$sender" "$days" "DIRECT: Confirming status and proposing a short call to lock the next step and timeline." || true
