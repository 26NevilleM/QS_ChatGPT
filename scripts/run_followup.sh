#!/usr/bin/env bash
set -euo pipefail

casefile="${1:?Usage: scripts/run_followup.sh path/to/case.json}"

# Paths
prompt_file="Vault/Prompt_Library/active/followup_generator/prompt.md"

# --- guardrails ---
if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq not found. Install with: brew install jq" >&2
  exit 1
fi
[ -f "$casefile" ] || { echo "❌ case JSON not found: $casefile" >&2; exit 1; }
[ -f "$prompt_file" ] || { echo "❌ prompt not found: $prompt_file" >&2; exit 1; }

# --- extract fields ---
recipient=$(jq -r '.recipient // "Friend"' "$casefile")
sender=$(jq -r '.sender // "Neville"' "$casefile")
days=$(jq -r '.last_contact_days // 7' "$casefile")
context=$(jq -r '.context // ""' "$casefile")

# --- render template (token substitution) ---
awk \
  -v RECIP="$recipient" \
  -v SENDER="$sender" \
  -v DAYS="$days" \
  -v CONTEXT="$context" '
{
  line = $0
  gsub(/\{\{recipient\}\}/, RECIP, line)
  gsub(/\{\{sender\}\}/, SENDER, line)
  gsub(/\{\{last_contact_days\}\}/, DAYS, line)
  gsub(/\{\{context\}\}/, CONTEXT, line)
  print line
}
' "$prompt_file" \
# --- cleanup block ---
# TEMP: disabled cleanup -> # TEMP: disabled stray pipe -> | awk -v CONTEXT="$context" '
# TEMP: disabled cleanup ->   # pass 1: trim trailing spaces
# TEMP: disabled cleanup ->   { sub(/[[:space:]]+$/, "", $0); lines[NR]=$0 }
# TEMP: disabled cleanup ->   END {
# TEMP: disabled cleanup ->     # pass 2: if context is empty, drop any line that reduces to a naked label
# TEMP: disabled cleanup ->     # e.g., "Context:", "Notes:", "Background:" (case-insensitive, optional colon)
# TEMP: disabled cleanup ->     for (i=1;i<=NR;i++) {
# TEMP: disabled cleanup ->       L = lines[i]
# TEMP: disabled cleanup ->       if (CONTEXT == "") {
# TEMP: disabled cleanup ->         # normalize spaces
# TEMP: disabled cleanup ->         gsub(/^[[:space:]]+|[[:space:]]+$/, "", L)
# TEMP: disabled cleanup ->         # match label-only lines
# TEMP: disabled cleanup ->         if (L ~ /^(?i:context|notes|background)\s*:?\s*$/) continue
# TEMP: disabled cleanup ->       }
# TEMP: disabled cleanup ->       print lines[i]
# TEMP: disabled cleanup ->     }
# TEMP: disabled cleanup ->   }
# TEMP: disabled cleanup -> ' \
# TEMP: disabled cleanup -> # TEMP: disabled stray pipe -> | awk '
# TEMP: disabled cleanup ->   # collapse any 3+ blank lines to at most 2
# TEMP: disabled cleanup ->   { buf = (NR==1 ? $0 : buf ORS $0) }
# TEMP: disabled cleanup ->   END { gsub(/\n{3,}/, "\n\n", buf); print buf }
# TEMP: disabled cleanup -> '
