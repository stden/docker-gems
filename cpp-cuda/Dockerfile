# NVIDIA publishes CUDA development images with versioned tags.
# https://hub.docker.com/r/nvidia/cuda/tags?name=devel-ubuntu26.04
FROM nvidia/cuda:13.4.3-devel-ubuntu26.04

# Install the security updates of the base image. The official image can be days
# behind the security repository of the distribution.
# Remove the Nsight Compute profiler and the loose Go binary pebble. The course
# does not use them. No package update fixes the CVEs in their Go code.
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        ccache \
        cmake \
        git \
        libssl-dev \
        ninja-build \
        pkg-config \
    && apt-get purge -y 'nsight-compute-*' 'cuda-nsight-compute-*' \
    && apt-get autoremove -y \
    && rm -f /usr/bin/pebble \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["bash"]
