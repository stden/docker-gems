# stden/rust-desktop

Build and test Rust desktop applications that use GTK 3 and X11.

## Overview

This image contains the current stable Rust toolchain and desktop build libraries.
It includes Cargo, rustfmt, Clippy, LLVM tools, sccache, Tarpaulin, and `cargo-binstall`.
To add a prebuilt Cargo tool in a child image, run `cargo binstall --no-confirm <crate>`.

GTK 3, X11, XCB, libxdo, and OpenSSL headers support native builds.
Xvfb and xauth give a virtual display for tests.
The default working directory is `/workspace`. The default command is Bash.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` | `linux/amd64` |

The `latest` tag changes after a new build passes its tests.
See [all tags and digests](https://hub.docker.com/r/stden/rust-desktop/tags).

## Use

```sh
docker pull stden/rust-desktop:latest
docker run --rm -v "$PWD":/workspace stden/rust-desktop:latest xvfb-run -a cargo test
docker run --rm -v "$PWD":/workspace stden/rust-desktop:latest \
  xvfb-run -a cargo tarpaulin --engine llvm --out Html
```

Run these commands from a project directory that contains `Cargo.toml`.
The virtual display does not open a window on your host screen.

Cargo downloads your project dependencies when necessary. The image does not contain them.
If your application uses extra native libraries, add them in a child image.
Build output and coverage reports stay in the mounted project directory.
Files that the container creates belong to root.

## Checks

The smoke test runs Rust tests, rustfmt, Clippy, and Tarpaulin with its LLVM engine.
It compiles a GTK program and opens its window under Xvfb.

## Source

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/rust-desktop/Dockerfile)
- [Overview source](https://github.com/stden/docker-gems/blob/main/rust-desktop/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
