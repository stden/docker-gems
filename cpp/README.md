# stden/cpp

Build C++ programs and check test coverage and memory use.

## Overview

This image uses the official GCC base image.
It includes `g++`, CMake, Git, gcovr, lcov, Valgrind, and tree.
Use it for C++ builds, coverage reports, and memory checks.
When you mount your project, set the working directory with `-w`.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` | `linux/amd64` |

The `latest` tag changes after a new build passes its tests.
See [all tags and digests](https://hub.docker.com/r/stden/cpp/tags).

## Use

Build and check a program from `main.cpp` in your current directory:

```sh
docker pull stden/cpp:latest
docker run --rm -v "$PWD":/workspace -w /workspace stden/cpp:latest \
  bash -c 'g++ --coverage -g -O0 main.cpp -o app && ./app && gcovr --root . && valgrind --error-exitcode=1 ./app'
```

For a CMake project:

```sh
docker run --rm -v "$PWD":/workspace -w /workspace stden/cpp:latest \
  bash -c 'cmake -S . -B build && cmake --build build && ctest --test-dir build --output-on-failure'
```

The image does not include project libraries. Install extra dependencies in a child image.
For example, if your project uses Boost.Filesystem, add `libboost-filesystem-dev`.
Build output and coverage files stay in the mounted project directory.
Files that the container creates belong to root.

## Checks

The smoke test compiles a C++ program with coverage enabled.
It runs the program, generates a gcovr report, and runs Valgrind with an error exit code.

## Source

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/cpp/Dockerfile)
- [Overview source](https://github.com/stden/docker-gems/blob/main/cpp/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
