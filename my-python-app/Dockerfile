# Base image: python:latest ships the current stable Python and pip.
FROM python:latest

# Install security updates before application packages to reduce CVE exposure.
# The official image can be days behind the security repository of the distribution.
# Install 'tree' to show the directory structure in the tutorial.
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends tree \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Copy requirements.txt before the source code so pip runs only when dependencies change.
# Docker skips the pip layer on the next build if this file did not change.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy source files after dependencies so a code change reuses the pip layer above.
COPY . .

# Verify the tools at build time. A missing tool stops the build before publication.
RUN python --version

# JSON array form: the OS sends signals to Python directly, without a shell wrapper.
CMD ["python", "./my-test.py"]
