# stden/node-ci

Build and test JavaScript and TypeScript projects in CI with Node.js, npm, pnpm, and Bun.

## What you learn

You learn to run the package managers of a JavaScript project in a Docker container.

## Overview

This image runs JavaScript and TypeScript projects on a computer or in a CI job. It contains:

- Node.js and npm, from the official [node:slim](https://hub.docker.com/_/node) image.
- [pnpm](https://pnpm.io/) and [Bun](https://bun.com/), installed with npm.
- `git`, which reads the history of a mounted repository.

The working directory is `/workspace`. The default command starts Bash.

## Run the image

Install the dependencies of a project in `/workspace` and run its start script:

```bash
docker run --rm -v "$PWD":/workspace -w /workspace stden/node-ci bash -c 'npm ci && npm start'
```
