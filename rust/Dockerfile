# Base image: rust:1.100.0 ships the stable compiler and rustup.
# rustup is the toolchain manager; it installs optional components from the same channel.
FROM rust:1.100.0

# rustfmt and clippy are optional toolchain components not in the default install.
# rustup component add fetches them from the same channel as the compiler.
RUN rustup component add rustfmt clippy \
    && rustc --version \
    && cargo --version \
    && rustfmt --version \
    && cargo clippy --version

WORKDIR /workspace
CMD ["bash"]
