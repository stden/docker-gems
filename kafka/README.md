# stden/kafka

Run a single-node Apache Kafka broker in KRaft mode for message testing.

## Contents

- Apache Kafka 3 in KRaft mode (no ZooKeeper)
- Kafka shell scripts at `/opt/kafka/bin/`
- Client listener on port 9092

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful `main` build | `linux/amd64` |

[View tags and image digests](https://hub.docker.com/r/stden/kafka/tags).

## Pull and run

```sh
docker pull stden/kafka:latest
docker run -d -p 127.0.0.1:9092:9092 --name kafka stden/kafka:latest
```

Wait for the broker to accept connections:

```sh
docker exec kafka /opt/kafka/bin/kafka-broker-api-versions.sh \
  --bootstrap-server localhost:9092
```

Create a topic and send a message:

```sh
docker exec kafka /opt/kafka/bin/kafka-topics.sh \
  --create --topic demo --bootstrap-server localhost:9092

echo "hello" | docker exec -i kafka \
  /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server localhost:9092 --topic demo
```

## Checks and source

CI builds the image and verifies the Kafka scripts are in place.
The local test starts the broker, creates a topic, produces a message, and consumes it.

[Dockerfile](https://github.com/stden/docker-gems/blob/main/kafka/Dockerfile) ·
[Docker tutorial](https://github.com/stden/docker-gems/blob/main/README.md) ·
[Build results](https://github.com/stden/docker-gems/actions)
