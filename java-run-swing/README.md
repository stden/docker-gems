# stden/java-run-swing

Run Java Swing applications and tests with JDK 25 LTS and a virtual display.

## Contents

- OpenJDK 25 LTS on Alpine Linux
- Xvfb and `xvfb-run` for a virtual display
- DejaVu fonts
- Tini to manage child processes

The working directory is `/app`. The default command starts `/bin/sh`.
The virtual display runs inside the container. It does not show a window on your monitor.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful `main` build | `linux/amd64` |

[View tags and image digests](https://hub.docker.com/r/stden/java-run-swing/tags).

## Pull and run

```sh
docker pull stden/java-run-swing:latest
docker run --rm stden/java-run-swing:latest java -version
```

Run a Swing JAR from the current directory:

```sh
docker run --rm -v "$PWD":/app stden/java-run-swing:latest \
  xvfb-run -a java -jar my-app.jar
```

Compile a Java source file named `Hello.java`. Then run the program:

```sh
docker run --rm -v "$PWD":/app stden/java-run-swing:latest javac Hello.java
docker run --rm -v "$PWD":/app stden/java-run-swing:latest xvfb-run -a java Hello
```

A test must close its windows and exit when it finishes.

## Checks and source

CI compiles a small Swing program, opens a `JFrame` under Xvfb, and checks its exit status.

[Dockerfile](https://github.com/stden/docker-gems/blob/main/java-run-swing/Dockerfile) ·
[Docker tutorial](https://github.com/stden/docker-gems/blob/main/README.md) ·
[Build results](https://github.com/stden/docker-gems/actions)
