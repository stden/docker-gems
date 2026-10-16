# Use the official GNU C++ base image.
FROM gcc:latest

# Install the security updates of the base image. The official image can be days
# behind the security repository of the distribution.
# Install build, coverage, and memory-check tools. The base image includes g++.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends git cmake gcovr lcov valgrind tree && \
    rm -rf /var/lib/apt/lists/*
# If a project uses Boost, add libboost-filesystem-dev.
