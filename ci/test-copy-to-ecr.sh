#!/bin/bash
# Check aws/copy-to-ecr.sh with a mock AWS CLI and a local registry. No AWS account is necessary.
# The test copies stden/codegraph:latest from Docker Hub to a temporary registry container.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
CONTAINER=docker-gems-ecr-test
cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

docker run -d --name "$CONTAINER" -p 127.0.0.1::5000 registry:3 >/dev/null
port=$(docker port "$CONTAINER" 5000/tcp | sed -n 1p | sed 's/.*://')
export REGISTRY="127.0.0.1:$port" TRACE="$WORK/trace" STATE="$WORK/state"
mkdir -p "$WORK/bin" "$STATE"
: > "$TRACE"

# The mock answers like the AWS CLI. The repository URI points to the local registry.
cat > "$WORK/bin/aws" <<'MOCK'
#!/bin/bash
set -euo pipefail
printf '%s\n' "$*" >> "$TRACE"
case "$1 $2" in
  'ecr describe-repositories')
    if [[ -f "$STATE/created" ]]; then
      echo "$REGISTRY/docker-gems/codegraph"
      exit 0
    fi
    echo 'RepositoryNotFoundException' >&2
    exit 254
    ;;
  'ecr create-repository')
    touch "$STATE/created"
    echo "$REGISTRY/docker-gems/codegraph"
    ;;
  'ecr get-login-password') echo mock-password ;;
  'ecr put-lifecycle-policy') ;;
  *)
    echo "Unexpected AWS CLI call: $*" >&2
    exit 99
    ;;
esac
MOCK
chmod +x "$WORK/bin/aws"
# Keep the login of the test out of the Docker configuration of the user.
export PATH="$WORK/bin:$PATH" AWS_REGION=eu-central-1 DOCKER_CONFIG="$WORK/docker"

if bash "$ROOT/aws/copy-to-ecr.sh" no-such-image 2> "$WORK/error"; then
  echo 'FAIL: an unknown image was accepted' >&2
  exit 1
fi
grep -F 'Unknown image: no-such-image' "$WORK/error"

for run in first second; do
  echo "Copy run: $run"
  bash "$ROOT/aws/copy-to-ecr.sh" codegraph
done

source_digest=$(docker buildx imagetools inspect docker.io/stden/codegraph:latest --format '{{.Manifest.Digest}}')
copied_digest=$(docker buildx imagetools inspect "$REGISTRY/docker-gems/codegraph:latest" --format '{{.Manifest.Digest}}')
[[ "$source_digest" == "$copied_digest" ]]
[[ $(grep -c '^ecr create-repository' "$TRACE") == 1 ]]
grep -F -- '--image-tag-mutability IMMUTABLE_WITH_EXCLUSION' "$TRACE"
grep -F -- 'filterType=WILDCARD,filter=latest' "$TRACE"
grep -F -- "file://$ROOT/aws/ecr-lifecycle-policy.json" "$TRACE"
[[ $(grep -c '^ecr put-lifecycle-policy' "$TRACE") == 2 ]]
python3 -m json.tool "$ROOT/aws/ecr-lifecycle-policy.json" > /dev/null
echo "The ECR copy script passed: $copied_digest"
