# Use the full TeX Live image, which receives daily updates.
# fermiumlabs/latex-docker received its last update in 2020.
FROM texlive/texlive:latest

# Install the security updates of the base image. The official image can be days
# behind the security repository of the distribution.
# Install sshpass and C++ build, coverage, and memory-check tools.
# Use the Boost development package without an exact library version.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends sshpass git cmake g++ libboost-filesystem-dev gcovr lcov valgrind tree && \
    rm -rf /var/lib/apt/lists/*

# Remove the Java tools of TeX Live, which the course does not use. Their jar files
# contain old libraries with known CVEs. The glob matches the TeX Live year.
RUN rm -rf /usr/local/texlive/*/texmf-dist/scripts/tlcockpit \
    /usr/local/texlive/*/texmf-dist/scripts/texplate \
    /usr/local/texlive/*/texmf-dist/scripts/latex2nemeth \
    /usr/local/texlive/*/bin/x86_64-linux/tlcockpit \
    /usr/local/texlive/*/bin/x86_64-linux/texplate \
    /usr/local/texlive/*/bin/x86_64-linux/latex2nemeth
