FROM ubuntu:latest

RUN apt-get update \
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
