# Build C and C++ projects in CI: GCC 14, CMake, Ninja, ccache, and mold.
# Ubuntu 24.04 matches the ubuntu-24.04 runner of GitHub Actions. The image has the CPU build
# tools of projects such as llama.cpp. GPU SDKs are not in this image.
FROM ubuntu:26.04

# Install security updates of the base image, then the build tools. The default cc stays GCC 13,
# so a job that needs GCC 14 must call gcc-14 and g++-14 by name.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates build-essential gcc-14 g++-14 cmake ninja-build ccache mold \
      pkg-config libssl-dev jq python3-venv git && \
    rm -rf /var/lib/apt/lists/*

# Verify the tools at build time. A missing tool stops the build before publication.
RUN gcc-14 --version && g++-14 --version && cmake --version && ninja --version && \
    ccache --version && mold --version

WORKDIR /workspace
CMD ["bash"]
