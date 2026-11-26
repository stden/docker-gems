#!/bin/bash
# Print the container state and the disk use after a failed image job.
# Usage: IMAGE=java ci/show-image-failure.sh
set -euo pipefail

ci/heading.sh fail "FAILED: ${IMAGE:?}. Check the failed step above."
echo "::error title=Image job failed::The $IMAGE job failed. Check the build or test output above."
echo '::group::Container state and disk use'
docker ps -a
docker system df
df -h /
echo '::endgroup::'
