#!/bin/sh
# Smoke-test one image after Kaniko builds it and before the job publishes it.
# Usage: test-built-image.sh NAME ARCHIVE ROOTFS
# ARCHIVE is a Kaniko --tarPath file. The command exits non-zero when the check fails.
set -eu

if [ $# -ne 3 ]; then
  echo "usage: test-built-image.sh NAME ARCHIVE ROOTFS" >&2
  exit 2
fi

NAME=$1
ARCHIVE=$2
ROOT=$3
META=$(dirname "$ROOT")/meta
HERE=$(cd "$(dirname "$0")" && pwd)

sh "$HERE/extract-image.sh" "$ARCHIVE" "$ROOT" "$META"

server_pid=
# The server runs under proot, several processes below the recorded shell.
# Kill the whole tree, so that Java does not continue to listen after a failed check.
# Record the process and every descendant. Then signal the descendants first.
kill_tree() {
  list=$META/kill.list
  printf '%s\n' "$1" > "$list"
  added=1
  while [ "$added" -eq 1 ]; do
    added=0
    proc=
    ppid=
    for proc in /proc/[0-9]*; do
      proc=${proc#/proc/}
      ppid=$(awk '/^PPid:/ {print $2}' "/proc/$proc/status" 2>/dev/null || true)
      [ -n "$ppid" ] || continue
      if grep -qx "$ppid" "$list" && ! grep -qx "$proc" "$list"; then
        printf '%s\n' "$proc" >> "$list"
        added=1
      fi
    done
  done
  set --
  while IFS= read -r proc; do
    set -- "$proc" "$@"
  done < "$list"
  for proc in "$@"; do
    kill "$proc" 2>/dev/null || true
  done
  rm -f "$list"
}
cleanup() {
  if [ -n "$server_pid" ]; then
    kill_tree "$server_pid"
    wait "$server_pid" 2>/dev/null || true
    server_pid=
  fi
}
trap cleanup EXIT

run() {
  sh "$HERE/run-rootfs.sh" "$ROOT" "$META" "$@"
}

# Keep the command output when the check fails. A bare $(...) drops it under set -e.
capture() {
  output=$(run "$@" 2>&1) || {
    printf '%s\n' "$output" >&2
    exit 1
  }
}

expect_out() {
  text=$1
  shift
  printf '%s\n' "$text"
  needle=
  for needle in "$@"; do
    printf '%s\n' "$text" | grep -F -- "$needle" >/dev/null || {
      echo "Missing text: $needle" >&2
      exit 1
    }
  done
}

case $NAME in
  postgres-vector-graph)
    user=$(awk -F: '$1 == "postgres" { print $3 ":" $4 }' "$ROOT/etc/passwd")
    [ -n "$user" ]
    run --user "$user" --bind "$HERE/../$NAME/smoke-test.sh:/tmp/docker-gems-smoke.sh" \
      -- bash /tmp/docker-gems-smoke.sh
    ;;
  allure|android|argocd|code-quality|codegraph|compilers|cpp-cuda|cpp-vulkan|crossplane|document-tools|graphify|open-webui|php|python-media|rust-ci|rust-desktop|rust-node|web-qa)
    run --bind "$HERE/../$NAME/smoke-test.sh:/tmp/docker-gems-smoke.sh" \
      -- bash /tmp/docker-gems-smoke.sh
    ;;
  cpp)
    src=$(mktemp -d)
    cat > "$src/main.cpp" <<'EOF'
