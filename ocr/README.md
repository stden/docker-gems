# stden/ocr

Read English and Russian text from images with Tesseract OCR 5 in a Docker container.

## What you learn

You learn to read the text of an image with Tesseract, without installing the language data.

## Overview

This image reads the text of images on a computer or in a CI job. It contains:

- [Tesseract OCR](https://github.com/tesseract-ocr/tesseract) 5, from the Ubuntu 24.04 packages.
- The English (`eng`) and Russian (`rus`) language data.
- [ImageMagick](https://imagemagick.org/) and the DejaVu fonts, to draw text into test images.

The base image is `ubuntu:24.04`. The working directory is `/workspace`. The default command
starts Bash.

## Run the image

Read the text of an image in the current directory:

```bash
docker run --rm -v "$PWD":/workspace -w /workspace stden/ocr tesseract scan.png stdout -l eng+rus
```
