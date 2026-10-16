# stden/rust-node

Build and test projects that use Rust and Node.js.

## Overview

This image contains the current stable Rust and Node.js tools.
It includes Cargo, rustfmt, Clippy, npm, npx, CMake, Git, and native build tools.
OpenSSL headers and `pkg-config` support native dependencies.
The default working directory is `/workspace`. The default command is Bash.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` | `linux/amd64` |

The `latest` tag changes after a new build passes its tests.
See [all tags and digests](https://hub.docker.com/r/stden/rust-node/tags).

## Use

```sh
docker pull stden/rust-node:latest
docker run --rm -v "$PWD":/workspace stden/rust-node:latest \
  bash -c 'cargo test && npm ci && npm test'
```

Run this example from a project directory with `Cargo.toml`, `package.json`, and `package-lock.json`.
The npm project must define a `test` script. For separate frontend and backend directories,
change the commands to enter each directory first.

Cargo and npm download your project dependencies when necessary. The image does not contain them.
Build output stays in the mounted project directory.
Files that the container creates belong to root.

## Checks

The smoke test runs Rust tests, rustfmt, Clippy, and a Node.js test.
It also compiles and runs a program that uses OpenSSL.

## Source

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/rust-node/Dockerfile)
- [Overview source](https://github.com/stden/docker-gems/blob/main/rust-node/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
