#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
out="$root/Vault/INDEX.json"

sha() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'; return; fi
  if command -v openssl >/dev/null 2>&1; then openssl dgst -sha256 "$1" | awk '{print $2}'; return; fi
  echo NA
}

size_of() {
  stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null || echo 0
}

tmp="$(mktemp)"
printf '[' > "$tmp"
first=1

git -C "$root" ls-files -z -- 'Vault/*' | while IFS= read -r -d '' f; do
  base="${f##*/}"
  [ "$base" = "INDEX.json" ] && continue
  p="$root/$f"
  [ -f "$p" ] || continue
  s="$(size_of "$p")"
  h="$(sha "$p")"
  if [ $first -eq 1 ]; then first=0; else printf ',' >> "$tmp"; fi
  printf '\n{"path":"%s","size":%s,"sha256":"%s"}' "$f" "$s" "$h" >> "$tmp"
done

printf '\n]\n' >> "$tmp"
mv "$tmp" "$out"
echo "INDEX_OK $out"
