# Build and test Rust applications that use GTK and X11.
FROM rust:latest

ARG BINSTALL_VERSION=1.26.1

# Install the security updates of the base image before the tools. The official image
# can be days behind the security repository of the distribution.
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl git libatk1.0-dev libcairo2-dev \
        libgdk-pixbuf-2.0-dev libglib2.0-dev libgtk-3-dev libpango1.0-dev \
        libssl-dev libx11-dev libxcb-render0-dev libxcb-shape0-dev \
        libxcb-xfixes0-dev libxcb1-dev libxdo-dev pkg-config xauth xvfb \
    && rm -rf /var/lib/apt/lists/* \
    && rustup component add rustfmt clippy llvm-tools-preview

# Check the installer archive against the official release checksum.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
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
    cargo binstall --no-confirm --disable-telemetry --strategies crate-meta-data,compile sccache cargo-tarpaulin

WORKDIR /workspace
CMD ["bash"]
