# Read text from images with Tesseract OCR 5: English and Russian language data.
# Ubuntu 24.04 ships Tesseract 5. The Debian stable release ships Tesseract 4 language data.
FROM ubuntu:26.04

# Install security updates of the base image, then Tesseract with the English and Russian data.
# ImageMagick and the DejaVu fonts let a test draw text into an image.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates tesseract-ocr tesseract-ocr-eng tesseract-ocr-rus imagemagick fonts-dejavu-core && \
    rm -rf /var/lib/apt/lists/*

# Verify the tools and the languages at build time. A missing language stops the build.
# The pipes need pipefail, so a failing tesseract stops the build.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN tesseract --version && convert --version >/dev/null && \
    tesseract --list-langs 2>&1 | grep -qx eng && \
    tesseract --list-langs 2>&1 | grep -qx rus

WORKDIR /workspace
CMD ["bash"]
