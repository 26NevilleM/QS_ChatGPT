#!/usr/bin/env bash
set -euo pipefail
# usage: scripts/run_followup.sh /path/to/case.json
# case.json keys: recipient, sender, last_contact_days (int), context (string)

json="${1:?Usage: scripts/run_followup.sh CASE.json}"

# --- read case fields via jq (fail fast if missing) ---
recipient="$(jq -r '.recipient' "$json")"
sender="$(jq -r '.sender' "$json")"
days="$(jq -r '.last_contact_days' "$json")"
context="$(jq -r '.context' "$json")"

# --- choose the prompt file (override with PROMPT_PATH=...) ---
ROOT="$(pwd)"
DEFAULT_PROMPT="$ROOT/Vault/Prompt_Library/active/followup_generator/prompt.md"
PROMPT_PATH="${PROMPT_PATH:-$DEFAULT_PROMPT}"

# --- tiny helper to escape for sed replacement ---
esc() {
  # escape \ / & for sed
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\//\\/}"
  s="${s//&/\\&}"
  printf '%s' "$s"
}

# --- load template or fallback ---
if [[ -f "$PROMPT_PATH" ]]; then
  template="$(cat "$PROMPT_PATH")"
else
  # very small fallback if the real prompt is unavailable
  read -r -d '' template <<'TPL' || true
Hi {{recipient}},

It’s been about {{last_contact_days}} day(s) since our last touchpoint.
{{context}}

If it helps, I can share next steps or a quick summary.

Best,
{{sender}}
TPL
fi

# --- perform placeholder replacements ---
r="$(esc "$recipient")"
s="$(esc "$sender")"
d="$(esc "$days")"
c="$(esc "$context")"

# Replace well-known tokens; leave unknown tokens untouched
rendered="$(printf '%s' "$template" \
  | sed -e "s/{{recipient}}/${r}/g" \
        -e "s/{{sender}}/${s}/g" \
        -e "s/{{last_contact_days}}/${d}/g" \
        -e "s/{{context}}/${c}/g")"

# --- print to STDOUT (so callers can tee/pbcopy) ---
printf '%s\n' "$rendered"
