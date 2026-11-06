#!/bin/bash
# Print the image name, the Docker versions, the disk space, and the Dockerfile.
# Usage: IMAGE=java DOCKER_HUB_USERNAME=stden ci/show-build-environment.sh
set -euo pipefail

ci/heading.sh info "IMAGE: ${IMAGE:?} -> ${DOCKER_HUB_USERNAME:?}/$IMAGE:latest"
echo '::group::Docker versions and disk space'
docker version
docker compose version
df -h /
echo '::endgroup::'
echo '::group::Dockerfile'
cat "$IMAGE/Dockerfile"
echo '::endgroup::'
