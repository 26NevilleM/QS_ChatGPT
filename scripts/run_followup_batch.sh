#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/run_followup_batch.sh <<'CSV'
# recipient,sender,last_contact_days,context
# Jordan,Neville,2,Confirm Phase 1 scope + start date
# CSV

# requires: jq and scripts/followup_cli.sh
if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq is required"; exit 1
fi
if [ ! -x scripts/followup_cli.sh ]; then
  echo "❌ scripts/followup_cli.sh missing or not executable"; exit 1
fi

# read header
IFS= read -r header || { echo "❌ empty CSV on stdin"; exit 1; }
# normalize header just in case
header=$(echo "$header" | tr -d '\r')

# expected header
expected="recipient,sender,last_contact_days,context"
if [ "$header" != "$expected" ]; then
  echo "❌ CSV header mismatch."
  echo "   got:      $header"
  echo "   expected: $expected"
  exit 1
fi

ts="$(date +%Y%m%d-%H%M%S)"
mkdir -p tests/.runs

# process rows
while IFS= read -r line; do
  [ -z "$line" ] && continue
  # strip CR from possible Windows newlines
  line="${line%$'\r'}"

  # Split into 4 fields only (context may contain commas — handle with awk CSV-ish split)
  recip=$(echo "$line" | awk -F',' '{print $1}')
  sender=$(echo "$line" | awk -F',' '{print $2}')
  days=$(echo "$line"   | awk -F',' '{print $3}')
  # context = everything after the 3rd comma
  context=$(echo "$line" | awk -F',' '{ 
    if (NF<=3) { print ""; } 
    else { 
      c=$4; 
      for (i=5;i<=NF;i++) c=c FS $i; 
      print c 
    } 
  }')

  # build a temp case JSON with jq (avoids quoting bugs)
  tmpcase="$(mktemp -t fg_batch_XXXX).json"
  jq -n --arg recip "$recip" --arg sender "$sender" --argjson days "$days" --arg context "$context" \
    '{recipient:$recip, sender:$sender, last_contact_days:$days, context:$context}' > "$tmpcase"

  echo "▶︎ running for: $recip ($days d)"
  bash -x scripts/followup_cli.sh "$tmpcase"
done

echo "✅ batch complete."
