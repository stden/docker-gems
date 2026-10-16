#!/bin/bash
# Build, test, and publish one image.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
if [[ $# != 1 || ! "$1" =~ ^[a-z0-9][a-z0-9-]*$ || ! -f "$ROOT/$1/Dockerfile" ]]; then
  echo "Usage: $0 IMAGE" >&2
  exit 2
fi
if [[ "$(git -C "$ROOT" symbolic-ref --quiet --short HEAD || true)" != main ]]; then
  echo 'Publish images only from the main branch.' >&2
  exit 1
fi
image=$1
target="${DOCKER_HUB_USERNAME:-stden}/$image:latest"

echo "Build $image"
docker build --pull --no-cache --tag "$image:latest" "$ROOT/$image"
echo "Test $image"
bash "$ROOT/test-images.sh" --no-build "$image"
echo "Publish $target"
docker tag "$image:latest" "$target"
docker push "$target"
