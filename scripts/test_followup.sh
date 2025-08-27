#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$root/tests/.runs"
ts="$(date +%Y%m%d-%H%M%S)"

for case in "$root"/tests/cases/*.json; do
  name="$(basename "$case" .json)"
  out="$root/tests/.runs/${ts}_${name}.out"
  "$root/scripts/run_followup.sh" "$case" > "$out"
  echo "✅ $name -> $out"
done
