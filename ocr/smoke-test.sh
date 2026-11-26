#!/usr/bin/env bash
# Draw English and Russian text into PNG images, then read the text with Tesseract.
# The test is offline and removes its files on exit.
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# Print the text that Tesseract reads from an image, without spaces, for a simple comparison.
read_text() {
    tesseract "$1" stdout -l "$2" --psm 7 2>/dev/null | tr -d '[:space:]'
}

convert -size 1200x200 xc:white -font DejaVu-Sans -pointsize 72 \
    -fill black -annotate +40+120 "HELLO 2026" english.png
convert -size 1200x200 xc:white -font DejaVu-Sans -pointsize 72 \
    -fill black -annotate +40+120 "ПРИВЕТ" russian.png

[[ "$(read_text english.png eng)" == HELLO2026 ]] || fail "English text was not read correctly"
echo "OK: English text is read"
[[ "$(read_text russian.png rus)" == ПРИВЕТ ]] || fail "Russian text was not read correctly"
echo "OK: Russian text is read"
echo "All OCR checks passed."
