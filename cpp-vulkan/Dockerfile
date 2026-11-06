FROM ubuntu:latest

# Install the security updates of the base image. The official image can be days
# behind the security repository of the distribution.
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        ccache \
        cmake \
        git \
        glslc \
        libssl-dev \
        libvulkan-dev \
        mesa-vulkan-drivers \
        ninja-build \
        pkg-config \
        spirv-headers \
        spirv-tools \
        vulkan-tools \
    && rm -rf /var/lib/apt/lists/*

# Verify the tools at build time. A missing tool stops the build before publication.
RUN g++ --version && cmake --version && glslc --version

WORKDIR /workspace
CMD ["bash"]