#include <iostream>
int main() {
    std::cout << "cpp-ok" << std::endl;
    return 0;
}
EOF
    run --bind "$src:/src" --workdir /src -- bash -c '
      set -euo pipefail
      g++ --coverage -o app main.cpp
      ./app
      gcovr
      valgrind --error-exitcode=1 ./app
    '
    rm -rf "$src"
    ;;
  java)
    capture -- bash -c 'java -version && mvn -version'
    expect_out "$output" 'openjdk version "25' 'Apache Maven 3'
    ;;
  java-17)
    capture -- bash -c 'java -version && mvn -version && git --version && curl --version && jq --version'
    expect_out "$output" 'openjdk version "17' 'Apache Maven 3' 'git version' 'curl' 'jq-'
    ;;
  java-eks)
    # The shell inside the image expands JAVA_OPTS.
    # shellcheck disable=SC2016
    run -- sh -c 'exec java $JAVA_OPTS -jar app.jar' > "$META/server.log" 2>&1 &
    server_pid=$!
    ready=0
    i=0
    while [ "$i" -lt 60 ]; do
      if wget -q -O /dev/null "http://127.0.0.1:8080/api/health"; then
        ready=1
        break
      fi
      i=$((i + 1))
      sleep 2
    done
    if [ "$ready" -ne 1 ]; then
      echo "java-eks did not answer /api/health" >&2
      cat "$META/server.log" >&2 || true
      exit 1
    fi
    path=
    for path in /api/health /api-docs /swagger-ui/index.html; do
      code=$(curl -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:8080$path")
      echo "$path $code"
      [ "$code" = "200" ]
    done
    cleanup
    ;;
  java-run-swing)
    src=$(mktemp -d)
    cat > "$src/Hello.java" <<'EOF'
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
    run --bind "$src:/work" --workdir /work -- javac Hello.java
    capture --bind "$src:/work" --workdir /work -- xvfb-run -a java Hello
    printf '%s\n' "$output"
    printf '%s\n' "$output" | grep -F 'JFrame' >/dev/null
    rm -rf "$src"
    ;;
  java-ui-browser)
    capture -- bash -c 'java --version && gradle --version && google-chrome --version && git --version && python3 --version && python3 -c "import venv, ctypes; ctypes.CDLL(\"libatomic.so.1\")"'
    expect_out "$output" 'openjdk 27' 'Gradle 9.8.2' 'Google Chrome' 'git version' 'Python 3'
    ;;
  latex)
    src=$(mktemp -d)
    cat > "$src/doc.tex" <<'EOF'
\documentclass{article}
\usepackage[T2A]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage[russian]{babel}
\begin{document}
Привет из контейнера.
\end{document}
EOF
    cat > "$src/boost.cpp" <<'EOF'
#include <boost/filesystem.hpp>
#include <iostream>
int main() {
    std::cout << boost::filesystem::current_path() << std::endl;
    return 0;
}
EOF
    run --bind "$src:/work" --workdir /work -- bash -c '
      set -euo pipefail
      pdflatex -interaction=nonstopmode -halt-on-error doc.tex
      test -s doc.pdf
      g++ -o boost-app boost.cpp -lboost_filesystem
      ./boost-app
    '
    rm -rf "$src"
    ;;
  my-python-app)
    # docker compose must have a daemon. The runner does not have one.
    # The local test-images.sh script runs the compose check.
    echo "CI checks Python imports. The compose check runs in test-images.sh."
    run -- python -c 'import requests, mysql.connector'
    run -- python -m py_compile my-test.py my-sql-test.py
    ;;
  python)
    capture -- bash -c 'python --version && uv --version && pytest --version && behave --version && ruff --version && mypy --version'
    expect_out "$output" 'Python ' 'uv ' 'pytest ' 'behave ' 'ruff ' 'mypy '
    ;;
  rust)
    capture -- bash -c 'rustc --version && cargo --version && rustfmt --version && cargo clippy --version'
    expect_out "$output" 'rustc ' 'cargo ' 'rustfmt ' 'clippy '
    ;;
  kafka|mailpit|minio|rabbitmq|wiremock)
    # These images run as network daemons. PRoot cannot start them.
    # The local test-images.sh script runs the full check.
    echo "CI skips the daemon check for $NAME. Run test-images.sh for the full check."
    ;;
  *)
    echo "Unknown image: $NAME" >&2
    exit 2
    ;;
esac

echo "OK $NAME"
