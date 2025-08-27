#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

usage() { echo "Usage: $(basename "$0") <slug> [--dry-run]"; }

slug="${1:-}"; shift || true
[[ -z "${slug}" || "${slug}" == -* ]] && { usage; exit 2; }

dry_run=false
if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run=true
  shift || true
fi

BASE="/Users/neville/Library/CloudStorage/GoogleDrive-design@qsurgical.co.za/My Drive/QS_ChatGPT/Vault/Prompt_Library"
A="$BASE/active/$slug/prompt.md"
S="$BASE/sandbox/$slug/prompt.md"

# sanity
[[ -f "$S" ]] || { echo "❌ Sandbox file not found: $S"; exit 1; }
[[ -f "$A" ]] || { echo "❌ Active file not found:  $A"; exit 1; }

ha="$(shasum -a 256 "$A" | awk '{print $1}')"
hs="$(shasum -a 256 "$S" | awk '{print $1}')"

if [[ "$ha" == "$hs" ]]; then
  echo "✅ No changes: '$slug' active == sandbox. Nothing to promote."
  exit 0
fi

ts="$(date +"%Y%m%d-%H%M%S")"
bak_dir="$(dirname "$A")"
bak="${bak_dir}/prompt.md.${ts}.bak"

echo "➡️  Will back up active → $bak"
echo "➡️  Will copy sandbox → active"

if $dry_run; then
  echo "🧪 Dry run only — no changes made."
  exit 0
fi

# do it
cp -p "$A" "$bak"
cp -p "$S" "$A"

# verify
ha2="$(shasum -a 256 "$A" | awk '{print $1}')"
hs2="$(shasum -a 256 "$S" | awk '{print $1}')"
if [[ "$ha2" == "$hs2" ]]; then
  echo "✅ Promoted '$slug' successfully."
  echo "   Backup: $bak"
  echo "   SHA256: $ha2"
else
  echo "⚠️  Verification failed — restoring backup."
  cp -p "$bak" "$A"
  exit 2
fi
