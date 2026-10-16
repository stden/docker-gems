# stden/java-ui-browser

Run Java browser tests with JDK 27, Gradle, and Google Chrome.

## Contents

- Eclipse Temurin JDK 27
- Gradle 9.8.2
- Stable Google Chrome
- Git and Python 3 with `venv`
- `libatomic` for browser test tools

The working directory is `/workspace`. Commands run as the `tester` user.
The default command starts Bash. Give this user write access to the mounted project files.

Gradle keeps its caches in `/home/tester/.gradle` (`GRADLE_USER_HOME`). To keep the downloaded
dependencies between runs, mount a named volume at this path, for example
`-v gradle-cache:/home/tester/.gradle`.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful `main` build | `linux/amd64` |

[View tags and image digests](https://hub.docker.com/r/stden/java-ui-browser/tags).

## Pull and run

```sh
docker pull stden/java-ui-browser:latest
docker run --rm stden/java-ui-browser:latest \
  bash -c 'java --version && gradle --version && google-chrome --version'
```

Run this command from a Gradle project directory:

```sh
docker run --rm --shm-size=1g -v "$PWD":/workspace \
  stden/java-ui-browser:latest gradle --no-daemon test
```

Configure the browser in your tests to use headless mode. Your project supplies its test
framework and browser driver dependencies.

## Checks and source

CI checks the Java, Gradle, Chrome, Git, and Python versions. It also checks that Python
can load `venv` and `libatomic.so.1`.

[Dockerfile](https://github.com/stden/docker-gems/blob/main/java-ui-browser/Dockerfile) ·
[Docker tutorial](https://github.com/stden/docker-gems/blob/main/README.md) ·
[Build results](https://github.com/stden/docker-gems/actions)
