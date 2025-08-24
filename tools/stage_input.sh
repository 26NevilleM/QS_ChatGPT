#!/bin/zsh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INPUT_DIR="$REPO_ROOT/Input"
STAGE_DIR="$REPO_ROOT/Tools/_scratch/staged_$(date -u +%Y%m%d-%H%M%SZ)"
LOG="$STAGE_DIR/stage.log"
INV="$STAGE_DIR/sha256_inventory.txt"

mkdir -p "$STAGE_DIR"
echo "==> Staging from: $INPUT_DIR" | tee -a "$LOG"

# 1) Copy all new inputs into a dated staging folder (preserve subpaths)
rsync -a --exclude ".DS_Store" --exclude "._*" "$INPUT_DIR/" "$STAGE_DIR/" | tee -a "$LOG"

# 2) Normalise filenames (spaces->_, strip odd chars)
find "$STAGE_DIR" -type f | while read -r f; do
  base="$(basename "$f")"
  dir="$(dirname "$f")"
  norm="$(echo "$base" | tr ' ' '_' | tr -cd '[:alnum:]_.-')"
  if [[ "$base" != "$norm" ]]; then
    mv "$f" "$dir/$norm"
    echo "rename: $base -> $norm" >> "$LOG"
  fi
done

# 3) Build SHA256 inventory
find "$STAGE_DIR" -type f -print0 | xargs -0 shasum -a 256 > "$INV"

echo "==> Staged to: $STAGE_DIR"
echo "Inventory: $INV"
echo "Log      : $LOG"
echo "Next: curate staged files into Vault/*, then commit."
