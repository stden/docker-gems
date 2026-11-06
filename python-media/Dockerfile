FROM python:latest

# Install security updates and FFmpeg from the Debian repository.
# The Debian package includes libopus and the lavfi source that the smoke test uses.
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends ffmpeg \
 && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

RUN ffmpeg -version && ffprobe -version

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /workspace
CMD ["bash"]
