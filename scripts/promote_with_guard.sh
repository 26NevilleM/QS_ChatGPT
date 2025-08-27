#!/usr/bin/env bash
set -euo pipefail

slug="${1:?usage: promote_with_guard.sh <slug>}"

sandbox="Vault/Prompt_Library/sandbox/$slug/prompt.md"
active="Vault/Prompt_Library/active/$slug/prompt.md"

# 1) Guard must pass
scripts/guard_prompt.sh "$sandbox"

# 2) Promote sandbox -> active (non-interactive)
scripts/vault/promote_clean.sh -y "$slug"

# 3) Publish (if you use a catalog/index step)
if [ -x scripts/vault/publish_prompt.sh ]; then
  scripts/vault/publish_prompt.sh "$slug"
fi

echo "✅ Completed guard → promote → (publish) for: $slug"
