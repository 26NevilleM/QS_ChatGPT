#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
"$here/beast_doctor.sh"

echo
echo "—— Preflight complete. Put your next-step command below — e.g.:"
echo "   scripts/followup_cli.sh path/to/case.json"
echo
