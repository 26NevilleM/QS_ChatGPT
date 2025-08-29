#!/usr/bin/env bash
set -euo pipefail

seed="${1:?Usage: scripts/research_exec.sh path/to/seed.json}"
template_path="Vault/Prompt_Library/active/research_probe/prompt.md"

# Extract fields from seed
objective="$(jq -r '.objective // ""' "$seed")"
constraints="$(jq -r '.constraints // ""' "$seed")"
schema="$(jq -r '.schema // ""' "$seed")"

# If you have file paths in .files, we’ll concatenate their contents into one block:
# e.g. "files": ["notes/kickoff.txt","notes/email_summary.txt"]
if jq -e 'has("files") and (.files|type=="array") and (.files|length>0)' "$seed" >/dev/null; then
  src_text=""
  while IFS= read -r f; do
    if [ -f "$f" ]; then
      src_text+="\n---\n# Source: $f\n"
      src_text+="$(cat "$f")\n"
    else
      src_text+="\n---\n# Source MISSING: $f\n"
    fi
  done < <(jq -r '.files[]' "$seed")
  sources="$src_text"
else
  # Or fallback to .sources array of plain descriptors
  sources="$(jq -r '.sources? // [] | .[]' "$seed" | sed 's/^/- /')"
fi

# Load template
template="$(cat "$template_path")"

# Render with python3 (safe replace of {{placeholders}})
rendered="$(python3 - "$template" "$objective" "$sources" "$constraints" "$schema" <<'PY'
import sys, json
tpl, objective, sources, constraints, schema = sys.argv[1:]
print(
  tpl.replace("{{objective}}", objective)
     .replace("{{sources}}", sources)
     .replace("{{constraints}}", constraints)
     .replace("{{schema}}", schema)
)
PY
)"

# Prepare run folder + filenames
mkdir -p tests/.research_runs
stamp="$(date +%Y%m%d-%H%M%S)"
outbase="tests/.research_runs/${stamp}_research"
prompt_file="${outbase}.prompt.md"
json_file="${outbase}.json"
md_file="${outbase}.md"

# Save prompt for audit
printf '%s\n' "$rendered" | tee "$prompt_file" >/dev/null

# Call the model
reply="$(printf '%s\n' "$rendered" | scripts/research_infer_openai.sh)"

# Try to detect JSON; if valid JSON, pretty print to .json and also mk a readable .md
if echo "$reply" | jq . >/dev/null 2>&1; then
  echo "$reply" | jq . > "$json_file"
  {
    echo "# Research Output (JSON)"
    echo
    echo '```json'
    cat "$json_file"
    echo '```'
  } > "$md_file"
else
  # Not JSON: just save as markdown
  printf '%s\n' "$reply" > "$md_file"
fi

# Convenience: copy the human-readable file to clipboard if available
command -v pbcopy >/dev/null && pbcopy < "$md_file" && echo "📋 Copied to clipboard."

echo "✅ Wrote:"
[ -f "$json_file" ] && echo "  - $json_file"
echo "  - $md_file"
echo "  - $prompt_file"
