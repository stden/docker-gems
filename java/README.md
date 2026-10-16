# stden/java

Build and test Java projects with JDK 25 LTS and Maven 3.

## Contents

- Amazon Corretto JDK 25 LTS
- Maven 3
- Bash

The working directory is `/workspace`. The default command starts Bash.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful `main` build | `linux/amd64` |

[View tags and image digests](https://hub.docker.com/r/stden/java/tags).

## Pull and run

```sh
docker pull stden/java:latest
docker run --rm stden/java:latest bash -c 'java -version && mvn -version'
```

Run this command from a Maven project directory:

```sh
docker run --rm -v "$PWD":/workspace stden/java:latest mvn -B verify
```

To reuse downloaded Maven dependencies, add a named volume:

```sh
docker run --rm -v "$PWD":/workspace -v docker-gems-maven:/root/.m2 \
  stden/java:latest mvn -B verify
```

## Checks and source

CI checks the Java and Maven versions before it publishes the image.

[Dockerfile](https://github.com/stden/docker-gems/blob/main/java/Dockerfile) ·
[Docker tutorial](https://github.com/stden/docker-gems/blob/main/README.md) ·
[Build results](https://github.com/stden/docker-gems/actions)
