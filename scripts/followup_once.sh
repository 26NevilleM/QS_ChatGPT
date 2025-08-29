#!/usr/bin/env bash
set -euo pipefail

# followup_once.sh [--copy] [--tone neutral|warm|soft|direct] "<recipient>" "<sender>" <days> "<context>"
copy=0
tone="neutral"

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy) copy=1; shift ;;
    --tone) tone="${2:-neutral}"; shift 2 ;;
    --) shift; break ;;
    *) break ;;
  esac
done

# Positional args
recip="${1:?recipient name}"; shift
sender="${1:?sender name}"; shift
days="${1:?days since last contact (int)}"; shift
ctx="${*:-}"

# Trim trailing spaces/dots from context
while [[ "$ctx" =~ [[:space:]]$ ]]; do ctx="${ctx% }"; done
while [[ "$ctx" =~ \.$ ]]; do ctx="${ctx%.}"; done

# Days grammar
if [[ "$days" == "1" ]]; then
  day_text="1 day"
else
  day_text="${days} days"
fi

# Tone presets
case "$tone" in
  warm)
    lead="Just a friendly follow-up after ${day_text} to keep things moving on ${ctx}."
    helper="If helpful, I can share a brief next step or answer any questions — whatever’s easiest on your side."
    ;;
  soft)
    lead="A gentle check-in after ${day_text} to see what’s easiest for you on ${ctx}."
    helper="Happy to suggest a small, low-lift next step or clarify anything you like."
    ;;
  direct)
    lead="Following up after ${day_text} to align on ${ctx} and lock the next step."
    helper="If it works, I can propose a short call or send a one-pager to confirm scope and date."
    ;;
  *)
    # neutral
    lead="Just a quick note after ${day_text} to keep things moving on ${ctx}."
    helper="If helpful, I can share a brief next step or answer any questions — whatever’s easiest on your side."
    ;;
esac

# Build body without here-docs (avoids paste corruption)
out="$(printf 'Hi %s,\n\n%s\n%s\n\nBest,\n%s\n' "$recip" "$lead" "$helper" "$sender")"

# Print to terminal
printf "%s" "$out"

# Save artifact
mkdir -p tests/.runs
ts="$(date +%Y%m%d-%H%M%S)"
safe_recip="${recip// /_}"
runfile="tests/.runs/${ts}_${safe_recip}.txt"
printf "%s" "$out" > "$runfile"
echo
echo "🗂  Saved: $runfile"

# Optional clipboard copy
if [[ "$copy" -eq 1 || "${FG_COPY:-0}" -eq 1 ]]; then
  if command -v pbcopy >/dev/null 2>&1; then
    printf "%s" "$out" | pbcopy
    echo "📋 Copied to clipboard."
  else
    echo "ℹ️  Clipboard copy requested but pbcopy not found."
  fi
fi
