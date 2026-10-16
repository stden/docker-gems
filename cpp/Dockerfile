# Use the official GNU C++ base image.
FROM gcc:latest

# Install build, coverage, and memory-check tools. The base image includes g++.
RUN apt-get update && \
    apt-get install -y git cmake gcovr lcov valgrind tree && \
    rm -rf /var/lib/apt/lists/*
# If a project uses Boost, add libboost-filesystem-dev.
