#!/bin/bash
# Build images and run smoke tests.
# ./test-images.sh                 - build and test each image with the :test tag
# ./test-images.sh java rust       - test only the specified directories
# ./test-images.sh --no-build java - test the java:latest image without a build
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
cd "$ROOT"

ALL=(
  allure
  android
  argocd
  code-quality
  codegraph
  compilers
  cpp
  cpp-cuda
  cpp-vulkan
  crossplane
  document-tools
  graphify
  java
  java-eks
  java-run-swing
  java-ui-browser
  latex
  my-python-app
  open-webui
  php
  postgres-vector-graph
  python
  python-media
  rust
  rust-ci
  rust-desktop
  rust-node
  web-qa
)

# --no-build tests the :latest tag that docker build -t <name> creates.
NO_BUILD=0
IMAGE_TAG="test"

# Color the heading, OK, and FAIL lines when the output is a terminal or a GitHub Actions log.
# The runner test ci/test-smoke-failures.sh sets GITHUB_ACTIONS to an empty value,
# because it compares the plain lines.
if [[ -t 1 || -n "${GITHUB_ACTIONS:-}" ]]; then
  HEAD_COLOR=$'\033[1;96m' OK_COLOR=$'\033[1;92m' FAIL_COLOR=$'\033[1;91m' END_COLOR=$'\033[0m'
else
  HEAD_COLOR='' OK_COLOR='' FAIL_COLOR='' END_COLOR=''
fi

usage() {
  echo "Usage: ./test-images.sh [--no-build] [image ...]"
  echo "Without arguments, the script tests all images: ${ALL[*]}"
  echo "--no-build tests the :latest tag without a build."
}

is_known() {
  local name=$1
  local item
  for item in "${ALL[@]}"; do
    if [[ "$item" == "$name" ]]; then
      return 0
    fi
  done
  return 1
}

build_image() {
  local name=$1
  if [[ "$NO_BUILD" -eq 1 ]]; then
    return 0
  fi
  echo "Build ${name}:${IMAGE_TAG}"
  docker build -t "${name}:${IMAGE_TAG}" "$ROOT/$name"
}

# Print command output and check that it contains each expected string.
expect_lines() {
  local output=$1
  shift
  printf '%s\n' "$output"
  local line
  for line in "$@"; do
    printf '%s\n' "$output" | grep -F -- "$line" >/dev/null
  done
}

test_cpp() {
  build_image cpp
  echo "Compile C++, run the program, and check gcovr and Valgrind"
  CPP_DIR=$(mktemp -d)
  trap 'rm -rf "$CPP_DIR"' EXIT
  cat >"$CPP_DIR/main.cpp" <<'EOF'
#include <iostream>
int main() {
    std::cout << "cpp-ok" << std::endl;
    return 0;
}
EOF
  docker run --rm -v "$CPP_DIR":/src -w /src "cpp:${IMAGE_TAG}" bash -c '
    set -euo pipefail
    g++ --coverage -o app main.cpp
    ./app
    gcovr
    valgrind --error-exitcode=1 ./app
  '
  rm -rf "$CPP_DIR"
  trap - EXIT
}

test_java() {
  build_image java
  echo "Check Java and Maven versions"
  local output
  output=$(docker run --rm "java:${IMAGE_TAG}" bash -c 'java -version && mvn -version' 2>&1) || { printf '%s\n' "$output" >&2; return 1; }
  expect_lines "$output" 'openjdk version "25' 'Apache Maven 3'
}

