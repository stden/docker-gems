# Base image: python:latest ships the current stable Python and pip.
FROM python:latest

# Copy only the uv binary from its official image without a package manager install.
# COPY --from a named image is a way to add a single tool without an extra RUN step.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Install test and lint tools in one layer to keep the image small.
RUN pip install --no-cache-dir --root-user-action=ignore pytest behave ruff mypy

# Verify the tools at build time. A missing tool stops the build before publication.
RUN python --version \
    && uv --version \
    && pytest --version \
    && behave --version \
    && ruff --version \
    && mypy --version

WORKDIR /workspace
CMD ["bash"]
