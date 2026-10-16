# NVIDIA publishes CUDA development images with versioned tags.
# https://hub.docker.com/r/nvidia/cuda/tags?name=devel-ubuntu26.04
FROM nvidia/cuda:13.4.3-devel-ubuntu26.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        ccache \
        cmake \
        git \
        libssl-dev \
        ninja-build \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["bash"]
