# stden/mailpit

Capture and inspect email with Mailpit in a development environment.

## Contents

- Mailpit SMTP server on port 1025
- Mailpit REST API and web UI on port 8025
- In-memory message store (no data persists after you remove the container)

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful `main` build | `linux/amd64` |

[View tags and image digests](https://hub.docker.com/r/stden/mailpit/tags).

## Pull and run

```sh
docker pull stden/mailpit:latest
docker run -d -p 127.0.0.1:1025:1025 -p 127.0.0.1:8025:8025 \
  --name mailpit stden/mailpit:latest
```

Open the web UI at `http://127.0.0.1:8025`.

Send a test message via SMTP:

```sh
curl -fsS smtp://127.0.0.1:1025 \
  --mail-from sender@example.com \
  --mail-rcpt to@example.com \
  -T - <<< "Subject: Test"$'\r\n'"hello"
```

## Checks and source

CI builds the image and verifies it starts.
The local test starts Mailpit, sends a message via the REST API, and reads it back.
Run `/mailpit version --no-release-check` to read the installed version.
The image disables automatic version checks.

[Dockerfile](https://github.com/stden/docker-gems/blob/main/mailpit/Dockerfile) ·
[Docker tutorial](https://github.com/stden/docker-gems/blob/main/README.md) ·
[Build results](https://github.com/stden/docker-gems/actions)
