#!/usr/bin/env bash
set -euo pipefail
casefile="${1:?Provide a case JSON file, e.g. tests/cases/followup_demo.json}"

# read fields from JSON
recipient=$(jq -r '.recipient // "Friend"' "$casefile")
sender=$(jq -r '.sender // "Neville"' "$casefile")
days=$(jq -r '.last_contact_days // 7' "$casefile")
context=$(jq -r '.context // ""' "$casefile")

# Compose a simple follow-up using the fields.
# (Later we can switch this to render from your prompt.md if you want template fidelity.)
printf "%s\n" \
"Hi ${recipient}," \
"" \
"Hope you're well! I'm circling back after ${days} day(s) on the thread we discussed." \
"${context:+}" \
"${context:+Context: ${context}}" \
"" \
"If it's helpful, I can propose next steps or schedule a quick call." \
"" \
"Best," \
"${sender}"
