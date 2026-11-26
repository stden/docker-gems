#!/bin/bash
# Print the job summary of one image as Markdown. The workflow appends it to the run page.
# The step results (success, failure, cancelled, or skipped) come from the environment.
# Usage: IMAGE=java BUILD_RESULT=success ... ci/job-summary.sh >> "$GITHUB_STEP_SUMMARY"
set -euo pipefail

target="$DOCKER_HUB_USERNAME/$IMAGE:latest"
results="$BUILD_RESULT ${SCAN_RESULT:-skipped} ${SARIF_RESULT:-skipped} $TEST_RESULT $KUBERNETES_RESULT $LOGIN_RESULT $PUBLISH_RESULT $OVERVIEW_RESULT"

mark() {
  case $1 in
    success) echo '✅ success' ;;
    failure) echo '❌ failure' ;;
    cancelled) echo '🚫 cancelled' ;;
    *) echo '⏭️ skipped' ;;
  esac
}

case $results in
  *failure*|*cancelled*) title="❌ $IMAGE" ;;
  *) title="✅ $IMAGE" ;;
esac

# The size is empty when the build failed. The digest is empty when the push did not run.
size=$(docker image ls --format '{{.Size}}' "$IMAGE:latest" 2>/dev/null | sed -n 1p || true)
digest=$(docker image inspect --format '{{join .RepoDigests " "}}' "$target" 2>/dev/null | cut -d ' ' -f 1 || true)

printf '## %s\n\n' "$title"
printf '| Step | Result |\n| --- | --- |\n'
printf '| 🔨 Build | %s |\n' "$(mark "$BUILD_RESULT")"
printf '| 🛡️ CVE scan | %s |\n' "$(mark "${SCAN_RESULT:-skipped}")"
printf '| 📤 SARIF upload | %s |\n' "$(mark "${SARIF_RESULT:-skipped}")"
printf '| 🧪 Smoke test | %s |\n' "$(mark "$TEST_RESULT")"
printf '| ☸️ Kubernetes test | %s |\n' "$(mark "$KUBERNETES_RESULT")"
printf '| 🔐 Docker Hub login | %s |\n' "$(mark "$LOGIN_RESULT")"
printf '| 🚀 Push to Docker Hub | %s |\n' "$(mark "$PUBLISH_RESULT")"
printf '| 📝 Overview and categories | %s |\n\n' "$(mark "$OVERVIEW_RESULT")"
printf 'Image: [%s](https://hub.docker.com/r/%s/%s)' "$target" "$DOCKER_HUB_USERNAME" "$IMAGE"
if [[ -n "$size" ]]; then
  printf ', size %s' "$size"
fi
if [[ -n "$digest" ]]; then
  printf ', digest %s' "${digest#*@}"
fi
printf '\n'
