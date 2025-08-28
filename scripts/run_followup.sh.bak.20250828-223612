#!/usr/bin/env bash
set -euo pipefail

# usage: scripts/run_followup.sh [--style=neutral|formal|casual|direct] case.json
style="neutral"
if [[ "${1:-}" == --style=* ]]; then
  style="${1#--style=}"
  shift
fi

case_json="${1:?path to case.json}"
[ -f "$case_json" ] || { echo "❌ case not found: $case_json"; exit 1; }

# Extract fields
recipient=$(jq -r ".recipient" "$case_json")
sender=$(jq -r ".sender" "$case_json")
days=$(jq -r ".last_contact_days" "$case_json")
context=$(jq -r ".context" "$case_json")

trimmed_context="${context//[$'\r\n""] / }"
has_ctx=0; [[ -n "$trimmed_context" && "$trimmed_context" != "null" && "$trimmed_context" != " " ]] && has_ctx=1

mk_msg_neutral(){
  printf "Hi %s,\\n\\n" "$recipient"
  if [[ "$days" =~ ^[0-9]+$ && "$days" -gt 0 ]]; then
    printf "It’'s been about %s day%s since we were last in touch, so I wanted to check in." "$days" "$([[ $days -eq 1 ]] && echo "" || echo "s")"
  else
    printf "Just a quick check-in to keep things moving."
  fi
  if [[ $has_ctx -eq 1 ]]; then printf " From my side: %s." "$trimmed_context"; fi
  printf "\\n\\nIf helpful, I can suggest a next step or answer any questions — whatever’s easiest on your side.\\n\\nBest,\\n%s\\n" "$sender"
}

mk_msg_formal(){
  printf "Dear %s,\\n\\n" "$recipient"
  if [[ "$days" =~ ^[0-9]+$ && "$days" -gt 0 ]]; then
    printf "I hope you are well. Following up after approximately %s day%s since our last correspondence." "$days" "$([[ $days -eq 1 ]] && echo "" || echo "s")"
  else
    printf "I hope you are well. I am writing to follow up briefly."
  fi
  if [[ $has_ctx -eq 1 ]]; then printf " Regarding: %s." "$trimmed_context"; fi
  printf "\\n\\nPlease let me know if you would like any further detail or if a brief call would be useful.\\n\\nKind regards,\\n%s\\n" "$sender"
}

mk_msg_casual(){
  printf "Hey %s,\\n\\n" "$recipient"
  if [[ "$days" =~ ^[0-9]+$ && "$days" -gt 0 ]]; then
    printf "Quick nudge — it’'s been ~%s day%s." "$days" "$([[ $days -eq 1 ]] && echo "" || echo "s")"
  else
    printf "Quick nudge while it’'s fresh."
  fi
  if [[ $has_ctx -eq 1 ]]; then printf " Re: %s." "$trimmed_context"; fi
  printf "\\n\\nHappy to send a next step or keep it light — whatever works.\\n\\nCheers,\\n%s\\n" "$sender"
}

mk_msg_direct(){
  printf "%s —\\n\\n" "$recipient"
  if [[ $has_ctx -eq 1 ]]; then
    printf "%s\\n\\n" "$trimmed_context"
  else
    printf "Following up to move this forward.\\n\\n"
  fi
  printf "Available to proceed or answer questions.\\n\\n— %s\\n" "$sender"
}

case "$style" in
  neutral|"") mk_msg_neutral ;;
  formal)       mk_msg_formal  ;;
  casual)       mk_msg_casual  ;;
  direct)       mk_msg_direct  ;;
  *)            mk_msg_neutral ;;
esac
