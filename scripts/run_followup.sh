#!/usr/bin/env bash
set -euo pipefail

casefile="${1:?usage: scripts/run_followup.sh path/to/case.json}"

ACTIVE="Vault/Prompt_Library/active/followup_generator/prompt.md"

# 1) Guard the active prompt
scripts/guard_prompt.sh "$ACTIVE" >/dev/null

# 2) Read inputs
recipient=$(jq -r '.recipient' "$casefile")
sender=$(jq -r '.sender' "$casefile")
days=$(jq -r '.last_contact_days' "$casefile")
context=$(jq -r '.context' "$casefile")

# 3) Compose a simple, deterministic message (no LLM; just logic)
# You can swap this section later to call your real model.
subject="Quick follow-up — next step?"
cta="Does this week still work to move this forward?"
tone="warm"

# A very short body shaped from inputs
body="$recipient,

Just circling back — it’s been about $days day(s) since we last spoke. $context

If it helps, I can propose the next step and line up the pieces. $cta

Best,
$sender"

# 4) Emit JSON exactly as your contract expects
jq -n --arg subject "$subject" \
      --arg body "$body" \
      --arg tone "$tone" \
      --arg cta "$cta" \
      --argjson days "$days" \
'{
  subject: $subject,
  body: $body,
  meta: {
    tone: $tone,
    call_to_action: $cta,
    last_contact_days: $days
  }
}'
