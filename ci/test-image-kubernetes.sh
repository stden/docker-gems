#!/bin/bash
# Deploy one image to a local kind cluster and run its checks.
# Usage: IMAGE=java-eks ci/test-image-kubernetes.sh
set -euo pipefail

ci/heading.sh test "KUBERNETES TEST: ${IMAGE:?}"
kind version
kubectl version --client
echo "::group::Deploy $IMAGE to a kind cluster"
bash ci/test-kubernetes.sh "$IMAGE"
echo '::endgroup::'
ci/heading.sh pass "KUBERNETES TEST PASSED: $IMAGE"
