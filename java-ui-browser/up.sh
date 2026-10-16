#!/bin/bash
set -euo pipefail
export USER=stden
export IMAGE=java-ui-browser
export TAG=latest
echo ===== Build image =====
docker build -t $IMAGE .
echo ===== Test image =====
bash "$(cd "$(dirname "$0")/.." && pwd)/test-images.sh" --no-build "$IMAGE"
echo ===== Tag image =====
docker tag $IMAGE:$TAG $USER/$IMAGE:$TAG
echo ===== Push to https://hub.docker.com/repository/docker/stden/java-ui-browser =====
docker push $USER/$IMAGE:$TAG
