#!/bin/bash
# Check the failure reports, the cleanup, and the tests for the next image without Docker.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/tmp"
export PATH="$WORK/bin:$PATH" TMPDIR="$WORK/tmp" TRACE="$WORK/trace"

cat >"$WORK/bin/docker" <<'MOCK'
#!/bin/bash
set -euo pipefail
printf '%s\n' "$*" >>"$TRACE"
case "$1" in
  build)
    if [[ "$SCENARIO" == shared_build_failure && "$*" == *'rust-node:test'* ]]; then
      exit 48
    fi
    if [[ "$SCENARIO" == build_failure && "$*" == *'java:test'* ]]; then
      exit 41
    fi
    ;;
  run)
    case " $* " in
      *' maven:3-amazoncorretto-25 mvn -B verify '*)
        [[ "$SCENARIO" != verify_failure ]] || exit 42
        ;;
      *' java:test '*|*' java:latest '*)
        [[ "$SCENARIO" == missing_version ]] || echo 'openjdk version "25"'
        echo 'Apache Maven 3'
        [[ "$SCENARIO" != run_failure ]] || exit 43
        ;;
      *' java-eks:test '*|*' java-eks:latest '*) echo test-container ;;
      *' cpp:test '*|*' cpp:latest '*)
        [[ "$SCENARIO" != cpp_failure ]] || exit 44
        ;;
      *' rust-node:test '*|*' rust-node:latest '*)
        [[ " $* " == *' --entrypoint bash '* ]] || exit 49
        [[ " $* " == *'/rust-node/smoke-test.sh:/tmp/docker-gems-smoke.sh:ro '* ]] || exit 50
        echo 'Shared smoke test details'
        [[ "$SCENARIO" != shared_failure ]] || exit 51
        ;;
      *) exit 90 ;;
    esac
    ;;
  inspect) echo 18080 ;;
  logs)
    echo 'Application log details'
    exit 81
    ;;
  rm) ;;
  tag|push) ;;
  compose)
    if [[ " $* " == *' ps -a '* ]]; then
      echo 'Compose service details'
      exit 82
    fi
    if [[ " $* " == *' logs --no-color '* ]]; then
      echo 'Compose log details'
      exit 83
    fi
    if [[ " $* " == *' up '* ]]; then
      if [[ "$SCENARIO" == compose_no_build ]]; then
        [[ " $* " == *' --no-build '* ]] || exit 46
        override=
        while (($#)); do
          [[ "$1" != -f ]] || override=$2
          shift
        done
        grep -Fxq '    pull_policy: never' "$override" || exit 47
      fi
      count=$(grep -c ' up ' "$TRACE")
      [[ "$SCENARIO" != "compose_failure_$count" ]] || exit 45
    fi
    ;;
  *) exit 91 ;;
esac
MOCK

cat >"$WORK/bin/git" <<'MOCK'
#!/bin/bash
set -euo pipefail
[[ "$*" == *'symbolic-ref --quiet --short HEAD' ]] || exit 92
case "$SCENARIO" in
  publish_feature) echo feature/test ;;
  publish_detached) exit 1 ;;
  *) echo main ;;
esac
MOCK

cat >"$WORK/bin/curl" <<'MOCK'
#!/bin/bash
set -euo pipefail
if [[ " $* " == *' -w '* ]]; then
  if [[ "$SCENARIO" == http_failure && "$*" == *'/api-docs' ]]; then
    printf 500
  else
    printf 200
  fi
fi
MOCK
chmod +x "$WORK/bin/docker" "$WORK/bin/curl" "$WORK/bin/git"

