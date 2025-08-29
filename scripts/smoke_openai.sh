#!/usr/bin/env bash
set -euo pipefail
: "${OPENAI_API_KEY:?OPENAI_API_KEY not set}"

curl -s https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
| head -n 30
