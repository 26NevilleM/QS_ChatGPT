#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ts="$(date -u +%Y%m%d_%H%M%S)"
out="$root/backups"
mkdir -p "$out"
zip -qr "$out/vault_$ts.zip" "Vault"
echo "$out/vault_$ts.zip"
