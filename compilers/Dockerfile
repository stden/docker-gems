# Use Debian stable for the compilers, Python, and LaTeX.
# The official Mono image no longer receives updates.
FROM debian:stable-slim

# Pin the DMD compiler version and its SHA-256 from https://downloads.dlang.org
ARG DMD_VERSION=2.113.0
ARG DMD_SHA256=cc381becf12894f3c8403f15d060f6ef172e60d65813a6b26dc32d9c4cfd908b

# Install the security updates of the base image. The official image can be days
# behind the security repository of the distribution.
# Install the compilers, Python, PDF tools, and tree.
# Download the latest DMD compiler from dlang.org.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    texlive texlive-latex-extra texlive-fonts-recommended texlive-luatex poppler-utils \
    g++ fp-compiler mono-mcs ghc \
    python3 python3-venv \
    tree wget curl git ca-certificates && \
    test "$(dpkg --print-architecture)" = amd64 && \
    curl -fsSLo /tmp/dmd.deb "https://downloads.dlang.org/releases/2.x/$DMD_VERSION/dmd_$DMD_VERSION-0_amd64.deb" && \
    echo "$DMD_SHA256  /tmp/dmd.deb" | sha256sum --check && \
    apt-get install -y --no-install-recommends /tmp/dmd.deb && \
    rm -rf /tmp/dmd.deb /var/lib/apt/lists/*

# Install Python libraries in a virtual environment. PEP 668 makes this necessary.
RUN python3 -m venv /opt/venv && /opt/venv/bin/pip install --no-cache-dir numpy pandas
ENV PATH="/opt/venv/bin:$PATH"
RUN gcc --version && g++ --version && mcs --version && dmd --version && \
    ghc --version && fpc -iV && python --version && \
    pdflatex --version && lualatex --version && pdftotext -v
# Set the code directory.
WORKDIR /x
# Copy the code into the image.
COPY . /x
RUN chmod +x /x/test.sh /x/hw_python.py
# Test the sample programs when the container starts.
CMD ["/x/test.sh"]
