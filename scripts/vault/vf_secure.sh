#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

ROOT="/Users/neville/Library/CloudStorage/GoogleDrive-design@qsurgical.co.za/My Drive/QS_ChatGPT"
DEST1="$HOME/Desktop/vf_results.txt"
DEST2="$HOME/Desktop/vf_files.txt"

if [ "$#" -lt 1 ]; then
  printf 'usage: %s <pattern>\n' "$(basename "$0")" >&2
  exit 2
fi

# Normalize paste artifacts (remove CRs) and assemble pattern
pattern="$*"
pattern="${pattern//$'\r'/}"

# Basic validation
case "$pattern" in
  -*) printf 'error: pattern must not start with "-"\n' >&2; exit 2;;
esac
# Reject ASCII control chars except tab
if printf '%s' "$pattern" | LC_ALL=C tr -d '\t' | grep -q '[[:cntrl:]]'; then
  printf 'error: pattern contains control characters\n' >&2; exit 2
fi
# Keep it sane
if [ "${#pattern}" -gt 256 ]; then
  printf 'error: pattern too long (>256 chars)\n' >&2; exit 2
fi

cd "$ROOT" || { printf 'error: cannot cd to %s\n' "$ROOT" >&2; exit 2; }
[ -d Vault ] || { printf 'error: Vault/ not found in %s\n' "$ROOT" >&2; exit 2; }

tmp1="$(mktemp "${TMPDIR:-/tmp}/vf_results.XXXXXXXX.txt")"
tmp2="$(mktemp "${TMPDIR:-/tmp}/vf_files.XXXXXXXX.txt")"
cleanup(){ rm -f -- "$tmp1" "$tmp2"; }
trap cleanup EXIT

if command -v rg >/dev/null 2>&1; then
  rg --hidden --no-ignore --no-messages -S --color=never -n -g "Vault/**" -- "$pattern" \
    | head -n 1000 > "$tmp1"
  rg --hidden --no-ignore --no-messages -S --color=never -l -g "Vault/**" -- "$pattern" \
    | head -n 1000 > "$tmp2"
else
  grep -RIn --exclude-dir=".git" -e "$pattern" Vault 2>/dev/null \
    | head -n 1000 > "$tmp1"
  grep -RIl --exclude-dir=".git" -e "$pattern" Vault 2>/dev/null \
    | head -n 1000 > "$tmp2"
fi

if [ ! -s "$tmp1" ] && [ ! -s "$tmp2" ]; then
  printf 'No matches for: %s\n' "$pattern" >&2
  exit 1
fi

mv -f -- "$tmp1" "$DEST1"
mv -f -- "$tmp2" "$DEST2"
trap - EXIT
exit 0
