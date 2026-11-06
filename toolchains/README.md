# stden/toolchains

Compilers and interpreters in one image: C++, Java, JavaScript, Python, Go, Perl, PHP, Ruby.

## What you learn

You learn to run the code of several languages in one Docker container, without installing each one.

## Overview

This image runs the programs of several languages on a computer or in a CI job. It contains:

- GCC 13 (`g++`) for C++.
- OpenJDK 21 (`javac`, `java`) for Java.
- Node.js 18 for JavaScript.
- Python 3.12 (`python3`). The image has no `pip`.
- Perl 5.38, PHP 8.3 CLI, Ruby 3.2, and Go 1.22.
- `git` 2.43, which reads the history of a repository.

The base image is `ubuntu:24.04`, the same release as the `ubuntu-latest` runner of GitHub Actions.
The image has the security updates of the base image at build time. The working directory is
`/workspace`. The default command starts Bash.

## Tags

| Tag | Meaning | Platform |
|-----|---------|----------|
| `latest` | Newest build of Ubuntu 24.04 with the toolchains | `linux/amd64` |

## Run the image

Mount the repository in `/workspace` and run the check script:

```bash
docker run --rm -v "$PWD":/workspace -w /workspace stden/toolchains \
  python3 --version
```
