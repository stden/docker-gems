# stden/document-tools

Create PDF files with Typst and LibreOffice, and inspect them with Poppler tools.

## Overview

Use this image for document builds, report conversion, and PDF checks. It
contains:

- Typst for document layout and PDF generation.
- LibreOffice for headless document conversion.
- Poppler tools, for example `pdfinfo`, `pdftotext`, and `pdftoppm`.
- DejaVu and Liberation fonts.
- Python and uv for document scripts.

The working directory is `/workspace`. The default command starts Bash. The
LibreOffice package runs only on `linux/amd64`.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main`. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/document-tools/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/document-tools:latest
```

## Create a PDF with Typst

Run these commands in the directory where you want to save the document:

```sh
printf '= Hello from Docker\nThis PDF was built with Typst.\n' > report.typ

docker run --rm -v "$PWD":/workspace stden/document-tools:latest \
  typst compile report.typ report.pdf
```

The mount saves `report.pdf` on your host. If your document uses Typst packages,
network access can be necessary at their first use.

## Convert an office document to PDF

Put `report.docx` in the current directory. Then run this command:

```sh
docker run --rm -v "$PWD":/workspace stden/document-tools:latest \
  libreoffice -env:UserInstallation=file:///tmp/lo-profile --headless \
  --convert-to pdf --outdir /workspace report.docx
```

The same command can convert supported office files, such as `.odt`, `.xlsx`,
and `.pptx`. Change the input file name. LibreOffice can also convert a text file
to DOCX:

```sh
docker run --rm -v "$PWD":/workspace stden/document-tools:latest \
  libreoffice -env:UserInstallation=file:///tmp/lo-profile --headless \
  --convert-to docx --outdir /workspace notes.txt
```

Each command uses a temporary LibreOffice profile inside its container. Supply
the fonts that your source document uses. Missing fonts can change the layout.

## Inspect a PDF

Show the page count, the page size, and the document metadata:

```sh
docker run --rm -v "$PWD":/workspace stden/document-tools:latest \
  pdfinfo report.pdf
```

Extract the text and keep the page layout:

```sh
docker run --rm -v "$PWD":/workspace stden/document-tools:latest \
  pdftotext -layout report.pdf report.txt
```

Create a PNG image of the first page for a visual check:

```sh
docker run --rm -v "$PWD":/workspace stden/document-tools:latest \
  pdftoppm -f 1 -singlefile -png -r 150 report.pdf report-page
```

The last command saves `report-page.png`. Text extraction works on PDF text. It
does not do OCR on scanned pages.

## Use your own scripts

Mount the project directory and run your Python script:

```sh
docker run --rm -v "$PWD":/workspace stden/document-tools:latest \
  python check_report.py
```

Install extra Python libraries in a child image that starts with
`FROM stden/document-tools:latest`. All generated files in `/workspace` stay
on the host. The default container user is root, so on Linux the output files can
belong to root.

## Source and checks

The smoke test creates a Typst PDF, converts text to DOCX and PDF with
LibreOffice, and checks the extracted text.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/document-tools/Dockerfile)
- [Smoke test](https://github.com/stden/docker-gems/blob/main/document-tools/smoke-test.sh)
- [Overview source](https://github.com/stden/docker-gems/blob/main/document-tools/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
