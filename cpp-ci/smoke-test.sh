#!/usr/bin/env bash
# Build a small CMake project with GCC 14, Ninja, and ccache, then check that the second build
# gets ccache hits. The test is offline and removes its files on exit.
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
export CCACHE_DIR="$work/ccache"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

mkdir src
cat > src/main.cpp <<'SRC'
#include <iostream>
int main() { std::cout << "cpp-ci-ok" << std::endl; }
SRC
cat > CMakeLists.txt <<'SRC'
cmake_minimum_required(VERSION 3.20)
project(smoke CXX)
add_executable(app src/main.cpp)
SRC

configure_and_build() {
    cmake -S . -B "$1" -G Ninja \
        -DCMAKE_C_COMPILER=gcc-14 -DCMAKE_CXX_COMPILER=g++-14 \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache >/dev/null
    cmake --build "$1" >/dev/null
}

configure_and_build build-1
[[ "$(./build-1/app)" == cpp-ci-ok ]] || fail "the program printed the wrong text"
echo "OK: GCC 14, CMake, and Ninja build and run the program"

# A second build in a new directory uses the same sources, so ccache must return cached objects.
configure_and_build build-2
hits=$(ccache --print-stats | awk -F'\t' '/_hit/ { sum += $2 } END { print sum + 0 }')
[[ "$hits" -gt 0 ]] || fail "ccache has no cache hits after a second build"
echo "OK: ccache returned $hits cache hits"

mold --version >/dev/null
echo "OK: mold is available"
echo "All C and C++ build tools work."
