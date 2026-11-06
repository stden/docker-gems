#!/bin/bash
# Check that failed tests remove only resources that they create.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin"
export PATH="$WORK/bin:$PATH" TRACE="$WORK/trace"

cat > "$WORK/bin/docker" <<'MOCK'
#!/bin/bash
set -euo pipefail
printf 'docker %s\n' "$*" >> "$TRACE"
case "$1" in
  image) [[ "$SCENARIO" != kind_missing_image ]] || exit 45 ;;
  tag) exit 47 ;;
  run)
    cidfile=
    while (($#)); do
      if [[ "$1" == --cidfile ]]; then
        cidfile=$2
        shift
      fi
      shift
    done
    [[ "$SCENARIO" != registry_start_failure ]] || exit 125
    [[ -n "$cidfile" ]] || exit 91
    printf 'owned-registry-id\n' > "$cidfile"
    [[ "$SCENARIO" != registry_partial_failure ]] || exit 125
    echo owned-registry-id
    ;;
  port) exit 48 ;;
  rm|rmi) ;;
  *) exit 92 ;;
esac
MOCK

cat > "$WORK/bin/kind" <<'MOCK'
#!/bin/bash
set -euo pipefail
printf 'kind %s\n' "$*" >> "$TRACE"
case "$1 $2" in
  'get clusters')
    if [[ "$SCENARIO" == kind_existing_cluster ]]; then
      cluster_work=${KUBECONFIG%/kubeconfig}
      suffix=$(printf '%s' "${cluster_work##*.}" | tr '[:upper:]' '[:lower:]')
      echo "docker-gems-test-$suffix"
    fi
    ;;
  'create cluster')
    printf 'temporary kubeconfig\n' > "$KUBECONFIG"
    [[ "$SCENARIO" != kind_create_failure ]] || exit 46
    ;;
  'delete cluster') ;;
  *) exit 93 ;;
esac
MOCK

cat > "$WORK/bin/kubectl" <<'MOCK'
#!/bin/bash
printf 'kubectl %s\n' "$*" >> "$TRACE"
MOCK
chmod +x "$WORK/bin/docker" "$WORK/bin/kind" "$WORK/bin/kubectl"

failures=0
run_case() {
  local scenario=$1 expected=$2 status=0
  shift 2
  : > "$TRACE"
  SCENARIO="$scenario" bash "$@" > "$WORK/output" 2>&1 || status=$?
  if [[ "$status" != "$expected" ]]; then
    echo "FAIL $scenario: expected exit $expected, got $status"
    cat "$WORK/output"
    failures=$((failures + 1))
    return
  fi
  case "$scenario" in
    kind_invalid|kind_missing_image|kind_existing_cluster)
      if grep -Eq '^kind (create|delete) cluster' "$TRACE"; then
        echo "FAIL $scenario: the test changed a cluster that it did not create"
        failures=$((failures + 1))
        return
      fi
      ;;
    kind_create_failure|kind_deploy_failure)
      local created deleted
      created=$(sed -n 's/^kind create cluster --name \([^ ]*\).*/\1/p' "$TRACE")
      deleted=$(sed -n 's/^kind delete cluster --name \([^ ]*\).*/\1/p' "$TRACE")
      if [[ -z "$created" || "$created" == docker-gems-test || "$deleted" != "$created" ]]; then
        echo "FAIL $scenario: cleanup did not remove only the test cluster"
        failures=$((failures + 1))
        return
      fi
      if ! grep -Fq 'Cluster state after the failure:' "$WORK/output"; then
        echo "FAIL $scenario: cluster diagnostics are absent"
        failures=$((failures + 1))
        return
      fi
      ;;
    registry_start_failure)
      if grep -Eq '^docker rm ' "$TRACE"; then
        echo "FAIL $scenario: cleanup removed a container that the test did not create"
        failures=$((failures + 1))
        return
      fi
      ;;
    registry_partial_failure|registry_port_failure)
      if [[ $(grep '^docker rm ' "$TRACE") != 'docker rm -f owned-registry-id' ]]; then
        echo "FAIL $scenario: cleanup did not use the created container ID"
        failures=$((failures + 1))
        return
      fi
      ;;
  esac
  echo "PASS $scenario"
}

run_case kind_invalid 2 "$ROOT/ci/test-kubernetes.sh" no-such-image
run_case kind_missing_image 45 "$ROOT/ci/test-kubernetes.sh" java-eks
run_case kind_existing_cluster 1 "$ROOT/ci/test-kubernetes.sh" java-eks
run_case kind_create_failure 46 "$ROOT/ci/test-kubernetes.sh" java-eks
run_case kind_deploy_failure 47 "$ROOT/ci/test-kubernetes.sh" java-eks
run_case registry_start_failure 125 "$ROOT/ci/test-copy-to-ecr.sh"
run_case registry_partial_failure 125 "$ROOT/ci/test-copy-to-ecr.sh"
run_case registry_port_failure 48 "$ROOT/ci/test-copy-to-ecr.sh"

if ((failures)); then
  echo "$failures cleanup checks failed."
  exit 1
fi
echo 'All cleanup checks passed.'
