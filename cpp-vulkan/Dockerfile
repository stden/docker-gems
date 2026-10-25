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

WORKDIR /workspace
CMD ["bash"]
