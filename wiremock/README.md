# stden/wiremock

Mock HTTP services for integration tests with WireMock.

## Contents

- WireMock standalone server on port 8080
- Admin API at `/__admin/`
- A pre-loaded `/demo` stub that returns `{"status": "ok"}`

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful `main` build | `linux/amd64` |

[View tags and image digests](https://hub.docker.com/r/stden/wiremock/tags).

## Pull and run

```sh
docker pull stden/wiremock:latest
docker run -d -p 127.0.0.1:8080:8080 --name wiremock stden/wiremock:latest
```

Check the demo stub:

```sh
curl http://127.0.0.1:8080/demo
```

List all mappings:

```sh
curl http://127.0.0.1:8080/__admin/mappings
```

Add a new stub at runtime:

```sh
curl -X POST http://127.0.0.1:8080/__admin/mappings \
  -H 'Content-Type: application/json' \
  -d '{"request":{"url":"/hello"},"response":{"body":"world"}}'
```

## Checks and source

CI builds the image and verifies WireMock starts.
The local test starts WireMock, calls the `/demo` stub, and checks the admin API.

[Dockerfile](https://github.com/stden/docker-gems/blob/main/wiremock/Dockerfile) ·
[Docker tutorial](https://github.com/stden/docker-gems/blob/main/README.md) ·
[Build results](https://github.com/stden/docker-gems/actions)
