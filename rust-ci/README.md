# stden/rust-ci

Run Rust tests, coverage, mutation tests, code and license checks, and cached builds in CI.

## Overview

This image adds CI tools to the current stable Rust toolchain:

- Cargo, rustfmt, Clippy, and LLVM coverage tools.
- Nextest to run tests and `cargo-audit` to check dependencies.
- `cargo-llvm-cov` and `cargo-tarpaulin` to measure test coverage.
- `cargo-deny` to check licenses, banned crates, crate sources, and advisories.
- `sqlx-cli` (`cargo sqlx` and `sqlx`) to manage SQLx migrations and offline query data.
- `cargo-mutants` to find code that the tests do not check.
- sccache to cache compiler output.
- Clang, LLD, mold, Git, jq, OpenSSL headers, and `pkg-config`.

The Cargo tools are prebuilt binaries. A CI job does not compile them.
The image installs them with `cargo-binstall`, and this installer stays in the image.
To add a prebuilt Cargo tool in a child image, run `cargo binstall --no-confirm <crate>`.
The default working directory is `/workspace`. The default command is Bash.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` | `linux/amd64` |

The `latest` tag changes after a new build passes its tests.
See [all tags and digests](https://hub.docker.com/r/stden/rust-ci/tags).

## Use

```sh
docker pull stden/rust-ci:latest
docker run --rm -v "$PWD":/workspace stden/rust-ci:latest \
  bash -c 'cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo nextest run'
docker run --rm -v "$PWD":/workspace stden/rust-ci:latest cargo audit
```

Run these commands from a project directory that contains `Cargo.toml`.
`cargo audit` checks `Cargo.lock`. It must have access to the advisory database.
Cargo downloads your project dependencies when necessary. The image does not contain them.

Use a named volume to keep the compiler cache between runs:

```sh
docker run --rm -v "$PWD":/workspace -v rust-ci-cache:/cache \
  -e RUSTC_WRAPPER=sccache -e SCCACHE_DIR=/cache -e CARGO_INCREMENTAL=0 \
  stden/rust-ci:latest cargo build --release
```

Build output stays in the mounted project directory.
Files that the container creates belong to root.
The image contains LLD and mold. If necessary, configure your project to select a linker.

### Coverage

```sh
docker run --rm -v "$PWD":/workspace stden/rust-ci:latest \
  cargo llvm-cov --lcov --output-path lcov.info --fail-under-lines 80
docker run --rm -v "$PWD":/workspace stden/rust-ci:latest \
  cargo tarpaulin --engine llvm --out Xml --fail-under 80
```

`cargo llvm-cov --summary-only` prints a coverage table. Tarpaulin writes `cobertura.xml`.
Use the LLVM engine of Tarpaulin in a container.
For its default ptrace engine, `--security-opt seccomp=unconfined` is necessary.

### Licenses and banned crates

```sh
docker run --rm -v "$PWD":/workspace stden/rust-ci:latest cargo deny init
docker run --rm -v "$PWD":/workspace stden/rust-ci:latest cargo deny check licenses bans sources
docker run --rm -v "$PWD":/workspace stden/rust-ci:latest cargo deny check advisories
```

`cargo deny init` writes a `deny.toml` template. Edit the policy before you use it.
The `advisories` check downloads the RustSec advisory database.
The `licenses`, `bans`, and `sources` checks do not use it.
If Cargo already has the dependencies, add `--offline` (`cargo deny --offline check licenses bans`).

### Database migrations

```sh
docker run --rm -v "$PWD":/workspace stden/rust-ci:latest cargo sqlx migrate add create_users
docker run --rm -v "$PWD":/workspace -e DATABASE_URL stden/rust-ci:latest \
  bash -c 'cargo sqlx migrate run && cargo sqlx prepare --check'
```

The commands that connect to a database read `DATABASE_URL`.
The tool supports PostgreSQL, MySQL, and SQLite.
`cargo sqlx prepare --check` fails when the query data in `.sqlx` is out of date.
The SQLx project does not publish binaries, so the image uses the signed
[cargo-quickinstall](https://github.com/cargo-bins/cargo-quickinstall) build.

### Mutation tests

```sh
docker run --rm -v "$PWD":/workspace stden/rust-ci:latest cargo mutants --list
docker run --rm -v "$PWD":/workspace stden/rust-ci:latest cargo mutants --test-tool nextest
```

`cargo mutants --list` shows the mutants and does not run them.
`cargo mutants` changes the code one mutant at a time and runs the tests.
It writes the results to `mutants.out`. A full run can take a long time.

## Checks

The smoke test runs Nextest, rustfmt, Clippy, and a real compiler cache check.
It checks the LLVM tools and compiles programs with LLD and mold.
It measures coverage with `cargo llvm-cov` and with the LLVM engine of Tarpaulin.
It checks that `cargo-deny` rejects a license that is not allowed and accepts an allowed license.
It applies an SQLx migration to an SQLite file and lists mutants with `cargo-mutants`.
It checks the `cargo-audit` command, but it does not download an advisory database.

The smoke test does not use the network.

## Source

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/rust-ci/Dockerfile)
- [Overview source](https://github.com/stden/docker-gems/blob/main/rust-ci/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
