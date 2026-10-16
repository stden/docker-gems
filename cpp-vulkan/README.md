# stden/cpp-vulkan

Build C++ Vulkan programs and compile shaders for tests without a physical GPU.

## Overview

This Ubuntu image includes C++ build tools, CMake, Ninja, ccache, Git, and OpenSSL headers.
It also includes Vulkan headers and tools, `glslc`, SPIR-V tools, and Mesa Vulkan drivers.
Mesa has a CPU driver for tests on hosts without a GPU.
The default working directory is `/workspace`. The default command is Bash.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` | `linux/amd64` |

The `latest` tag changes after a new build passes its tests.
See [all tags and digests](https://hub.docker.com/r/stden/cpp-vulkan/tags).

## Use

Compile a compute shader from `shader.comp` in your current directory:

```sh
docker pull stden/cpp-vulkan:latest
docker run --rm -v "$PWD":/workspace stden/cpp-vulkan:latest \
  glslc --target-env=vulkan1.2 shader.comp -o shader.spv
docker run --rm -v "$PWD":/workspace stden/cpp-vulkan:latest \
  spirv-val --target-env vulkan1.2 shader.spv
```

Build a CMake project:

```sh
docker run --rm -v "$PWD":/workspace stden/cpp-vulkan:latest \
  bash -c 'cmake -S . -B build -G Ninja && cmake --build build'
```

Install extra project dependencies in a child image.
Build output stays in the mounted project directory.
Files that the container creates belong to root.
For access to a physical GPU, a compatible host driver and device configuration are necessary.
The smoke test does not check access to a physical GPU.

## Checks

The smoke test compiles and validates a shader.
It builds a C++ Vulkan program and finds the Mesa CPU device.

## Source

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/cpp-vulkan/Dockerfile)
- [Overview source](https://github.com/stden/docker-gems/blob/main/cpp-vulkan/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
