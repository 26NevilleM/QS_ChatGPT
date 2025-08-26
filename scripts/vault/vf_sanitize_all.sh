#!/usr/bin/env bash
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

LOG="$HOME/Desktop/vault_validation_$(date +%F_%H-%M-%S).log"
: > "$LOG"

# ---- JSON: sanitize only *.json ----
find Vault -type f -name '*.json' -print0 |
while IFS= read -r -d '' f; do
  echo "[JSON] $f" | tee -a "$LOG"
  python3 scripts/vault/sanitize_json.py "$f" >>"$LOG" 2>&1 \
    || echo "[WARN] json-sanitizer exit code $? on $f" | tee -a "$LOG"
done

# ---- Markdown: fence check only prompt.md ----
find Vault -type f -path '*/Prompt_Library/*/prompt.md' -print0 |
while IFS= read -r -d '' f; do
  echo "[MD]   $f" | tee -a "$LOG"
  python3 scripts/vault/check_markdown_fences.py "$f" >>"$LOG" 2>&1 \
    || echo "[WARN] md-fence checker exit code $? on $f" | tee -a "$LOG"
done

# ---- Git: commit if there are changes ----
git add -A
if ! git diff --cached --quiet; then
  git commit -m "chore: vault sanitize (json-only + md-fences)"
  git push
  echo "[GIT] committed & pushed" | tee -a "$LOG"
else
  echo "[GIT] no changes to commit" | tee -a "$LOG"
fi

echo
echo "Tail of log:"
tail -n 40 "$LOG"
