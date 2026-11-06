#!/usr/bin/env bash
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

python --version
uv --version
ffmpeg -version
ffprobe -version

ffmpeg -hide_banner -loglevel error -f lavfi -i sine=frequency=440:duration=1 \
    -ar 16000 -ac 1 source.wav
ffmpeg -hide_banner -loglevel error -i source.wav -c:a libopus converted.ogg
ffmpeg -hide_banner -loglevel error -i converted.ogg -ar 16000 -ac 1 decoded.wav
ffprobe -v error -show_streams -show_format -of json converted.ogg > media.json

python - <<'PY'
import json
import wave
from pathlib import Path

media = json.loads(Path("media.json").read_text())
assert media["streams"][0]["codec_name"] == "opus", media
assert media["streams"][0]["channels"] == 1, media
assert 0.9 < float(media["format"]["duration"]) < 1.2, media
for name in ("source.wav", "decoded.wav"):
    with wave.open(name) as audio:
        assert audio.getframerate() == 16000
        assert audio.getnchannels() == 1
        assert audio.getnframes() == 16000
        assert any(audio.readframes(16000)), "The audio is silent."
print("Audio generation, conversion, and Python inspection passed.")
PY
