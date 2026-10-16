#!/bin/bash
# Tag the tested image and push that tag to Docker Hub.
# Usage: IMAGE=java TARGET=stden/java:latest ci/push-tested-image.sh
set -euo pipefail

ci/heading.sh publish "PUBLISH: ${TARGET:?}"
echo "::group::Push the tested image to $TARGET"
docker tag "${IMAGE:?}:latest" "$TARGET"
docker push "$TARGET"
echo '::endgroup::'
ci/heading.sh pass "PUBLISHED: $TARGET"
