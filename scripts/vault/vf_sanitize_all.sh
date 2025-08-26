#!/usr/bin/env bash
set -euo pipefail

# --- locate repo root (works even if you run from a subdir) ---
if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  cd "$git_root"
fi

# --- logging ---
ts="$(date +%Y-%m-%d_%H-%M-%S)"
LOG="$HOME/Desktop/vault_validation_$ts.log"
echo "[vf_sanitize_all] started at $(date)" | tee -a "$LOG"

# --- build list of files to sanitize (JSON + prompt.md, skip backups and packs) ---
mapfile -d '' FILES < <(
  find Vault -type f \
    \( -name '*.json' -o -path '*/Prompt_Library/*/prompt.md' \) \
    ! -path 'Vault/Packs/*' \
    ! -name '*.bak' \
    -print0
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "[vf_sanitize_all] No candidate files found." | tee -a "$LOG"
  exit 0
fi

# --- run the sanitizer per file with python3 (avoid calling the script as sh) ---
PY="python3"
SAN="scripts/vault/sanitize_json.py"

if [[ ! -x "$SAN" ]]; then
  # ensure it has a shebang (harmless if already present)
  if ! head -n1 "$SAN" | grep -q '^#!'; then
    tmp="$(mktemp)"; printf '%s\n' '#!/usr/bin/env python3' | cat - "$SAN" > "$tmp" && mv "$tmp" "$SAN"
  fi
  chmod +x "$SAN"
fi

echo "[vf_sanitize_all] Processing ${#FILES[@]} files..." | tee -a "$LOG"
changed=0
for f in "${FILES[@]}"; do
  echo "  → $f" | tee -a "$LOG"
  # Run under python3 explicitly, capture exit code
  if "$PY" "$SAN" "$f" >>"$LOG" 2>&1; then
    :
  else
    echo "     [WARN] sanitizer returned non-zero for: $f" | tee -a "$LOG"
  fi
done

# --- stage & commit only if there are changes ---
if ! git diff --quiet -- Vault; then
  echo "[vf_sanitize_all] Changes detected; staging…" | tee -a "$LOG"
  git add Vault
  if ! git diff --cached --quiet; then
    msg="chore: vault validation + auto-fixes ($(date +%Y-%m-%d))"
    git commit -m "$msg" | tee -a "$LOG"
    echo "[vf_sanitize_all] Pushing…" | tee -a "$LOG"
    git push | tee -a "$LOG"
    changed=1
  fi
else
  echo "[vf_sanitize_all] No changes produced by sanitizer." | tee -a "$LOG"
fi

echo "[vf_sanitize_all] done. Log: $LOG" | tee -a "$LOG"

# exit status reflects whether we changed anything (0 = no change, 1 = changed)
exit $changed
