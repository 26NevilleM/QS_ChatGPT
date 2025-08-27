#!/bin/bash
set -euo pipefail
root="$HOME/Library/CloudStorage/GoogleDrive-design@qsurgical.co.za/My Drive/QS_ChatGPT"
lib="$root/Vault/Prompt_Library"
catalog="$root/Vault/Prompt_Catalog.json"

tmp="$(mktemp)"
echo "[" > "$tmp"
first=1

while IFS= read -r -d '' p; do
  # Expect paths like .../active/<slug>/prompt.md
  slug="$(basename "$(dirname "$p")")"
  bucket="$(basename "$(dirname "$(dirname "$p")")")" # active or sandbox
  [ "$bucket" != "active" ] && continue

  size=$(wc -c < "$p" | tr -d ' ')
  sha=$(shasum -a 256 "$p" | awk '{print $1}')
  rel="${p#"$root/"}"

  if [ $first -eq 0 ]; then echo "," >> "$tmp"; fi
  first=0
  cat >> "$tmp" <<JSON
{"slug":"$slug","path":"$rel","bucket":"$bucket","size":$size,"sha256":"$sha"}
JSON
done < <(find "$lib/active" -type f -name 'prompt.md' -print0)

echo "]" >> "$tmp"
mv "$tmp" "$catalog"

echo "🗂  Wrote catalog: $catalog"
