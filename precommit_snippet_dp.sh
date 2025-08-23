#!/bin/sh
set -eu
REPO_ROOT="$(git rev-parse --show-toplevel)"
MODULE="$REPO_ROOT/Q_Vault_v2.0.0_FULL/Vault/Modules/Compliance/Domain_DataProtection_SA_UAE_v1.0.json"
OUT="$REPO_ROOT/Q_Vault_v2.0.0_FULL/Vault/Changelog/DP_SmokeTest_Report.json"

echo "[pre-commit:dp] running Data Protection smoketest..." >&2
# If the smoketest script itself errors (e.g., invalid JSON), block the commit
if ! /usr/bin/python3 "$REPO_ROOT/smoketest_dp.py" --file "$MODULE" --out "$OUT"; then
  echo "✖ DP smoketest ERROR (script failed). See $OUT" >&2
  exit 1
fi

# If it ran, require overall PASS in the report
if grep -q '"overall": "PASS"' "$OUT"; then
  echo "✓ DP smoketest PASS" >&2
else
  echo "✖ DP smoketest FAIL. See $OUT" >&2
  exit 1
fi
