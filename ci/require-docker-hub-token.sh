#!/bin/bash
# Stop when the Docker Hub token is empty.
# Usage: DOCKER_HUB_TOKEN=... ci/require-docker-hub-token.sh
set -euo pipefail

if [[ -z "${DOCKER_HUB_TOKEN:-}" ]]; then
  echo '::error::Set the DOCKER_HUB_TOKEN repository secret to a Docker Hub token with write access.'
  exit 1
fi
