#!/usr/bin/env bash
set -euo pipefail
: "${OPENAI_API_KEY:?OPENAI_API_KEY not set (keychain loader must be active)}"

mkdir -p tests/.research_runs
query="${*:-Smoke test: research alignment for follow-up. Return only a crisp 2–3 sentence summary.}"
stamp="$(date +%Y%m%d-%H%M%S)"
out="tests/.research_runs/${stamp}_research.txt"

payload="$(jq -n --arg q "$query" '{model:"gpt-4o-mini", messages:[
  {role:"system", content:"You condense notes into a crisp 2–3 sentence summary with no preamble."},
  {role:"user",   content:$q}
]}')"

resp="$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$payload")"

summary="$(jq -r '.choices[0].message.content // empty' <<<"$resp")"
if [ -z "$summary" ]; then
  echo "❌ OpenAI response had no summary:" >&2
  echo "$resp" >&2
  exit 1
fi

printf "%s\n" "$summary" > "$out"
echo "📝 Wrote research summary: $out" >&2
echo "$out"
