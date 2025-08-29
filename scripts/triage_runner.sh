#!/usr/bin/env bash
set -euo pipefail
echo "▶︎ Shell: $SHELL"
echo "▶︎ PWD:   $PWD"
if [ -d "Vault" ]; then echo "▶︎ Repo: OK"; else echo "❌ Repo not at root (missing Vault/)"; exit 2; fi
echo "▶︎ Deps:"
if command -v jq >/dev/null 2>&1; then echo "  jq: $(jq --version)"; else echo "  ❌ jq missing (brew install jq)"; exit 1; fi
if command -v pbcopy >/dev/null 2>&1; then echo "  pbcopy: OK"; else echo "  pbcopy: (not critical)"; fi
if [ -x scripts/run_followup.sh ]; then echo "▶︎ runner: scripts/run_followup.sh (executable)"; else echo "❌ scripts/run_followup.sh missing or not executable"; ls -l scripts || true; exit 3; fi
echo "▶︎ Create minimal case"
tmpcase="$(mktemp -t fg_case_XXXX).json"
printf '{"context":"triage sanity","recipient":"Taylor","sender":"Neville","last_contact_days":7}\n' > "$tmpcase"
echo "   -> $tmpcase"
echo "▶︎ Run with bash -x (capturing output)"
set +e
bash -x scripts/run_followup.sh "$tmpcase" > /tmp/fg_stdout.txt 2> /tmp/fg_stderr.txt
rc=$?
set -e
echo "▶︎ Exit code: $rc"
echo "▶︎ STDERR:"; sed 's/^/  > /' /tmp/fg_stderr.txt || true
echo "▶︎ STDOUT:"; sed 's/^/  > /' /tmp/fg_stdout.txt || true
mkdir -p tests/.runs
ts="$(date +%Y%m%d-%H%M%S)"
out="tests/.runs/${ts}_followup.out"
cp /tmp/fg_stdout.txt "$out"
[ -s "$out" ] && { echo "▶︎ Wrote $out"; command -v pbcopy >/dev/null && pbcopy < "$out" && echo "📋 Copied to clipboard"; } || echo "⚠️ Empty output file."
echo "✅ triage complete."
