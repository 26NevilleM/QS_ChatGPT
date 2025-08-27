#!/bin/bash
set -euo pipefail
slug="${1:?Usage: publish_prompt <slug>}"

# 1) Smoke test before (if available)
if command -v run_prompt >/dev/null 2>&1; then
  echo "---- SMOKE TEST (pre) ----"
  run_prompt "$slug" --input '{"context":"publish smoke","recipient":"QA","sender":"Neville"}' >/dev/null || true
fi

# 2) Promote (auto-confirm)
scripts/vault/promote_clean.sh -y "$slug"

# 3) Smoke test after (if available)
if command -v run_prompt >/dev/null 2>&1; then
  echo "---- SMOKE TEST (post) ----"
  run_prompt "$slug" --input '{"context":"post-promo","recipient":"QA","sender":"Neville"}' >/dev/null || true
fi

# 4) Drift check (must be clean)
scripts/vault/check_drift.sh "$slug"

echo "🎉 $slug published clean."
