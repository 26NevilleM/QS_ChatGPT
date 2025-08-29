#!/usr/bin/env bash
set -euo pipefail

# usage: scripts/followup_cli.sh /path/to/case.json
casefile="${1:?usage: followup_cli.sh CASE.json}"

# --- deps ---
command -v jq >/dev/null || { echo "❌ jq missing"; exit 1; }

# --- read case ---
recipient=$(jq -r '.recipient' "$casefile")
sender=$(jq -r '.sender' "$casefile")
days=$(jq -r '.last_contact_days' "$casefile")
context=$(jq -r '.context' "$casefile")

# --- compose message (plain; style hook can prettify later) ---
msg=$(cat <<TXT
Hi ${recipient},

It’s been ${days} day(s) since we last connected. ${context}

If helpful, I can share a brief next step or answer any questions — whatever’s easiest on your side. No rush.

Best,
${sender}
TXT
)

# --- write + copy ---
mkdir -p tests/.runs
stamp="$(date +%Y%m%d-%H%M%S)"
safe_recipient="${recipient// /_}"
outfile="tests/.runs/${stamp}_${safe_recipient}_followup_${RANDOM}.out"

# Keep these echos (your style hook can also add its own log line)
printf "%s" "$msg" | tee "$outfile" >/dev/null
command -v pbcopy >/dev/null && printf "%s" "$msg" | pbcopy && echo "📋 Copied to clipboard."
echo "✅ Wrote: $outfile"