test_java_eks() {
  echo "Run Maven tests and check the 95% JaCoCo coverage threshold"
  docker run --rm -v "$ROOT/java-eks":/app -w /app maven:3-amazoncorretto-25 mvn -B verify
  build_image java-eks
  JAVA_EKS_CID=""
  cleanup_java_eks() {
    local status=${1:-0}
    if [[ -n "${JAVA_EKS_CID}" ]]; then
      if [[ "$status" -ne 0 ]]; then
        echo "Application logs after test failure:" >&2
        docker logs "$JAVA_EKS_CID" >&2 || true
      fi
      docker rm -f "$JAVA_EKS_CID" >/dev/null 2>&1 || true
      JAVA_EKS_CID=""
    fi
  }
  trap 'status=$?; cleanup_java_eks "$status" || true; exit "$status"' EXIT
  echo "Start the application and wait for the health endpoint"
  JAVA_EKS_CID=$(docker run -d -p 127.0.0.1::8080 "java-eks:${IMAGE_TAG}")
  local port ready path code
  port=$(docker inspect -f '{{ (index (index .NetworkSettings.Ports "8080/tcp") 0).HostPort }}' "$JAVA_EKS_CID")
  ready=0
  local _
  for _ in $(seq 1 60); do
    if curl -fsS "http://127.0.0.1:${port}/api/health" >/dev/null 2>&1; then
      ready=1
      break
    fi
    sleep 2
  done
  [[ "$ready" -eq 1 ]]
  echo "Check HTTP 200 from health, OpenAPI, and Swagger UI endpoints"
  for path in /api/health /api-docs /swagger-ui/index.html; do
    code=$(curl -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${port}${path}")
    echo "$path $code"
    [[ "$code" == "200" ]]
  done
  cleanup_java_eks
  trap - EXIT
}

test_java_run_swing() {
  build_image java-run-swing
  echo "Compile and run a Swing window with Xvfb"
  SWING_DIR=$(mktemp -d)
  trap 'rm -rf "$SWING_DIR"' EXIT
  local output
  cat >"$SWING_DIR/Hello.java" <<'EOF'
import javax.swing.JFrame;

public class Hello {
    public static void main(String[] args) {
        JFrame frame = new JFrame("Hello");
        frame.setSize(200, 100);
        frame.setVisible(true);
        System.out.println(frame.getClass().getSimpleName());
        System.exit(0);
    }
}
EOF
  docker run --rm -v "$SWING_DIR":/app -w /app "java-run-swing:${IMAGE_TAG}" javac Hello.java
  output=$(docker run --rm -v "$SWING_DIR":/app "java-run-swing:${IMAGE_TAG}" xvfb-run -a java Hello) || { printf '%s\n' "$output" >&2; return 1; }
  printf '%s\n' "$output"
  printf '%s\n' "$output" | grep -F 'JFrame' >/dev/null
  rm -rf "$SWING_DIR"
  trap - EXIT
}

test_java_ui_browser() {
  build_image java-ui-browser
  echo "Check Java, Gradle, Chrome, git, Python, venv, and libatomic"
  local output
  output=$(docker run --rm "java-ui-browser:${IMAGE_TAG}" bash -c 'java --version && gradle --version && google-chrome --version && git --version && python3 --version && python3 -c "import venv, ctypes; ctypes.CDLL(\"libatomic.so.1\")"' 2>&1) || { printf '%s\n' "$output" >&2; return 1; }
  expect_lines "$output" 'openjdk 27' 'Gradle 9.8.2' 'Google Chrome' 'git version' 'Python 3'
}

test_latex() {
  build_image latex
  echo "Compile a Russian LaTeX document and a Boost.Filesystem program"
  LATEX_DIR=$(mktemp -d)
  trap 'rm -rf "$LATEX_DIR"' EXIT
  cat >"$LATEX_DIR/doc.tex" <<'EOF'
\documentclass{article}
\usepackage[T2A]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage[russian]{babel}
\begin{document}
Привет из контейнера.
\end{document}
EOF
  cat >"$LATEX_DIR/boost.cpp" <<'EOF'
#include <boost/filesystem.hpp>
#include <iostream>
int main() {
    std::cout << boost::filesystem::current_path() << std::endl;
    return 0;
}
EOF
  docker run --rm -v "$LATEX_DIR":/work -w /work "latex:${IMAGE_TAG}" bash -c '
    set -euo pipefail
    pdflatex -interaction=nonstopmode -halt-on-error doc.tex
    test -s doc.pdf
    g++ -o boost-app boost.cpp -lboost_filesystem
    ./boost-app
  '
  rm -rf "$LATEX_DIR"
  trap - EXIT
}

test_my_python_app() {
  MY_PYTHON_OVERRIDE=
  cleanup_python_app() {
    local status=${1:-0}
    local -a compose=(docker compose --project-directory "$ROOT" -f "$ROOT/docker-compose.yml" -p my-docker-images-test)
    if [[ "$status" -ne 0 ]]; then
      echo "Compose status and logs after test failure:" >&2
      "${compose[@]}" ps -a >&2 || true
      "${compose[@]}" logs --no-color >&2 || true
    fi
    "${compose[@]}" down -v --remove-orphans >/dev/null 2>&1 || true
    if [[ -n "${MY_PYTHON_OVERRIDE}" ]]; then
      rm -f "$MY_PYTHON_OVERRIDE"
    fi
  }
  trap 'status=$?; cleanup_python_app "$status" || true; exit "$status"' EXIT
  cleanup_python_app
  local -a files=(-f "$ROOT/docker-compose.yml")
  local -a up_options=(--abort-on-container-exit --exit-code-from app)
  local -a build_options=(--build)
  if [[ "$NO_BUILD" -eq 1 ]]; then
    MY_PYTHON_OVERRIDE=$(mktemp)
    cat >"$MY_PYTHON_OVERRIDE" <<EOF
services:
  app:
    image: my-python-app:${IMAGE_TAG}
    pull_policy: never
EOF
    files+=(-f "$MY_PYTHON_OVERRIDE")
    up_options+=(--no-build)
    build_options=()
  fi
  echo "First run: use a new volume"
  docker compose --project-directory "$ROOT" "${files[@]}" \
    -p my-docker-images-test up "${build_options[@]}" "${up_options[@]}"
  echo "Second run: use the same volume"
  docker compose --project-directory "$ROOT" "${files[@]}" \
    -p my-docker-images-test up "${up_options[@]}"
  cleanup_python_app
  trap - EXIT
}

test_python() {
  build_image python
  echo "Check Python, uv, pytest, Behave, Ruff, and mypy versions"
  local output
  output=$(docker run --rm "python:${IMAGE_TAG}" bash -c 'python --version && uv --version && pytest --version && behave --version && ruff --version && mypy --version' 2>&1) || { printf '%s\n' "$output" >&2; return 1; }
  expect_lines "$output" 'Python ' 'uv ' 'pytest ' 'behave ' 'ruff ' 'mypy '
}

test_rust() {
  build_image rust
  echo "Check Rust, Cargo, rustfmt, and Clippy versions"
  local output
  output=$(docker run --rm "rust:${IMAGE_TAG}" bash -c 'rustc --version && cargo --version && rustfmt --version && cargo clippy --version' 2>&1) || { printf '%s\n' "$output" >&2; return 1; }
  expect_lines "$output" 'rustc ' 'cargo ' 'rustfmt ' 'clippy '
}

test_shared() {
  local name=$1
  local -a options=(--rm --entrypoint bash)
  if [[ ! -f "$ROOT/$name/smoke-test.sh" ]]; then
    echo "Missing smoke test: $name/smoke-test.sh" >&2
    return 1
  fi
  build_image "$name"
  if [[ "$name" == web-qa ]]; then
    options+=(--shm-size=1g)
  elif [[ "$name" == postgres-vector-graph ]]; then
    options+=(--user postgres)
  fi
  echo "Run the functional checks in $name/smoke-test.sh"
  docker run "${options[@]}" \
    -v "$ROOT/$name/smoke-test.sh:/tmp/docker-gems-smoke.sh:ro" \
    "$name:${IMAGE_TAG}" /tmp/docker-gems-smoke.sh
}

run_image() {
  local name=$1
  case "$name" in
    cpp) test_cpp ;;
    java) test_java ;;
    java-eks) test_java_eks ;;
    java-run-swing) test_java_run_swing ;;
    java-ui-browser) test_java_ui_browser ;;
    latex) test_latex ;;
    my-python-app) test_my_python_app ;;
    python) test_python ;;
    rust) test_rust ;;
    allure|android|argocd|code-quality|codegraph|compilers|cpp-cuda|cpp-vulkan|crossplane|document-tools|graphify|open-webui|php|postgres-vector-graph|python-media|rust-ci|rust-desktop|rust-node|web-qa)
      test_shared "$name"
      ;;
    *) return 2 ;;
  esac
}

