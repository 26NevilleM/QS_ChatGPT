#!/usr/bin/env bash
set -euo pipefail

# --- OUTFILE_GUARD_TOP ---
# Ensure out_file exists before any write (set -u safe)
if [ -z "${out_file:-}" ]; then
  mkdir -p tests/.runs
  out_file="tests/.runs/$(date +%Y%m%d-%H%M%S)_followup.out"
fi


: "${BEAST_CONTACT_NAME:=Jordan}"
: "${BEAST_SENDER_NAME:=Neville}"
: "${BEAST_LAST_CONTACT_DAYS:=3}"
context="${1:-}"

# call the already-working runner wrapper
scripts/followup_entry.sh "$BEAST_CONTACT_NAME" "$BEAST_SENDER_NAME" "$BEAST_LAST_CONTACT_DAYS" "$context"

# --- STYLE_HOOK_INSTALLED ---
# If BEAST_TONE/BEAST_LENGTH/BEAST_PERSONA are set, render with style helper.
if [ -x "scripts/beast_hooks/_style_wrap.sh" ]; then
  # Recreate the message using the style (summary is in $summary if your hook defines it)
  styled_out="$(scripts/followup_style.sh "${summary:-}" "")"
  printf '%b
' "$styled_out" | perl -00 -pe 's/
{3,}/

/g' | tee "$out_file" >/dev/null
  command -v pbcopy >/dev/null && printf '%b
' "$styled_out" | perl -00 -pe 's/
{3,}/

/g' | pbcopy && echo "📋 Copied to clipboard."
  echo "✅ Updated styled output."
  exit 0
fi

# --- OUTFILE_GUARD_INSTALLED ---
# Ensure out_file always exists before final write (set -u safe)
if [ -z "${out_file:-}" ]; then
  mkdir -p tests/.runs
  out_file="tests/.runs/$(date +%Y%m%d-%H%M%S)_followup.out"
fi
