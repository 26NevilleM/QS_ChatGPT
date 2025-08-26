#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"
ts="$(date +%Y%m%d-%H%M%S)"
name="${1:-QS_Vault_PACK_$ts}"
out="Vault/Packs/Exports/${name}.zip"
mkdir -p "Vault/Packs/Exports"
zip -rq "$out" Vault/Prompt_Library Vault/Config Vault/Modules Vault/Workflows Vault/templates Vault/tools || true
echo "$out"
