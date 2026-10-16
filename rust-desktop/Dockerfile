# Build and test Rust applications that use GTK and X11.
FROM rust:latest

ARG BINSTALL_VERSION=1.26.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl git libatk1.0-dev libcairo2-dev \
        libgdk-pixbuf-2.0-dev libglib2.0-dev libgtk-3-dev libpango1.0-dev \
        libssl-dev libx11-dev libxcb-render0-dev libxcb-shape0-dev \
        libxcb-xfixes0-dev libxcb1-dev libxdo-dev pkg-config xauth xvfb \
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
    cargo binstall --no-confirm --strategies crate-meta-data,compile sccache cargo-tarpaulin

WORKDIR /workspace
CMD ["bash"]
