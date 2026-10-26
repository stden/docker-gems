# stden/java-17

Build and test Java 17 projects with Maven 3.9 and common CI utilities.

## Contents

- Eclipse Temurin JDK 17 LTS
- Maven 3.9
- Bash, curl, git, jq
- fontconfig and DejaVu fonts for PDF generation
- openssh-client and sshpass for SSH deployments
- tzdata for timezone support

The working directory is `/workspace`. The default command starts Bash.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful `main` build | `linux/amd64` |

[View tags and image digests](https://hub.docker.com/r/stden/java-17/tags).

## Pull and run

```sh
docker pull stden/java-17:latest
docker run --rm stden/java-17:latest bash -c 'java -version && mvn -version'
```

Run this command from a Maven project directory:

```sh
docker run --rm -v "$PWD":/workspace stden/java-17:latest mvn -B verify
```

To reuse downloaded Maven dependencies, add a named volume:

```sh
docker run --rm -v "$PWD":/workspace -v docker-gems-maven:/root/.m2 \
  stden/java-17:latest mvn -B verify
```

## Checks and source

CI checks the Java 17, Maven, git, curl, and jq versions before it publishes the image.

[Dockerfile](https://github.com/stden/docker-gems/blob/main/java-17/Dockerfile) ·
[Docker tutorial](https://github.com/stden/docker-gems/blob/main/README.md) ·
[Build results](https://github.com/stden/docker-gems/actions)
