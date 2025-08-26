#!/usr/bin/env bash
set -euo pipefail
zipfile="${1:?usage: pack_verify.sh path/to/pack.zip}"
command -v shasum >/dev/null 2>&1 && algo="shasum -a 256" || algo="openssl dgst -sha256 | awk '{print \$2}'"
echo "== Contents =="
unzip -l "$zipfile"
echo "== SHA256 =="
if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$zipfile"
else
  openssl dgst -sha256 "$zipfile"
fi
