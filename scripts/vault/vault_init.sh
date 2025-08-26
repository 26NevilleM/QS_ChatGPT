#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
d="$root/Vault"
dirs=(Modules Compliance Personas Workflows Config Patches Snapshots Tools Inbox Archive Logs)
for x in "${dirs[@]}"; do
  mkdir -p "$d/$x"
  [ -f "$d/$x/README.md" ] || printf "# %s\n\nSeed placeholder.\n" "$x" > "$d/$x/README.md"
done
cfg="$d/Config/Config_Master.json"
[ -f "$cfg" ] || printf "{\n  \"config_version\": \"1.0.0\",\n  \"__metadata\": {\"created\": \"%s\",\"owner\": \"QS_ChatGPT/BEAST\",\"notes\": \"Seed master config\"},\n  \"personas\": {},\n  \"modules\": {},\n  \"policies\": {},\n  \"paths\": {\"modules\":\"Vault/Modules\",\"snapshots\":\"Vault/Snapshots\",\"patches\":\"Vault/Patches\",\"tools\":\"Vault/Tools\",\"inbox\":\"Vault/Inbox\",\"archive\":\"Vault/Archive\"}\n}\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$cfg"
echo OK
