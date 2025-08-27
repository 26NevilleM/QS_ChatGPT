#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  rollback_prompt <slug> [--list | --latest | --ts YYYYMMDD-HHMMSS] [--dry-run]

Examples:
  rollback_prompt followup_generator --list
  rollback_prompt followup_generator --latest
  rollback_prompt followup_generator --ts 20250826-212050
  rollback_prompt followup_generator --ts 20250826-212050 --dry-run

Notes:
  - Backups live at: .../active/<slug>/prompt.md.YYYYMMDD-HHMMSS.bak
  - --list shows available backups (newest first)
  - --latest restores the newest backup
  - --ts restores a specific timestamp
  - --dry-run only prints what would happen
USAGE
}

slug="${1:-}"
shift || true

[[ -z "${slug}" ]] && { echo "❌ Missing <slug>." >&2; usage; exit 1; }

# -------- locate repo root -> BASE/Vault/Prompt_Library --------
script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
BASE="$repo_root/Vault/Prompt_Library"

active_dir="$BASE/active/$slug"
sandbox_dir="$BASE/sandbox/$slug"
active_file="$active_dir/prompt.md"

[[ -d "$active_dir" ]]   || { echo "❌ Active dir not found: $active_dir" >&2; exit 1; }
[[ -f "$active_file" ]]  || { echo "❌ Active file not found: $active_file" >&2; exit 1; }

# -------- parse flags --------
ts=""
mode="choose"   # choose|latest|specific
dry_run="no"
list_only="no"

while (( "$#" )); do
  case "$1" in
    --list)   list_only="yes"; shift ;;
    --latest) mode="latest";  shift ;;
    --ts)     mode="specific"; ts="${2:-}"; [[ -z "$ts" ]] && { echo "❌ --ts requires YYYYMMDD-HHMMSS" >&2; exit 1; }; shift 2 ;;
    --dry-run) dry_run="yes"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "❌ Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

# -------- gather backups --------
shopt -s nullglob
backups=( "$active_dir"/prompt.md.*.bak )
shopt -u nullglob

if (( ${#backups[@]} == 0 )); then
  echo "❌ No backups found in: $active_dir" >&2
  exit 1
fi

# sort newest first by mtime
IFS=$'\n' backups=( $(ls -1t "${backups[@]}") )
unset IFS

if [[ "$list_only" == "yes" ]]; then
  echo "📦 Available backups (newest first):"
  for f in "${backups[@]}"; do
    sz=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
    mt=$(stat -f"%Sm" -t "%Y-%m-%d %H:%M:%S" "$f" 2>/dev/null || stat -c%y "$f")
    echo "  - $(basename "$f")   ($sz bytes, $mt)"
  done
  exit 0
fi

# choose target backup
target=""
case "$mode" in
  latest)
    target="${backups[0]}"
    ;;
  specific)
    cand="$active_dir/prompt.md.$ts.bak"
    [[ -f "$cand" ]] || { echo "❌ Backup not found: $cand" >&2; exit 1; }
    target="$cand"
    ;;
  choose)
    # default to latest for safety/non-interactive
    target="${backups[0]}"
    ;;
esac

echo "➡️  Active file: $active_file"
echo "➡️  Backup to restore: $target"

if [[ "$dry_run" == "yes" ]]; then
  echo "🧪 Dry run only — no changes made."
  exit 0
fi

# sanity check read
head -n 1 "$target" >/dev/null || { echo "❌ Cannot read backup: $target" >&2; exit 1; }

# restore with permissions preserved
cp -p -- "$target" "$active_file"

# verify integrity: show SHA256 and tail diff hint
act_sha=$(shasum -a 256 "$active_file"   | awk '{print $1}')
bak_sha=$(shasum -a 256 "$target"        | awk '{print $1}')

echo "✅ Restored. Hashes:"
echo "   active : $act_sha"
echo "   backup : $bak_sha"

if [[ "$act_sha" != "$bak_sha" ]]; then
  echo "⚠️  Hashes differ — investigate:"
  echo "    diff -u \"$active_file\" \"$target\" | less"
  exit 1
fi

echo "🎉 Rollback complete: active now matches the selected backup."
