#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
v="$root/Vault"
fail=0

# 1) Vault directory contract
[ -d "$v" ] || { echo "MISSING_DIR Vault"; exit 1; }
need="Modules Config Patches Snapshots Tools Inbox Archive Logs"
for n in $need; do
  [ -d "$v/$n" ] || { echo "MISSING_DIR $n"; fail=1; }
  [ -f "$v/$n/README.md" ] || { echo "MISSING_README $v/$n"; fail=1; }
done

# 2) Tooling for JSON checks
json_checker=""
if command -v python3 >/dev/null 2>&1; then
  json_checker="python3"
elif command -v perl >/dev/null 2>&1; then
  json_checker="perl"
fi

badname=0
json_ok=1
count=0

# 3) Iterate tracked Vault files without mapfile/arrays (Bash 3.2-safe)
while IFS= read -r -d '' f; do
  # Skip generated/archived areas and the catalog
  case "$f" in
    Vault/Snapshots/*|Vault/Archive/*|Vault/Prompt_Catalog.json) continue ;;
  esac

  base="${f##*/}"
  case "$base" in
    *" "* ) echo "SPACE_IN_NAME $f"; badname=1 ;;
  esac

  case "$f" in
    *.json)
      if [ -n "$json_checker" ]; then
        if [ "$json_checker" = "python3" ]; then
          "$json_checker" - <<'PY' < "$root/$f" >/dev/null 2>&1 || { echo "INVALID_JSON $f"; json_ok=0; }
import sys, json
json.load(sys.stdin)
PY
        else
          perl -MJSON::PP -e 'local $/; decode_json(<STDIN>);' < "$root/$f" >/dev/null 2>&1 || { echo "INVALID_JSON $f"; json_ok=0; }
        fi
        count=$((count+1))
        [ "$count" -ge 2000 ] && { echo "JSON_SCAN_LIMIT_REACHED 2000"; break; }
      else
        echo "JSON_PARSE_SKIPPED No_python3_or_perl"
      fi
    ;;
  esac
done < <(git -C "$root" ls-files -z -- 'Vault/*' || printf '\0')

[ "$badname" -eq 0 ] || fail=1
[ "$json_ok" -eq 1 ] || fail=1

[ "$fail" -ne 0 ] && exit 1
echo "LINT_OK"
