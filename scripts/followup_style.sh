#!/usr/bin/env bash
set -euo pipefail

# Inputs via env with sane defaults:
TONE="${BEAST_TONE:-neutral}"          # neutral|warm|direct|friendly|polite|assertive
LENGTH="${BEAST_LENGTH:-normal}"       # short|normal|long
PERSONA="${BEAST_PERSONA:-Operator}"   # free text label
RECIP="${BEAST_CONTACT_NAME:-There}"   # fallback if not set by caller
SENDER="${BEAST_SENDER_NAME:-Neville}"
DAYS="${BEAST_LAST_CONTACT_DAYS:-3}"
SUMMARY="${1:-}"                       # first arg = research summary (optional)
EXTRA="${2:-}"                         # second arg = extra context (optional)

# --- Openers by tone ---
case "$TONE" in
  warm)     OPENER="Hi $RECIP," ;;
  friendly) OPENER="Hey $RECIP," ;;
  direct)   OPENER="Hello $RECIP," ;;
  assertive)OPENER="Hi $RECIP," ;;
  polite)   OPENER="Dear $RECIP," ;;
  *)        OPENER="Hi $RECIP," ;;
esac

# --- Middle (length controls) ---
BASE_1="It’s been $DAYS day(s) since we last connected."
BASE_2="${SUMMARY:-Just a quick ping to keep things moving.}"

case "$LENGTH" in
  short)
    BODY="$BASE_1 ${SUMMARY:+${SUMMARY} }If useful, I can send the next step.\n"
    ;;
  long)
    BODY="$BASE_1 ${SUMMARY}\n\nIf helpful, I can propose a brief plan, share options, or answer open questions—whatever’s easiest on your side. Happy to align timelines as well.\n"
    ;;
  *)
    BODY="$BASE_1 ${BASE_2}\n\nIf helpful, I can share a brief next step or answer any questions — whatever’s easiest on your side.\n"
    ;;
esac

# --- Persona tag (subtle) ---
case "$PERSONA" in
  ""|"neutral"|"Operator") P_TAG="" ;;
  *)                       P_TAG="\n\n(Perspective: ${PERSONA})" ;;
esac

# --- Sign-off by tone ---
case "$TONE" in
  direct|assertive) SIGN="Regards," ;;
  polite)           SIGN="Kind regards," ;;
  warm|friendly)    SIGN="Best," ;;
  *)                SIGN="Best," ;;
esac

# Optional extra line if the caller passes anything
EXTRA_LINE=""
[ -n "$EXTRA" ] && EXTRA_LINE="\n${EXTRA}\n"

# Output
printf "%s\n\n%s\n%s%s\n\n%s\n%s\n" \
  "$OPENER" \
  "$BODY" \
  "$EXTRA_LINE" \
  "" \
  "$SIGN" \
  "$SENDER"
