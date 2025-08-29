#!/usr/bin/env bash
set -euo pipefail

log(){ printf "%s %s\n" "$(date '+%H:%M:%S')" "$*"; }
die(){ printf "ERROR: %s\n" "$*" >&2; exit 1; }

SRC="ENV"
if [ -z "${OPENAI_API_KEY:-}" ]; then
  OPENAI_API_KEY="$(security find-generic-password -a "$USER" -s OPENAI_API_KEY -w 2>/dev/null || true)"
  SRC="Keychain"
fi
[ -n "${OPENAI_API_KEY:-}" ] || die "OPENAI_API_KEY not found in ENV or Keychain."
log "🔑 Using OPENAI_API_KEY from: $SRC (prefix: ${OPENAI_API_KEY:0:8}…)"

command -v curl >/dev/null || die "curl missing"
command -v jq   >/dev/null || die "jq missing (brew install jq)"

log "🌐 Hitting OpenAI /models…"
models_json="$(curl -sS https://api.openai.com/v1/models -H "Authorization: Bearer $OPENAI_API_KEY")" || die "Failed to reach API"
err="$(echo "$models_json" | jq -r '.error.message // empty')"
[ -z "$err" ] || die "API /models error: $err"
echo "$models_json" | jq -e '.object=="list"' >/dev/null || die "Unexpected /models response"
top_models=$(echo "$models_json" | jq -r '.data[0:8][]?.id' | paste -sd ", " -)

PREF="gpt-4"
HAS_PREF=$(echo "$models_json" | jq -r --arg m "$PREF" '[.data[]?.id==$m] | any')
MODEL="$([ "$HAS_PREF" = "true" ] && echo "$PREF" || echo "gpt-4")"

log "💬 Tiny chat ping with model: $MODEL"
payload="$(jq -n --arg p "Quick preflight ping from Neville's Beast. Reply: OK." --arg m "$MODEL" '{model:$m, messages:[{role:"user",content:$p}] }')"
resp="$(curl -sS https://api.openai.com/v1/chat/completions -H "Authorization: Bearer '"$OPENAI_API_KEY"'" -H "Content-Type: application/json" -d "$payload")" || die "Chat call failed"

err="$(echo "$resp" | jq -r '.error.message // empty')"
[ -z "$err" ] || die "Chat API error: $err"

text="$(echo "$resp" | jq -r '.choices[0].message.content // empty')"
[ -n "$text" ] || die "No content returned (unexpected response)."

log "✅ Models reachable. Top: ${top_models:-(none)}"
log "✅ Chat OK → $(echo "$text" | tr -d '\n' | cut -c1-120)"

stamp="$(date +%Y%m%d-%H%M%S)"
out="tests/.runs/${stamp}_doctor.txt"
{
  echo "=== Beast Doctor ==="
  echo "Time: $(date -Iseconds)"
  echo "Model: $MODEL"
  echo "Top: $top_models"
  echo "Chat snippet: $text"
} > "$out"
log "🗂  Wrote: $out"
log "🟢 Preflight passed."
