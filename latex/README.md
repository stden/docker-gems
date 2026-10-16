# stden/latex

Build LaTeX documents and check C++ code with coverage and memory tools.

## Overview

This image starts from the full `texlive/texlive:latest` distribution. It also
contains GNU C++, CMake, Boost.Filesystem development files, gcovr, lcov,
Valgrind, Git, sshpass, and tree.

Use it for LaTeX course documents and for projects that have documents and C++
examples. The full TeX Live distribution makes this a large image.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main`. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/latex/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/latex:latest
```

## Compile a document

Run the command from the directory that contains `document.tex`. Set the working
directory explicitly, so that TeX can find the mounted source files:

```sh
docker run --rm -v "$PWD":/workspace -w /workspace stden/latex:latest \
  pdflatex -interaction=nonstopmode -halt-on-error document.tex
```

The PDF, log, and auxiliary files stay in the host directory. If another pass is
necessary for cross-references, run the command again.

## Compile C++ with Boost.Filesystem

Run this command from a project directory that contains `main.cpp`:

```sh
docker run --rm -v "$PWD":/workspace -w /workspace stden/latex:latest \
  bash -c 'g++ main.cpp -lboost_filesystem -o app && ./app'
```

The mount saves the compiled executable on the host. Add the project libraries
and build commands that your source code uses.

## Source and checks

The smoke test creates a PDF with Russian text to check language support. It
also compiles and links a C++ program with Boost.Filesystem.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/latex/Dockerfile)
- [Overview source](https://github.com/stden/docker-gems/blob/main/latex/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
