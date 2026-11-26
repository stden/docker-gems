#!/bin/sh
# Download the static tools that the image job uses after Kaniko builds an image.
# Busybox wget does not check TLS certificates. The script keeps each file only when its
# SHA-256 matches the upstream release.
# Usage: install-tools.sh [DEST]
set -eu

DEST=${1:-/cache/my-docker-images-tools}
mkdir -p "$DEST"

# proot 5.5.0, from https://github.com/proot-me/proot/releases/download/v5.5.0/SHA256SUMS
PROOT_URL=https://github.com/proot-me/proot/releases/download/v5.5.0/proot
PROOT_SHA=db185300a9daabbce86aca7632d8c7fdc4249f6f153171954013b70c5f491ec0

# jq 1.8.2, from https://github.com/jqlang/jq/releases/download/jq-1.8.2/sha256sum.txt
JQ_URL=https://github.com/jqlang/jq/releases/download/jq-1.8.2/jq-linux-amd64
JQ_SHA=b1c22172dd303f3be49e935aa56aa48a8b7a46e0bc838b4997d3bb451495870f

# crane 0.22.1. The archive checksum is from upstream checksums.txt.
# The binary checksum is for the crane file inside that verified archive.
CRANE_URL=https://github.com/google/go-containerregistry/releases/download/v0.22.1/go-containerregistry_Linux_x86_64.tar.gz
CRANE_ARCHIVE_SHA=0ab7a1d6932a213aed964ce97666c3077fe691c8606413674a8b3e0b9ec4cda0
CRANE_SHA=8e75c326adb43b053cfd78b9b987663f8f4fe4557f4d3915905643f25c730992

has_sum() {
  sum_file=$1
  sum_value=$2
  [ -f "$sum_file" ] || return 1
  printf '%s  %s\n' "$sum_value" "$sum_file" | sha256sum -c - >/dev/null 2>&1
}

fetch() {
  url=$1
  file=$2
  sum=$3
  if has_sum "$file" "$sum"; then
    return 0
  fi
  wget -O "$file.partial" "$url"
  if ! has_sum "$file.partial" "$sum"; then
    echo "checksum failed: $url" >&2
    rm -f "$file.partial"
    exit 1
  fi
  mv "$file.partial" "$file"
  chmod +x "$file"
}

fetch "$PROOT_URL" "$DEST/proot" "$PROOT_SHA"
fetch "$JQ_URL" "$DEST/jq" "$JQ_SHA"

if ! has_sum "$DEST/crane" "$CRANE_SHA"; then
  fetch "$CRANE_URL" "$DEST/crane.tar.gz" "$CRANE_ARCHIVE_SHA"
  tar -xzf "$DEST/crane.tar.gz" -C "$DEST" crane
  rm -f "$DEST/crane.tar.gz"
  chmod +x "$DEST/crane"
  if ! has_sum "$DEST/crane" "$CRANE_SHA"; then
    echo "crane binary checksum failed" >&2
    exit 1
  fi
fi

echo "tools $DEST"
