# stden/compilers

Compile and run small programs in C++, C#, D, Pascal, and Python.

## Overview

This image contains GNU C++, Mono C#, DMD for D, Free Pascal, and Python.
Python runs from a virtual environment with NumPy and pandas. The image also
includes LaTeX tools, git, curl, wget, tree, and sample programs for five languages.

The base image is `debian:stable-slim`. The working directory is `/x`.
The default command compiles and runs the sample programs in that directory.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main`. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/compilers/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/compilers:latest
```

## Run the sample programs

```sh
docker run --rm stden/compilers:latest
```

The command shows the output from the Pascal, C++, D, C#, and Python programs.

## Compile your own code

Mount your source directory at `/workspace` and select it as the working
directory. This keeps the sample programs available under `/x`.

For a C++ source file named `main.cpp`:

```sh
docker run --rm -v "$PWD":/workspace -w /workspace stden/compilers:latest \
  bash -c 'g++ main.cpp -o app && ./app'
```

For a Python source file named `main.py`:

```sh
docker run --rm -v "$PWD":/workspace -w /workspace stden/compilers:latest \
  python main.py
```

Start an interactive shell to use the other compilers:

```sh
docker run --rm -it -v "$PWD":/workspace -w /workspace \
  stden/compilers:latest bash
```

New files in `/workspace` stay in the host directory. If the included tools are not
enough, install extra project dependencies in a child image.

## Source and checks

The smoke test runs the sample programs and checks that all five languages
produce output.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/compilers/Dockerfile)
- [Example runner](https://github.com/stden/docker-gems/blob/main/compilers/test.sh)
- [Overview source](https://github.com/stden/docker-gems/blob/main/compilers/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
