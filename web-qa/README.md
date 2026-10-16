# stden/web-qa

Test web pages with Python, Chromium, Google Chrome, axe, and Lighthouse.

## Overview

This image contains:

- Python, uv, pytest, Behave, Playwright, and pytest-playwright.
- Chromium that matches the installed Playwright package.
- Google Chrome and the ChromeDriver that axe uses.
- Node.js, npm, the axe CLI, and Lighthouse.

Use it for browser tests, behavior tests, and accessibility checks. The working
directory is `/workspace`. The default command starts Bash. The image includes
Chromium and Chrome. For Firefox and WebKit, a separate installation is necessary.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main`. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/web-qa/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/web-qa:latest
```

## Run project tests

Run these commands from your project directory. Give the browser tests shared memory
with `--shm-size=1g`.

```sh
docker run --rm --shm-size=1g -v "$PWD":/workspace \
  stden/web-qa:latest pytest

docker run --rm --shm-size=1g -v "$PWD":/workspace \
  stden/web-qa:latest behave
```

Install extra project dependencies in a child image. Keep the installed
Playwright package and its browser revision together. If you change the package
version, run `python -m playwright install --with-deps chromium` in that build.

For Python Playwright code, use `playwright.chromium.launch()` for Chromium.
Set `channel="chrome"` to use Google Chrome.

## Check accessibility

Replace `https://example.com` with the page to test. The commands save the reports to
the mounted project directory.

```sh
docker run --rm --shm-size=1g -v "$PWD":/workspace stden/web-qa:latest \
  axe https://example.com --exit \
  --chrome-options="no-sandbox,disable-dev-shm-usage,remote-debugging-pipe" \
  --save axe.json

docker run --rm --shm-size=1g -v "$PWD":/workspace stden/web-qa:latest \
  lighthouse https://example.com --only-categories=accessibility \
  --chrome-flags="--headless --no-sandbox --disable-dev-shm-usage" \
  --output=html --output-path=lighthouse.html
```

Use these commands only for pages that you control. They run Chrome without its
sandbox in a disposable container. Inside the container, `localhost` is the
container itself. Use a Docker network and a service name to connect to another
container.

## Source and checks

The smoke test opens a local page in Chromium and Chrome. It also runs pytest,
Behave, axe, and a Lighthouse accessibility check.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/web-qa/Dockerfile)
- [Smoke test](https://github.com/stden/docker-gems/blob/main/web-qa/smoke-test.sh)
- [Overview source](https://github.com/stden/docker-gems/blob/main/web-qa/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
