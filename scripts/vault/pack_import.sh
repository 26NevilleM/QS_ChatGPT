#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"
pkg="${1:?path_to_pack_zip_required}"
dest="Vault/restore_here_$(date +%Y%m%d-%H%M%S)"
mkdir -p "$dest"
unzip -q "$pkg" -d "$dest"
echo "$dest"
