# stden/compilers

Compile Hello, world! examples in seven languages and check PDF output with two LaTeX engines.

## Overview

This image contains GNU C, GNU C++, Mono C#, DMD for D, GHC for Haskell, Free Pascal, and Python.
Python runs from a virtual environment with NumPy and pandas.
The image also has pdfLaTeX, LuaLaTeX, PDF text tools, git, curl, wget, and tree.

The base image is `debian:stable-slim`.
The `WORKDIR` is `/x`.
The default command compiles each example and checks its output.

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

Each program must print `Hello, world!`.
Both LaTeX engines must create a PDF with the same text.
The runner stops if a compiler fails, a program fails, or the result is incorrect.
The runner deletes all temporary files after each run.

| Language or format | Tool | Example |
| --- | --- | --- |
| C | GCC | [hw_c.c](https://github.com/stden/docker-gems/blob/main/compilers/hw_c.c) |
| C++ | G++ | [hw_cpp.cpp](https://github.com/stden/docker-gems/blob/main/compilers/hw_cpp.cpp) |
| C# | Mono C# and Mono | [hw.cs](https://github.com/stden/docker-gems/blob/main/compilers/hw.cs) |
| D | DMD | [hw_d.d](https://github.com/stden/docker-gems/blob/main/compilers/hw_d.d) |
| Haskell | GHC | [hw_haskell.hs](https://github.com/stden/docker-gems/blob/main/compilers/hw_haskell.hs) |
| Pascal | Free Pascal | [hw_pascal.pas](https://github.com/stden/docker-gems/blob/main/compilers/hw_pascal.pas) |
| Python | Python 3 | [hw_python.py](https://github.com/stden/docker-gems/blob/main/compilers/hw_python.py) |
| PDF | pdfLaTeX and LuaLaTeX | [hw_latex.tex](https://github.com/stden/docker-gems/blob/main/compilers/hw_latex.tex) |

Expected output:

```text
== Program in C ==
Hello, world!
PASS C
== Program in C++ ==
Hello, world!
PASS C++
== Program in C# ==
Hello, world!
PASS C#
== Program in D ==
Hello, world!
PASS D
== Program in Haskell ==
Hello, world!
PASS Haskell
== Program in Pascal ==
Hello, world!
PASS Pascal
== Program in Python ==
Hello, world!
PASS Python
== Program in pdfLaTeX ==
Hello, world!
PASS pdfLaTeX
== Program in LuaLaTeX ==
Hello, world!
PASS LuaLaTeX
```

## Compile your own code

Mount your source directory at `/workspace`.
Select it with `-w /workspace`.
The sample programs stay available under `/x`.

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

For a Haskell source file named `main.hs`:

```sh
docker run --rm -v "$PWD":/workspace -w /workspace stden/compilers:latest \
  bash -c 'ghc -o app main.hs && ./app'
```

Start an interactive shell to use the other compilers:

```sh
docker run --rm -it -v "$PWD":/workspace -w /workspace \
  stden/compilers:latest bash
```

New files in `/workspace` stay in the host directory.
If the included tools are not sufficient, install extra project dependencies in a child image.

## Source and checks

The smoke test runs the examples and checks all nine results.
Both CI runners use this test.
The regression test checks compile failures, runtime failures, incorrect text, PDF failures, and temporary file cleanup.

From the repository root, build the image and test every result:

```sh
./test-images.sh compilers
```

Run the runner regression test without Docker:

```sh
bash ci/test-compilers.sh
```

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/compilers/Dockerfile)
- [Example runner](https://github.com/stden/docker-gems/blob/main/compilers/test.sh)
- [Smoke test](https://github.com/stden/docker-gems/blob/main/compilers/smoke-test.sh)
- [Runner regression test](https://github.com/stden/docker-gems/blob/main/ci/test-compilers.sh)
- [Overview source](https://github.com/stden/docker-gems/blob/main/compilers/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
