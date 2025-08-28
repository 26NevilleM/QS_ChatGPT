#!/usr/bin/env bash
set -euo pipefail

# usage: scripts/run_followup.sh /path/to/case.json
casefile="${1:?JSON case file missing}"

# deps
command -v jq >/dev/null || { echo "jq is required"; exit 1; }

# read inputs
recipient=$(jq -r '.recipient' "$casefile")
sender=$(jq -r '.sender' "$casefile")
days=$(jq -r '.last_contact_days' "$casefile")
context=$(jq -r '.context' "$casefile")

# template path (active prompt)
tmpl="Vault/Prompt_Library/active/followup_generator/prompt.md"
[ -f "$tmpl" ] || { echo "Template not found: $tmpl" >&2; exit 1; }

# substitute tokens and print to STDOUT
awk -v r="$recipient" -v s="$sender" -v d="$days" -v c="$context" '
{
  line=$0
  gsub(/\{\{recipient\}\}/, r, line)
  gsub(/\{\{sender\}\}/, s, line)
  gsub(/\{\{last_contact_days\}\}/, d, line)
  gsub(/\{\{context\}\}/, c, line)
  print line
}
' "$tmpl"
