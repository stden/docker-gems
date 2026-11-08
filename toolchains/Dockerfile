# A compiler and interpreter set for CI jobs and local tests. The image has the toolchains
# of the Ubuntu 24.04 packages, so a job starts without installing them.
# Ubuntu 24.04 is the same release as the runs-on image ubuntu-latest of GitHub Actions.
FROM ubuntu:26.04

# Install the security updates of the base image, then the toolchains of the job.
# Git reads the repository history, and the CA bundle lets tools use HTTPS.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates git python3 g++ default-jdk-headless nodejs perl php-cli ruby golang-go && \
    rm -rf /var/lib/apt/lists/*

# Verify the tools at build time. A missing tool stops the build before publication.
RUN g++ --version && python3 --version && javac -version && node --version && \
    perl -v && php --version && ruby --version && go version

WORKDIR /workspace
CMD ["bash"]
