#!/usr/bin/env bash
set -euo pipefail
: "${OPENAI_API_KEY:?Set OPENAI_API_KEY}"

# Read full prompt from STDIN
prompt="$(cat)"

# Ask the model to return strict JSON if your schema expects JSON,
# otherwise plain text is fine. We nudge it toward JSON either way.
payload=$(jq -n --arg p "$prompt" '{
  model: "gpt-4o-mini",
  temperature: 0.2,
  messages: [
    {role:"system","content":"You are a careful research assistant. If a schema is shown, respond with valid JSON only. Otherwise be concise."},
    {role:"user","content": $p}
  ]
}')

curl -sS https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer '"$OPENAI_API_KEY"'" \
  -H "Content-Type: application/json" \
  -d "$payload" \
| jq -r '.choices[0].message.content'
