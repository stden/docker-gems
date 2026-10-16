# Install the Rust compiler, Cargo, rustfmt, and Clippy.
FROM rust:latest

RUN rustup component add rustfmt clippy \
    && rustc --version \
    && cargo --version \
    && rustfmt --version \
    && cargo clippy --version

WORKDIR /workspace
CMD ["bash"]
