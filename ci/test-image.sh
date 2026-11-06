#!/bin/bash
# Run the smoke test of one image. The test uses the image from the build.
# Usage: IMAGE=java ci/test-image.sh
set -euo pipefail

ci/heading.sh test "SMOKE TEST: ${IMAGE:?}"
echo "::group::Smoke test for $IMAGE"
./test-images.sh --no-build "$IMAGE"
echo '::endgroup::'
ci/heading.sh pass "SMOKE TEST PASSED: $IMAGE"
