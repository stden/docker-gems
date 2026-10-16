#!/bin/bash
# Build one image with a fresh base image and no cache.
# Usage: IMAGE=java ci/build-image.sh
set -euo pipefail

ci/heading.sh build "BUILD: ${IMAGE:?}"
docker build --progress=plain --pull --no-cache --tag "$IMAGE:latest" "$IMAGE"
ci/heading.sh pass "BUILD PASSED: $IMAGE"
