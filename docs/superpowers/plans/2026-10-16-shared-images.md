# Implementation plan for the shared Docker images

> For AI agents: Use the subagent-driven-development workflow for the independent image groups.

**Goal:** Add all nine proposed images, test their main functions, and publish them through GitHub Actions.

**Architecture:** Each image has an independent Dockerfile and a self-contained `smoke-test.sh`. The Docker and PRoot runners use the same test file. The tests of the existing images stay available. The workflow finds all image directories automatically.

**Tech Stack:** Docker, Bash, GitHub Actions, Rust, Node.js, Python, Playwright, Typst, LibreOffice, Vulkan, CUDA, PostgreSQL, pgvector, Apache AGE.

## Image groups

- [x] Add `rust-node`, `rust-ci`, and `rust-desktop`. Verify the current official base images and tool releases. Where applicable, test a Rust build, Node execution, nextest, and a GTK window under Xvfb.
- [x] Add `web-qa`, `document-tools`, and `python-media`. Test browser navigation, document conversion, and FFmpeg audio conversion. Keep the versions of the Playwright browser and the Playwright package aligned.
- [x] Add `cpp-vulkan`, `cpp-cuda`, and `postgres-vector-graph`. Test shader compilation and a software Vulkan device. Compile CUDA code without a GPU. Run vector and Cypher queries against a temporary PostgreSQL cluster. Use a stable, compatible PostgreSQL/AGE pair.

## Integration

- [x] Add the nine names to `test-images.sh`. Run each shared smoke test in the built image. Override the entrypoint of the image. Use a bind mount, so that the tests do not increase the size of the runtime image.
- [x] Add an equivalent test dispatch to `ci/test-built-image.sh`. Keep test failures fatal. Rehearse a new image with Kaniko and PRoot.
- [x] Add the `up.sh` and `up.cmd` scripts as a pair. Each script builds, tests, tags, and pushes in that order. It must stop if a step fails.
- [x] Extend the regression checks of the smoke runner for the new test dispatch and for the propagation of failures.
- [x] Add image catalogue entries, quick-start commands, version constraints, and GPU test limitations to README.md and AGENTS.md.
- [x] Check the disk space of the runner for the new large images. Keep the short job names and the full build output.

## Verification and publication

- [x] Build each new image with `docker build --pull --no-cache --tag NAME:latest NAME`. Then run `./test-images.sh --no-build NAME`.
- [x] Run `actionlint .github/workflows/docker-images.yml`, shell syntax checks, ShellCheck, `bash ci/test-smoke-failures.sh`, and `git diff --check`.
- [x] Review all nine Dockerfiles and the shared test integration independently. Resolve all important findings.
- [x] Keep the existing history of one commit. Amend that commit with a message in Simplified Technical English. Push with an explicit force-with-lease. Then monitor all new image jobs until they publish the images.

The standard hosted runner cannot run GPU code on NVIDIA hardware. The CUDA test must state that it verifies compilation only. The PostgreSQL tests use temporary data. They must not connect to existing databases.
