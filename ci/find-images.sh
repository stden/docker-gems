#!/bin/bash
# Write the image directory names to GITHUB_OUTPUT for the matrix.
# Usage: GITHUB_OUTPUT=path ci/find-images.sh
#
# On a push to main: output only images whose files changed (or all images
# when a CI directory changed, because CI changes can affect every image).
# On schedule, workflow_dispatch, and pull_request: output all images.
set -euo pipefail

all_images=()
for dockerfile in */Dockerfile; do
  [[ -f "$dockerfile" ]] || continue
  all_images+=("${dockerfile%/Dockerfile}")
done
[[ ${#all_images[@]} -gt 0 ]]

if [[ "${GITHUB_EVENT_NAME:-}" == "push" && -n "${BEFORE_SHA:-}" ]] \
    && git cat-file -e "${BEFORE_SHA}^{commit}" 2>/dev/null; then
  # Get the top-level directories that changed in this push.
  changed_files=$(git diff --name-only "$BEFORE_SHA" HEAD)
  changed_dirs=$(printf '%s\n' "$changed_files" \
    | grep '/' | cut -d/ -f1 | sort -u || true)

  # A change to ci/ or .github/ can affect any image — rebuild all.
  if echo "$changed_dirs" | grep -qE '^(ci|\.github)$'; then
    echo "CI or workflow files changed — building all images."
    images=("${all_images[@]}")
  else
    images=()
    for img in "${all_images[@]}"; do
      if echo "$changed_dirs" | grep -qx "$img"; then
        images+=("$img")
      fi
    done
    echo "Push filter: ${#images[@]} changed image(s): ${images[*]:-none}"
  fi
else
  # Build all images for other events or an unavailable push baseline.
  echo "Full build: ${#all_images[@]} image(s)"
  images=("${all_images[@]}")
fi

if [[ ${#images[@]} -gt 0 ]]; then
  printf 'images=%s\n' "$(jq -cn --args '$ARGS.positional' "${images[@]}")"  \
    >> "${GITHUB_OUTPUT:?}"
else
  # Nothing changed — write an empty array so the matrix job is skipped.
  printf 'images=%s\n' "[]" >> "${GITHUB_OUTPUT:?}"
  echo "No images to build for this push."
fi
