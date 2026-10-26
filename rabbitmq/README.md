# stden/rabbitmq

Run a RabbitMQ broker with the management UI and a demo exchange and queue.

## Contents

- RabbitMQ with the management plugin
- Management API and web UI on port 15672 (guest:guest)
- AMQP listener on port 5672
- Pre-created `demo` direct exchange, `demo` queue, and `demo` binding

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful `main` build | `linux/amd64` |

[View tags and image digests](https://hub.docker.com/r/stden/rabbitmq/tags).

## Pull and run

```sh
docker pull stden/rabbitmq:latest
docker run -d -p 127.0.0.1:5672:5672 -p 127.0.0.1:15672:15672 \
  --name rabbitmq stden/rabbitmq:latest
```

Check the broker health:

```sh
curl -fsS -u guest:guest http://127.0.0.1:15672/api/healthchecks/node
```

Open the management UI at `http://127.0.0.1:15672` (guest:guest).

## Checks and source

CI builds the image and verifies the configuration files are in place.
The local test starts the broker, publishes a message to the `demo` exchange, and reads it from the `demo` queue.

[Dockerfile](https://github.com/stden/docker-gems/blob/main/rabbitmq/Dockerfile) ·
[Docker tutorial](https://github.com/stden/docker-gems/blob/main/README.md) ·
[Build results](https://github.com/stden/docker-gems/actions)