failures=0
run_case() {
  local scenario=$1 image=$2 expected=$3
  shift 3
  local next=cpp status=0
  [[ "$image" != cpp ]] || next=java
  : >"$TRACE"
  # GITHUB_ACTIONS is empty, so that the smoke test prints plain OK and FAIL lines.
  if SCENARIO="$scenario" GITHUB_ACTIONS='' bash "$ROOT/test-images.sh" "$@" "$image" "$next" >"$WORK/output" 2>&1; then
    status=0
  else
    status=$?
  fi
  if [[ "$status" != "$expected" ]] || ! grep -Fxq "OK $next" "$WORK/output"; then
    echo "FAIL $scenario: expected exit $expected and a successful next image; got exit $status"
    cat "$WORK/output"
    failures=$((failures + 1))
    return
  fi
  if [[ "$expected" == 1 ]] && ! grep -Fxq "FAIL $image" "$WORK/output"; then
    echo "FAIL $scenario: the failed image was not reported"
    failures=$((failures + 1))
    return
  fi
  if [[ "$scenario" == run_failure ]] && ! grep -Fxq 'Apache Maven 3' "$WORK/output"; then
    echo "FAIL $scenario: failed command output was not shown"
    failures=$((failures + 1))
    return
  fi
  if [[ "$scenario" == shared_failure ]] && ! grep -Fxq 'Shared smoke test details' "$WORK/output"; then
    echo "FAIL $scenario: shared smoke test output was not shown"
    failures=$((failures + 1))
    return
  fi
  if [[ -n "$(ls -A "$WORK/tmp")" ]]; then
    echo "FAIL $scenario: temporary files remain after the test"
    failures=$((failures + 1))
    return
  fi
  if [[ "$scenario" == http_failure ]] && ! grep -Fxq 'rm -f test-container' "$TRACE"; then
    echo "FAIL $scenario: the application container was not removed"
    failures=$((failures + 1))
    return
  fi
  if [[ "$scenario" == http_failure ]] && ! grep -Fxq 'Application log details' "$WORK/output"; then
    echo "FAIL $scenario: application logs were not shown"
    failures=$((failures + 1))
    return
  fi
  if [[ "$scenario" == compose_failure_* ]] && [[ $(grep -c ' down ' "$TRACE") != 2 ]]; then
    echo "FAIL $scenario: the Compose resources were not removed"
    failures=$((failures + 1))
    return
  fi
  if [[ "$scenario" == compose_failure_* ]]; then
    if ! grep -Fxq 'Compose service details' "$WORK/output" || ! grep -Fxq 'Compose log details' "$WORK/output"; then
      echo "FAIL $scenario: Compose service status and logs were not shown"
      failures=$((failures + 1))
      return
    fi
  fi
  echo "PASS $scenario"
}

run_case success java 0
run_case success_no_build java 0 --no-build
run_case compose_no_build my-python-app 0 --no-build
run_case build_failure java 1
run_case run_failure java 1 --no-build
run_case missing_version java 1 --no-build
run_case verify_failure java-eks 1
run_case cpp_failure cpp 1 --no-build
run_case http_failure java-eks 1 --no-build
run_case compose_failure_1 my-python-app 1 --no-build
run_case compose_failure_2 my-python-app 1 --no-build
run_case shared_success rust-node 0
run_case shared_no_build rust-node 0 --no-build
run_case shared_failure rust-node 1 --no-build
run_case shared_build_failure rust-node 1

echo 'Check that a failed smoke test prevents publication'
: >"$TRACE"
if SCENARIO=shared_failure bash "$ROOT/ci/publish-image.sh" rust-node >"$WORK/output" 2>&1; then
  echo 'FAIL publish_failure: publication returned success after a failed smoke test'
  failures=$((failures + 1))
elif grep -Eq '^(tag|push) ' "$TRACE"; then
  echo 'FAIL publish_failure: the failed image was tagged or pushed'
  failures=$((failures + 1))
elif ! grep -Fxq 'Shared smoke test details' "$WORK/output"; then
  echo 'FAIL publish_failure: the smoke test did not run'
  cat "$WORK/output"
  failures=$((failures + 1))
else
  echo 'PASS publish_failure'
fi

for scenario in publish_feature publish_detached; do
  : >"$TRACE"
  if SCENARIO="$scenario" bash "$ROOT/ci/publish-image.sh" rust-node >"$WORK/output" 2>&1; then
    echo "FAIL $scenario: publication was allowed outside main"
    failures=$((failures + 1))
  elif [[ -s "$TRACE" ]] || ! grep -Fxq 'Publish images only from the main branch.' "$WORK/output"; then
    echo "FAIL $scenario: the branch check did not stop before the build"
    cat "$WORK/output"
    failures=$((failures + 1))
  else
    echo "PASS $scenario"
  fi
done

if ((failures)); then
  echo "$failures smoke runner checks failed."
  exit 1
fi
echo 'All smoke runner checks passed.'
