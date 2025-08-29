#!/usr/bin/env bash
set -euo pipefail

case_json="${1:?path to research seed json}"
prompt_path="${2:-Vault/Prompt_Library/active/research_probe/prompt.md}"

# deps
command -v jq >/dev/null 2>&1 || { echo "❌ jq not found"; exit 1; }

objective="$(jq -r '.objective // ""' "$case_json")"
constraints="$(jq -r '.constraints // ""' "$case_json")"
schema="$(jq -r '.schema // ""' "$case_json")"

# sources: bulletize if array
if jq -e 'has("sources") and (.sources|type=="array")' "$case_json" >/dev/null; then
  sources="$(jq -r '.sources[]' "$case_json" | sed 's/^/- /')"
else
  sources="$(jq -r '.sources // ""' "$case_json")"
fi

# template: use file if present, else fallback
if [ -f "$prompt_path" ]; then
  template="$(cat "$prompt_path")"
else
  template=$'# Research Probe (fallback)\n\nObjective:\n{{objective}}\n\nSources:\n{{sources}}\n\nConstraints:\n{{constraints}}\n\nSchema:\n{{schema}}\n'
fi

# render safely with python3 (handles any characters)
command -v python3 >/dev/null 2>&1 || { echo "❌ python3 not found"; exit 1; }
rendered="$(python3 - "$template" "$objective" "$sources" "$constraints" "$schema" <<'PY'
import sys
template = sys.argv[1]
obj, src, cons, sch = sys.argv[2:6]
out = (template
       .replace("{{objective}}", obj)
       .replace("{{sources}}", src)
       .replace("{{constraints}}", cons)
       .replace("{{schema}}", sch))
print(out)
PY
)"

# write output + clipboard
mkdir -p tests/.research_runs
stamp="$(date +%Y%m%d-%H%M%S)"
outfile="tests/.research_runs/${stamp}_research.out"
printf "%s\n" "$rendered" | tee "$outfile" >/dev/null
command -v pbcopy >/dev/null 2>&1 && pbcopy < "$outfile" && echo "📋 Copied to clipboard."
echo "✅ Wrote: $outfile"
