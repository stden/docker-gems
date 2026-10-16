# stden/rust

Build, test, format, and lint Rust projects.

## Overview

This image contains the current stable Rust toolchain from the official Rust base image.
It includes `rustc`, Cargo, rustfmt, and Clippy.
The default working directory is `/workspace`. The default command is Bash.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` | `linux/amd64` |

The `latest` tag changes after a new build passes its tests.
See [all tags and digests](https://hub.docker.com/r/stden/rust/tags).

## Use

```sh
docker pull stden/rust:latest
docker run --rm -v "$PWD":/workspace stden/rust:latest cargo test
docker run --rm -v "$PWD":/workspace stden/rust:latest cargo fmt --check
docker run --rm -v "$PWD":/workspace stden/rust:latest cargo clippy --all-targets -- -D warnings
```

Run these commands from a project directory that contains `Cargo.toml`.
Cargo downloads your project dependencies when necessary. The image does not contain them.
Build output stays in the mounted project directory.
Files that the container creates belong to root.

## Checks

The smoke test checks the Rust compiler, Cargo, rustfmt, and Clippy commands.

## Source

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/rust/Dockerfile)
- [Overview source](https://github.com/stden/docker-gems/blob/main/rust/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
