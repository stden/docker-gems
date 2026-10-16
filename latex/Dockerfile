# Use the full TeX Live image, which receives daily updates.
# fermiumlabs/latex-docker received its last update in 2020.
FROM texlive/texlive:latest

# Install sshpass and C++ build, coverage, and memory-check tools.
# Use the Boost development package without an exact library version.
RUN apt-get update && \
    apt-get install -y sshpass git cmake g++ libboost-filesystem-dev gcovr lcov valgrind tree && \
    rm -rf /var/lib/apt/lists/*
