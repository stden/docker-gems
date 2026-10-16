# stden/cpp-cuda

Build C++ and CUDA programs with the NVIDIA CUDA development toolkit.

## Overview

This image uses the NVIDIA CUDA development image for Ubuntu.
It includes `nvcc`, C++ build tools, CMake, Ninja, ccache, Git, and OpenSSL headers.
You can compile and link CUDA programs without a GPU.
The default working directory is `/workspace`. The default command is Bash.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` | `linux/amd64` |

The `latest` tag changes after a new build passes its tests.
See [all tags and digests](https://hub.docker.com/r/stden/cpp-cuda/tags).
See the [Dockerfile](https://github.com/stden/docker-gems/blob/main/cpp-cuda/Dockerfile)
for the CUDA version of the current build.

## Use

Compile `main.cu` in your current directory:

```sh
docker pull stden/cpp-cuda:latest
docker run --rm -v "$PWD":/workspace stden/cpp-cuda:latest nvcc main.cu -o app
```

To run the program on a GPU, install a compatible NVIDIA driver and the NVIDIA Container Toolkit
on the Docker host. Then run this command:

```sh
docker run --rm --gpus all -v "$PWD":/workspace stden/cpp-cuda:latest ./app
```

Install extra project dependencies in a child image.
Build output stays in the mounted project directory.
Files that the container creates belong to root.
Before you run GPU code, check that the host driver supports the CUDA version.

## Checks

The smoke test compiles and links a real CUDA kernel. It also runs a host C++ program.
It does not run a GPU kernel. The standard CI runner does not test physical GPU operation.

## Source

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/cpp-cuda/Dockerfile)
- [Overview source](https://github.com/stden/docker-gems/blob/main/cpp-cuda/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
