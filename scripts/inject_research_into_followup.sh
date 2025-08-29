#!/usr/bin/env bash
set -euo pipefail
R="${1:?research.txt}"
F="${2:?followup.out}"

# Take first 1–2 lines of research, trim to ~160 chars
snippet="$(sed -n '1,2p' "$R" | tr -d '\r' | tr '\n' ' ' | awk '{print substr($0,1,160)}')"
snippet="${snippet% }"

# Insert "From my side: ..." on the line after the greeting block (after the first blank line)
tmp="$(mktemp)"
awk -v s="$snippet" '
  BEGIN{printed=0}
  {
    print $0
    if (!printed && $0 ~ /^$/) {
      print "From my side: " s
      printed=1
    }
  }
' "$F" > "$tmp"
mv "$tmp" "$F"
echo "✅ Injected research snippet into: $F"
