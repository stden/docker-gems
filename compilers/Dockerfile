# Use Debian stable for the compilers, Python, and LaTeX.
# The official Mono image no longer receives updates.
FROM debian:stable-slim

# Install the security updates of the base image. The official image can be days
# behind the security repository of the distribution.
# Install the compilers, Python, PDF tools, and tree.
# Download the latest DMD compiler from dlang.org.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    texlive texlive-latex-extra texlive-fonts-recommended texlive-luatex poppler-utils \
    g++ fp-compiler mono-mcs ghc \
    python3 python3-venv \
    tree wget curl git ca-certificates && \
    DMD_VERSION=$(curl -fsS https://downloads.dlang.org/releases/LATEST) && \
    curl -fsSLo /tmp/dmd.deb "https://downloads.dlang.org/releases/2.x/$DMD_VERSION/dmd_$DMD_VERSION-0_amd64.deb" && \
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
