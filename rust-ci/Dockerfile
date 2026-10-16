# Build and test Rust projects with current stable tools.
FROM rust:latest

ARG BINSTALL_VERSION=1.26.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential ca-certificates clang curl git jq libssl-dev lld mold pkg-config \
    && rm -rf /var/lib/apt/lists/* \
    && rustup component add rustfmt clippy llvm-tools-preview

# Check the installer archive against the official release checksum.
RUN set -eu; \
    case "$(uname -m)" in \
        x86_64) binstall_sha=dd7ff9451d8ba2e437a8d861889b630746f82f09d931df2d893b0c3f28656f87 ;; \
        aarch64) binstall_sha=4c7fdaa9fb6803ef66d282dfb671dc81f36fc03d469fb9a177b4aa4fade6b91b ;; \
        *) echo "Unsupported CPU architecture." >&2; exit 1 ;; \
    esac; \
    curl -fsSL --retry 3 \
        "https://github.com/cargo-bins/cargo-binstall/releases/download/v${BINSTALL_VERSION}/cargo-binstall-$(uname -m)-unknown-linux-musl.tgz" \
        -o /tmp/binstall.tgz; \
    echo "$binstall_sha  /tmp/binstall.tgz" | sha256sum -c -; \
    tar -xzf /tmp/binstall.tgz -C /usr/local/cargo/bin cargo-binstall; \
    rm /tmp/binstall.tgz; \
    cargo binstall --no-confirm --strategies crate-meta-data,compile sccache cargo-nextest cargo-audit

# Install prebuilt coverage, policy, database, and mutation tools. Do not compile them.
# sqlx-cli has no upstream release binaries. Use the signed cargo-quickinstall build.
RUN cargo binstall --no-confirm --strategies crate-meta-data \
        cargo-tarpaulin cargo-llvm-cov cargo-deny cargo-mutants \
    && cargo binstall --no-confirm --only-signed --disable-telemetry --strategies quick-install sqlx-cli

WORKDIR /workspace
CMD ["bash"]
