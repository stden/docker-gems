#!/bin/bash
# Publish the overview of each image.
# Usage: DOCKER_HUB_USERNAME=stden DOCKER_HUB_TOKEN=... ci/publish-hub-pages.sh
set -euo pipefail

for dockerfile in */Dockerfile; do
  python3 ci/hub_metadata.py "${dockerfile%/Dockerfile}"
done
