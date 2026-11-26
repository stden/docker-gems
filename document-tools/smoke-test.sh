#!/usr/bin/env bash
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

python --version
uv --version
typst --version
libreoffice --version
pdftotext -v

cat > sample.typ <<'TYP'
#set text(font: "DejaVu Sans")
= Document tools
Typst PDF conversion passed.
TYP
typst compile sample.typ sample.pdf
pdftotext sample.pdf sample.txt
grep -Fq 'Typst PDF conversion passed.' sample.txt
pdfinfo sample.pdf

printf '%s\n' 'LibreOffice document conversion passed.' > writer.txt
libreoffice -env:UserInstallation="file://$work/lo-profile" --headless \
    --convert-to docx --outdir "$work" writer.txt
test -s writer.docx
libreoffice -env:UserInstallation="file://$work/lo-profile" --headless \
    --convert-to pdf --outdir "$work" writer.docx
pdftotext writer.pdf writer-result.txt
grep -Fq 'LibreOffice document conversion passed.' writer-result.txt
python - <<'PY'
from zipfile import ZipFile

with ZipFile("writer.docx") as document:
    assert b"LibreOffice document conversion passed." in document.read("word/document.xml")
print("Typst PDF and LibreOffice DOCX/PDF conversion passed.")
PY
