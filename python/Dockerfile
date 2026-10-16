# Use Python, uv, pytest, Behave, Ruff, and mypy to test and check Python code.
FROM python:latest

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

RUN pip install --no-cache-dir --root-user-action=ignore pytest behave ruff mypy \
    && python --version \
    && uv --version \
    && pytest --version \
    && behave --version \
    && ruff --version \
    && mypy --version

WORKDIR /workspace
CMD ["bash"]
