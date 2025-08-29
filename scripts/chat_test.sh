#!/usr/bin/env bash
set -euo pipefail
: "${OPENAI_API_KEY:?OPENAI_API_KEY not set}"

prompt="${*:-Say hello from the Beast.}"
curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg p "$prompt" '
    {
      model: "gpt-4",
      messages: [ {role:"user", content:$p} ]
    }'
  )" \
| jq -r '.choices[0].message.content // "⚠️ No content returned"'
