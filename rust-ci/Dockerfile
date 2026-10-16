# Build and test Rust projects with current stable tools.
FROM rust:latest

ARG BINSTALL_VERSION=1.26.1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential ca-certificates clang curl git jq libssl-dev lld mold pkg-config \
    && rm -rf /var/lib/apt/lists/* \
    && rustup component add rustfmt clippy llvm-tools-preview

# Check the installer archive against the official release checksum.
RUN set -eu; \
    case "$(uname -m)" in \
        x86_64) binstall_sha=43d379fef8cb450961a14ff113e7bce7b5e1e52db709c776d186f928d8a20a40 ;; \
        aarch64) binstall_sha=243dbea9976495f0a5640f856283b5b3d934113381c9a1fba347c9e4b1fea142 ;; \
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
