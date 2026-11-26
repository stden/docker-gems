#!/bin/bash
# Copy the named images to Amazon ECR.
# Usage: IMAGES="open-webui graphify" ci/copy-selected-images.sh
set -euo pipefail

read -ra images <<< "${IMAGES:-}"
bash aws/copy-to-ecr.sh "${images[@]}"
