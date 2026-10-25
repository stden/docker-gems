#!/usr/bin/env bash
# Check every compiler and both PDF engines with the built-in examples.
set -euo pipefail

status=0
output=$(/x/test.sh) || status=$?
printf '%s\n' "$output"
if ((status != 0)); then
    exit "$status"
fi
for language in C C++ 'C#' D Haskell Pascal Python pdfLaTeX LuaLaTeX; do
    if ! grep -Fxq "PASS $language" <<< "$output"; then
        printf 'FAIL: no result for %s.\n' "$language" >&2
        exit 1
    fi
done
