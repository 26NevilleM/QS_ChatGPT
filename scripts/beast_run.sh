#!/usr/bin/env bash
set -euo pipefail
path="$(scripts/run_beast_research.sh "$@")"   # stdout == file path only
summary="$(cat "$path")"
scripts/beast_hooks/after_research.sh "$summary"
