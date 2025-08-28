#!/usr/bin/env bash
set -euo pipefail

in="${1:?path to input file}"
out="${2:-}"   # optional output; if empty we overwrite input (after making a .bak)

tmp="$(mktemp -t prompt_clean_XXXX).md"

# Remove empty "Context:" bullets, test markers, trim trailing spaces, collapse blank lines
awk 'BEGIN{IGNORECASE=1}
  /^[[:space:]]*[-*][[:space:]]*Context:[[:space:]]*$/ { next }     # "- Context:" only
  /# TEST/ { next }                                                 # any "# TEST..." line
  /<!--[[:space:]]*test/ { next }                                   # "<!-- test ... -->"
  { print }
' "$in" \
| sed -E 's/[[:space:]]+$//' \
| awk '{
    blank = ($0 ~ /^[[:space:]]*$/);
    if (blank) { if (prevblank) next; prevblank=1; }
    else { prevblank=0; }
    print
  }' > "$tmp"

if [[ -n "${out}" ]]; then
  mv -f "$tmp" "$out"
  echo "✅ Wrote cleaned output to: $out"
else
  cp -p "$in" "$in.bak"
  mv -f "$tmp" "$in"
  echo "✅ Cleaned in-place: $in"
  echo "   Backup: $in.bak"
fi
