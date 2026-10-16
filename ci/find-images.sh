#!/bin/bash
# Write the image directory names to GITHUB_OUTPUT for the matrix.
# Usage: GITHUB_OUTPUT=path ci/find-images.sh
set -euo pipefail

images=()
for dockerfile in */Dockerfile; do
  [[ -f "$dockerfile" ]] || continue
  images+=("${dockerfile%/Dockerfile}")
done
[[ ${#images[@]} -gt 0 ]]
printf 'images=%s\n' "$(jq -cn --args '$ARGS.positional' "${images[@]}")" >> "${GITHUB_OUTPUT:?}"
