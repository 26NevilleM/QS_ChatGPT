#!/usr/bin/env bash
set -euo pipefail

# Usage:
# scripts/filter_followup.sh [--style=neutral|formal|casual|direct] [--max-words=N] [--signoff="..."] "Recipient Name" "Sender Name" DAYS "Context text"
#
# Examples:
# scripts/filter_followup.sh --style=formal --max-words=110 --signoff="Kind regards" "Alex Smith" "Neville" 5 "Billing ticket & next steps."

style="neutral"
max_words=""
signoff=""

# Parse flags
while (( $# )); do
  case "$1" in
    --style=*)
      style="${1#*=}"; shift;;
    --max-words=*)
      max_words="${1#*=}"; shift;;
    --signoff=*)
      signoff="${1#*=}"; shift;;
    --) shift; break;;
    -*)
      echo "Unknown flag: $1" >&2; exit 2;;
    *)
      break;;
  esac
done

# Positional args
recip="${1:?recipient}"; shift
sender="${1:?sender}"; shift
days="${1:?last_contact_days int}"; shift
context="${*:-}"

# Helpers
trim_words() {
  # $1 = text, $2 = max count
  awk -v limit="${2:-0}" '
    BEGIN{ count=0 }
    {
      for (i=1;i<=NF;i++){
        if (limit>0 && count>=limit) { exit }
        out = (out ? out " " : "") $i
        count++
      }
    }
    END{ if (out=="") print ""; else print out }
  ' <<<"$1"
}

first_name() {
  # pull first token before space, default to full if single
  name="$1"
  fn="${name%% *}"
  [ -n "$fn" ] && printf "%s" "$fn" || printf "%s" "$name"
}

# Choose tone
greet_name="$(first_name "$recip")"
case "$style" in
  neutral)
    intro="Just a quick note to keep things moving and check in on next steps."
    bridge="If helpful, I can clarify anything or suggest a short path forward."
    ;;
  formal)
    intro="I hope this finds you well. I’m writing to follow up and confirm next steps."
    bridge="If convenient, I can provide a concise summary or address any questions you may have."
    ;;
  casual)
    intro="Just checking in to keep things rolling and see what feels good for next steps."
    bridge="Happy to share a quick summary or jump on a brief call—whatever’s easiest."
    ;;
  direct)
    intro="Following up to align on next steps and keep momentum."
    bridge="If useful, I can send a brief plan or answer any blockers right away."
    ;;
  *)
    echo "Unknown style: $style (use neutral|formal|casual|direct)" >&2
    exit 2
    ;;
esac

# Compose body (plain text)
para1="Hi ${greet_name},

${intro}"
if [ -n "$context" ]; then
  para1="${para1}
From my side: ${context}"
fi

para2="${bridge}
No pressure—I just want to make it easy to proceed whenever you’re ready."

# Signoff
if [ -z "$signoff" ]; then
  case "$style" in
    formal)  signoff="Kind regards";;
    direct)  signoff="Regards";;
    casual)  signoff="Cheers";;
    *)       signoff="Best";;
  esac
fi

body="${para1}

${para2}

${signoff},
${sender}
"

# Optional word cap
if [ -n "${max_words}" ]; then
  # Count words; if above limit, trim and add ellipsis politely
  words_total=$(printf "%s" "$body" | wc -w | awk '{print $1}')
  if [ "$words_total" -gt "$max_words" ]; then
    trimmed="$(trim_words "$body" "$max_words")"
    # Make sure it ends gracefully
    case "$trimmed" in
      *[[:punct:]]) body="$trimmed";;
      *) body="${trimmed}…";;
    esac
  fi
fi

# Output, clipboard, save
printf "%s" "$body"
if command -v pbcopy >/dev/null 2>&1; then
  printf "%s" "$body" | pbcopy
  echo
  echo "📋 Copied to clipboard."
fi

outdir="tests/.runs"
mkdir -p "$outdir"
stamp=$(date +%Y%m%d-%H%M%S)
out="$outdir/${stamp}_filtered_followup.out"
printf "%s" "$body" > "$out"
echo "✅ Saved: $out"
