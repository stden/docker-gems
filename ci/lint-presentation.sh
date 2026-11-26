#!/usr/bin/env bash
# Lint Typst presentation files for known diagram overlap patterns.
# Run: bash ci/lint-presentation.sh <file.typ>
# Exit 1 when problems are found.
set -euo pipefail

FILE="${1:?Usage: $0 <file.typ>}"
ERRORS=0

warn() { echo "WARN  line $1: $2"; }
fail() { echo "FAIL  line $1: $2"; ERRORS=$((ERRORS + 1)); }

echo "=== lint-presentation: $FILE ==="

# Rule 1: <-> edge with label-side: center and NO bend — label sits on the
#         midpoint of a straight line and overlaps adjacent nodes.
while IFS= read -r line; do
    lineno=$(echo "$line" | cut -d: -f1)
    text=$(echo "$line"  | cut -d: -f2-)
    if echo "$text" | grep -q '"<->"'; then
        if echo "$text" | grep -q 'label-side: center'; then
            if ! echo "$text" | grep -q 'bend:'; then
                fail "$lineno" '<-> with label-side: center and no bend — label will overlap nodes. Add bend: 25deg / bend: -25deg pair.'
            fi
        fi
    fi
done < <(grep -n '<->' "$FILE")

# Rule 2: horizontal edge (implicit or "r"/"l") with label-side: center —
#         same overlap risk as Rule 1 for single-direction edges.
while IFS= read -r line; do
    lineno=$(echo "$line" | cut -d: -f1)
    text=$(echo "$line"  | cut -d: -f2-)
    if echo "$text" | grep -qE '"r"|"l"|"->"|"<-"'; then
        if echo "$text" | grep -q 'label-side: center'; then
            if ! echo "$text" | grep -q 'bend:'; then
                warn "$lineno" 'Horizontal edge with label-side: center — label may overlap node. Use label-side: left or right.'
            fi
        fi
    fi
done < <(grep -n 'edge(' "$FILE")

# Rule 3: spacing x-value smaller than node width on the same diagram block.
#         Detect spacing(Xem, ...) where X < 4 and width: Wem where W >= X.
#         This is a heuristic — manual review is still necessary.
while IFS= read -r line; do
    lineno=$(echo "$line" | cut -d: -f1)
    text=$(echo "$line"  | cut -d: -f2-)
    if echo "$text" | grep -qE 'spacing: \([0-9]+em'; then
        x=$(echo "$text" | grep -oE 'spacing: \([0-9]+' | grep -oE '[0-9]+$')
        if [ -n "$x" ] && [ "$x" -lt 4 ]; then
            warn "$lineno" "spacing x=${x}em is very tight — check that node widths leave room for edge labels."
        fi
    fi
done < <(grep -n 'spacing:' "$FILE")

echo "=== $ERRORS error(s) found ==="
exit $ERRORS
