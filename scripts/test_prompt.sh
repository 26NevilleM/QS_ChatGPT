#!/bin/bash
set -euo pipefail
slug="${1:-followup_generator}"

cases_dir="tests/cases"
golden_dir="tests/golden"

if ! command -v run_prompt >/dev/null 2>&1; then
  echo "⚠️  'run_prompt' not found. Skipping prompt tests (exit 0 for now)."
  exit 0
fi

fail=0
for case in "$cases_dir"/*.json; do
  [ -e "$case" ] || continue
  name="$(basename "$case" .json)"
  out="tests/.tmp_${slug}_${name}.json"
  golden="$golden_dir/${slug}_${name}.golden.json"

  # Run the prompt
  run_prompt "$slug" --input "$(cat "$case")" > "$out"

  # Normalize output to remove unstable fields
  if command -v jq >/dev/null 2>&1; then
    mv "$out" "${out}.raw"
    jq -f scripts/normalize_prompt_output.jq < "${out}.raw" > "$out" 2>/dev/null || cp "${out}.raw" "$out"
    rm -f "${out}.raw"
  fi

  if [ ! -f "$golden" ]; then
    echo "🟡 No golden for ${name}; creating: $golden"
    mkdir -p "$golden_dir"
    cp "$out" "$golden"
  else
    if ! diff -u "$golden" "$out" > "tests/.diff_${slug}_${name}.txt"; then
      echo "❌ Snapshot drift for ${name} (see tests/.diff_${slug}_${name}.txt)"
      fail=1
    else
      rm -f "tests/.diff_${slug}_${name}.txt"
      echo "✅ ${name}"
    fi
  fi
done

exit $fail
