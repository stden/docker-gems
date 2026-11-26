# stden/cpp-ci

Build C and C++ projects in CI with GCC 14, CMake, Ninja, ccache, and mold.

## What you learn

You learn to build a C or C++ project in a Docker container, with a compiler cache.

## Overview

This image builds C and C++ projects on a computer or in a CI job. It contains:

- GCC 14 (`gcc-14`, `g++-14`) and the default `build-essential` tools. The default `cc` is GCC 13.
- [CMake](https://cmake.org/) and [Ninja](https://ninja-build.org/) for the build.
- [ccache](https://ccache.dev/) to reuse compiled objects between builds.
- [mold](https://github.com/rui314/mold), a fast linker.
- `pkg-config`, the OpenSSL headers (`libssl-dev`), `jq`, `git`, and `python3-venv`.

The base image is `ubuntu:24.04`, the same release as the `ubuntu-24.04` runner of GitHub Actions.
The image does not contain GPU SDKs such as CUDA, ROCm, or SYCL. The working directory is
`/workspace`. The default command starts Bash.

## Run the image

Mount the project in `/workspace` and configure it with GCC 14:

```bash
docker run --rm -v "$PWD":/workspace -w /workspace stden/cpp-ci bash -c \
  'cmake -S . -B build -G Ninja -DCMAKE_C_COMPILER=gcc-14 -DCMAKE_CXX_COMPILER=g++-14 && cmake --build build'
```
