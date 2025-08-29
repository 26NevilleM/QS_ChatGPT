#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/followup_cli.sh /path/to/case.json [optional:/path/to/prompt.md]
case_json="${1:?give case.json}"; shift || true
prompt_path="${1:-}"

# Dependencies
command -v jq >/dev/null || { echo "❌ jq not installed"; exit 1; }

# Default prompt location (active)
DEFAULT_PROMPT="Vault/Prompt_Library/active/followup_generator/prompt.md"

# Resolve prompt path
if [[ -z "${prompt_path}" ]]; then
  prompt_path="$DEFAULT_PROMPT"
fi

# Validate prompt path to avoid bare `cat`
if [[ ! -f "$prompt_path" ]]; then
  echo "❌ prompt file not found: $prompt_path"
  echo "   (Set a custom path as 2nd arg if needed)"
  exit 1
fi

# Read case fields
recipient=$(jq -r '.recipient // empty' "$case_json"); : "${recipient:?missing recipient}"
sender=$(jq -r '.sender // empty' "$case_json"); : "${sender:?missing sender}"
days=$(jq -r '.last_contact_days // empty' "$case_json"); : "${days:?missing last_contact_days}"
context=$(jq -r '.context // empty' "$case_json"); : "${context:?missing context}"

# Read template safely (no naked cat)
template_content="$(<"$prompt_path")"

# Escape for sed replacement
esc() {
  # escape &, / and \ for sed replacement
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g' -e 's/\\/\\\\/g'
}

# Perform token replacements
out="$template_content"
out="${out//\{\{recipient\}\}/$(esc "$recipient")}"
out="${out//\{\{sender\}\}/$(esc "$sender")}"
out="${out//\{\{last_contact_days\}\}/$(esc "$days")}"
out="${out//\{\{context\}\}/$(esc "$context")}"

# Output + persist
mkdir -p tests/.runs
stamp="$(date +%Y%m%d-%H%M%S)"
outfile="tests/.runs/${stamp}_followup.out"

printf '%s\n' "$out" | tee "$outfile" >/dev/null
command -v pbcopy >/dev/null && printf '%s' "$out" | pbcopy && # echo "📋 Copied to clipboard." (style hook handles this)

# echo "✅ Wrote…" (style hook handles this)
