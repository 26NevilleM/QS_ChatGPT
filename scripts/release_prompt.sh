#!/bin/bash
set -euo pipefail
slug="${1:-followup_generator}"

# Run the full test suite
scripts/all_tests.sh "$slug"

# Date utility (macOS-friendly)
if command -v gdate >/dev/null 2>&1; then
  NOW="$(gdate -u +%Y%m%d-%H%M%S)"
else
  NOW="$(date -u +%Y%m%d-%H%M%S)"
fi

root="$HOME/Library/CloudStorage/GoogleDrive-design@qsurgical.co.za/My Drive/QS_ChatGPT"
zip_path="$root/Vault/Packs/Exports/QS_Vault_${NOW}.zip"

# Create export zip (Vault only to keep it clean)
(
  cd "$root"
  zip -qry "$zip_path" "Vault"
)
echo "📦 Exported: $zip_path"

# Optional git tag if in a repo
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  tag="prompt/${slug}/${NOW}"
  git add -A
  git commit -m "release(${slug}): ${NOW}" || true
  git tag -a "$tag" -m "Release ${slug} @ ${NOW}"
  echo "🏷  Created git tag: $tag"
fi

echo "🎉 Release complete for $slug"
