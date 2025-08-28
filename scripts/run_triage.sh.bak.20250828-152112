#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/run_triage.sh path/to/case.json

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq not found. Install with: brew install jq" >&2
  exit 127
fi

case_json="${1:-}"
if [[ -z "${case_json}" || ! -f "${case_json}" ]]; then
  echo "❌ Provide a case JSON file. Example:" >&2
  echo "   scripts/run_triage.sh tests/cases/triage_demo.json" >&2
  exit 2
fi

prompt="Vault/Prompt_Library/active/triage_intake/prompt.md"
if [[ ! -f "$prompt" ]]; then
  echo "❌ Prompt not found at: $prompt" >&2
  exit 3
fi

required=( '{{source}}' '{{submitted_at}}' '{{contact}}' '{{summary}}' '{{details}}' )
for t in "${required[@]}"; do
  if ! grep -qF -- "$t" "$prompt"; then
    echo "❌ Prompt missing placeholder: $t" >&2
    exit 4
  fi
done

source_v=$(jq -r '.source // ""'        "$case_json")
ts_v=$(jq -r '.submitted_at // ""'      "$case_json")
contact_v=$(jq -r '.contact // ""'      "$case_json")
summary_v=$(jq -r '.summary // ""'      "$case_json")
details_v=$(jq -r '.details // ""'      "$case_json")

urg="low"
if printf '%s\n%s\n' "$summary_v" "$details_v" | grep -qiE '\burgent|asap|critical|immediately|downtime|outage|escalat'; then
  urg="high"
fi

category="general"
if printf '%s\n' "$summary_v" | grep -qiE '\b(invoice|billing|payment|refund)\b'; then category="billing"; fi
if printf '%s\n' "$summary_v" | grep -qiE '\bbug|error|crash|exception|stack\b'; then category="bug"; fi
if printf '%s\n' "$summary_v" | grep -qiE '\bfeature|request|idea|improvement\b'; then category="feature_request"; fi

next_steps_json=$(jq -n --arg cat "$category" --arg urg "$urg" '
  [
    { "step": "Acknowledge receipt", "owner": "ops", "due": "today" },
    { "step": (if $cat == "bug" then "Collect logs & repro steps" else "Clarify requirements" end),
      "owner": "ops", "due": "tomorrow" },
    { "step": (if $urg == "high" then "Escalate to on-call" else "Schedule review" end),
      "owner": "ops", "due": "next_business_day" }
  ]')

result_json=$(jq -n \
  --arg who "$contact_v" \
  --arg what "$summary_v" \
  --arg when "$ts_v" \
  --arg src "$source_v" \
  --arg det "$details_v" \
  --arg urg "$urg" \
  --arg cat "$category" \
  --argjson steps "$next_steps_json" \
  '{
     source: $src,
     submitted_at: $when,
     contact: $who,
     summary: $what,
     details: $det,
     urgency: $urg,
     category: $cat,
     next_steps: $steps
   }')

mkdir -p tests/.runs
stamp="$(date +%Y%m%d-%H%M%S)"
out_file="tests/.runs/${stamp}_triage.out"
printf '%s\n' "$result_json" > "$out_file"

cat "$out_file"
command -v pbcopy >/dev/null 2>&1 && { pbcopy < "$out_file"; echo "📋 Copied to clipboard: $out_file" >&2; }
exit 0
