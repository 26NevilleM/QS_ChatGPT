#!/usr/bin/env bash
set -euo pipefail
seed="${1:?seed.json}"
scripts/research_exec.sh "$seed"
last_json="$(ls -t tests/.research_runs/*_research.json 2>/dev/null | head -n 1 || true)"
if [ -n "$last_json" ]; then
  if scripts/research_validate.sh "$last_json"; then
    echo "✅ Pass: $last_json"
  else
    echo "⚠️ Attempting a correction pass..."
    prompt_file="${last_json%.json}.prompt.md"
    corr_out="${last_json%.json}.corr.json"
    corr_prompt="$(cat "$prompt_file"; printf '\n\nPlease re-emit valid JSON strictly matching the schema above with all required keys present.')"
    printf '%s' "$corr_prompt" | scripts/research_infer_openai.sh | tee "$corr_out" >/dev/null
    scripts/research_validate.sh "$corr_out" && echo "✅ Correction succeeded: $corr_out" || echo "❌ Correction failed"
  fi
else
  echo "⚠️ No JSON produced; see markdown output."
fi
