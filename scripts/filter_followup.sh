#!/usr/bin/env bash
set -euo pipefail

style="neutral"
signoff="Best,\nNeville"
max_words=0

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --style=*) style="${1#*=}" ;;
    --signoff=*) signoff="${1#*=}" ;;
    --max-words=*) max_words="${1#*=}" ;;
    --) shift; break ;;
    *) break ;;
  esac
  shift
done

recip="${1:?recipient}"; shift
sender="${1:?sender}"; shift
days="${1:?days}"; shift
context="${*:-}"

# Guard check
scripts/guard_prompt.sh "Vault/Prompt_Library/active/followup_generator/prompt.md" \
  || { echo "❌ Guard failed"; exit 1; }

# Build case JSON
tmpcase="$(mktemp -t fg_case_XXXX).json"
printf '{"context":%s,"recipient":%s,"sender":%s,"last_contact_days":%s,"style":%s}\n' \
  "$(jq -Rs . <<<"$context")" \
  "$(jq -Rs . <<<"$recip")" \
  "$(jq -Rs . <<<"$sender")" \
  "$days" \
  "$(jq -Rs . <<<"$style")" > "$tmpcase"

stdout="$(mktemp -t fg_stdout_XXXX).txt"
stderr="$(mktemp -t fg_stderr_XXXX).txt"

if ! scripts/run_followup.sh "$tmpcase" >"$stdout" 2>"$stderr"; then
  echo "⌖ run_followup.sh failed. See $stderr"
  sed -n "1,200p" "$stderr" || true
  exit 1
fi

body="$(cat "$stdout")"

# Trim if max_words set
if (( max_words > 0 )); then
  body="$(printf "%s" "$body" | awk -v m=$max_words '{
    n=split($0,a," ");
    for(i=1;i<=n && i<=m;i++) printf a[i]" ";
    if(n>m) printf "...";
    printf "\n";
  }')"
fi

# Append signoff
body="${body}\n\n${signoff}"

printf "%b\n" "$body"
command -v pbcopy >/dev/null && printf "%b" "$body" | pbcopy && echo "📋 Copied to clipboard."

outdir="tests/.runs"; mkdir -p "$outdir"
stamp=$(date +%Y%m%d-%H%M%S)
who=$(printf "%s" "$recip" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-_')
out="$outdir/${stamp}_${who}_${style}_filtered_followup.out"
printf "%b\n" "$body" > "$out"
echo "✅ Saved: $out"