main() {
  local -a images=()
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        usage
        exit 0
        ;;
      --no-build)
        NO_BUILD=1
        IMAGE_TAG=latest
        shift
        ;;
      --)
        shift
        images+=("$@")
        break
        ;;
      -*)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 2
        ;;
      *)
        images+=("$1")
        shift
        ;;
    esac
  done
  command -v docker >/dev/null
  command -v curl >/dev/null
  if ((${#images[@]} == 0)); then
    images=("${ALL[@]}")
  fi
  local name
  for name in "${images[@]}"; do
    if ! is_known "$name"; then
      echo "Unknown image: $name" >&2
      usage >&2
      exit 2
    fi
  done

  local -a failed=()
  local status
  for name in "${images[@]}"; do
    echo "${HEAD_COLOR}===== $name =====${END_COLOR}"
    # Run outside an if condition, so that errexit remains active in each test.
    set +e
    (set -euo pipefail; run_image "$name")
    status=$?
    set -e
    if [[ "$status" -eq 0 ]]; then
      echo "${OK_COLOR}OK $name${END_COLOR}"
    else
      echo "${FAIL_COLOR}FAIL $name${END_COLOR}" >&2
      failed+=("$name")
    fi
  done

  if ((${#failed[@]})); then
    echo "${FAIL_COLOR}Failed images: ${failed[*]}${END_COLOR}" >&2
    exit 1
  fi
  echo "${OK_COLOR}All tests passed.${END_COLOR}"
}

main "$@"
