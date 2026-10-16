FROM python:latest AS ffmpeg-build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg nasm pkg-config \
      libmp3lame-dev libopus-dev libvpx-dev libx264-dev \
 && rm -rf /var/lib/apt/lists/*

# Use the newest stable release that FFmpeg publishes.
RUN release=$(curl -fsSL https://ffmpeg.org/download.html \
      | sed -n 's/.*href="\(releases\/ffmpeg-[0-9][0-9.]*\.tar\.xz\)".*/\1/p' \
      | sed -n '1p') \
 && test -n "$release" \
 && curl -fsSL "https://ffmpeg.org/$release" -o /tmp/ffmpeg.tar.xz \
 && curl -fsSL "https://ffmpeg.org/$release.asc" -o /tmp/ffmpeg.tar.xz.asc \
 && curl -fsSL https://ffmpeg.org/ffmpeg-devel.asc -o /tmp/ffmpeg-key.asc \
 && gpg --batch --import /tmp/ffmpeg-key.asc \
 && gpg --batch --verify /tmp/ffmpeg.tar.xz.asc /tmp/ffmpeg.tar.xz \
 && mkdir /tmp/ffmpeg \
 && tar -xJf /tmp/ffmpeg.tar.xz --strip-components=1 -C /tmp/ffmpeg \
 && cd /tmp/ffmpeg \
 && ./configure --prefix=/opt/ffmpeg --disable-debug --disable-doc --disable-ffplay \
      --enable-gpl --enable-libmp3lame --enable-libopus --enable-libvpx --enable-libx264 \
 && make -j2 \
 && make install

FROM python:latest

# The -dev names remain valid when Debian updates codec library versions.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libmp3lame-dev libopus-dev libvpx-dev libx264-dev \
 && rm -rf /var/lib/apt/lists/*

COPY --from=ffmpeg-build /opt/ffmpeg/bin/ffmpeg /opt/ffmpeg/bin/ffprobe /usr/local/bin/
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /workspace
CMD ["bash"]
