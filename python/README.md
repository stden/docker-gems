# stden/python

Test and check Python code with uv, pytest, Behave, Ruff, and mypy.

## Overview

This image contains Python, pip, uv, pytest, Behave, Ruff, and mypy. Use it for course
tasks, local checks, and CI jobs. The base image is `python:latest`. The working directory is
`/workspace`. The default command starts Bash.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main`. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/python/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/python:latest
```

## Run tests

Run these commands from your project directory:

```sh
docker run --rm -v "$PWD":/workspace stden/python:latest pytest
docker run --rm -v "$PWD":/workspace stden/python:latest behave
docker run --rm -v "$PWD":/workspace stden/python:latest ruff check .
docker run --rm -v "$PWD":/workspace stden/python:latest mypy .
```

The image does not include your project dependencies. If your project has a requirements
file, install them before the tests:

```sh
docker run --rm -v "$PWD":/workspace stden/python:latest \
  bash -c 'python -m pip install -r requirements.txt && pytest'
```

For a project with `pyproject.toml` and `uv.lock`, uv installs the locked
dependencies in a few seconds:

```sh
docker run --rm -v "$PWD":/workspace stden/python:latest \
  bash -c 'uv sync --frozen && uv run pytest'
```

The mount keeps reports and other output in your project directory. Packages that
you install in this container do not stay after the container exits. For repeated
use, install your dependencies in a Dockerfile that starts with
`FROM stden/python:latest`.

## Source and checks

The image smoke test checks Python, uv, pytest, Behave, Ruff, and mypy.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/python/Dockerfile)
- [Overview source](https://github.com/stden/docker-gems/blob/main/python/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
