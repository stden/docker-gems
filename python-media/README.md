# stden/python-media

Process audio and video with FFmpeg, ffprobe, Python, and uv.

## Overview

This image contains Python and a current stable FFmpeg build. It includes
`ffmpeg`, `ffprobe`, and support for x264, LAME MP3, Opus, and VP8/VP9 through
libvpx. Use it for media conversion and Python scripts that inspect media.

The working directory is `/workspace`. The default command starts Bash.
The image does not include `ffplay`.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main`. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/python-media/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/python-media:latest
```

## Convert media

Run these commands from a directory that contains `input.wav`:

```sh
docker run --rm -v "$PWD":/workspace stden/python-media:latest \
  ffmpeg -i input.wav -c:a libmp3lame output.mp3

docker run --rm -v "$PWD":/workspace stden/python-media:latest \
  ffmpeg -i input.wav -c:a libopus output.ogg
```

Convert a video to H.264 with AAC audio:

```sh
docker run --rm -v "$PWD":/workspace stden/python-media:latest \
  ffmpeg -i input.mov -c:v libx264 -c:a aac output.mp4
```

The output files stay in the mounted host directory. Use a new output file name
for each command. To replace an existing output file, add `-y`.

## Inspect media with ffprobe

```sh
docker run --rm -v "$PWD":/workspace stden/python-media:latest \
  ffprobe -v error -show_streams -show_format -of json output.mp4
```

Run a Python script in the same environment:

```sh
docker run --rm -v "$PWD":/workspace stden/python-media:latest \
  python inspect_media.py
```

Install extra Python libraries in a child image that starts with
`FROM stden/python-media:latest`. The image contains command-line media tools.
You must install project-specific Python media libraries separately.

## Source and checks

The smoke test generates audio, encodes it as Opus, and decodes it to PCM.
Python checks the codec, duration, channel count, sample rate, and audio data.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/python-media/Dockerfile)
- [Smoke test](https://github.com/stden/docker-gems/blob/main/python-media/smoke-test.sh)
- [Overview source](https://github.com/stden/docker-gems/blob/main/python-media/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
