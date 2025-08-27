#!/bin/bash
set -euo pipefail
slug="${1:-followup_generator}"

scripts/vault/rebuild_catalog.sh
scripts/test_prompt.sh "$slug"
scripts/vault/check_drift.sh "$slug"
echo "✅ All tests passed for $slug"
