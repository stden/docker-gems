# Service Image CI Repair Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to execute each task. Check each result before the next task.

**Goal:** Restore the MinIO, Mailpit, RabbitMQ, and LaTeX checks without weaker functional or security tests.

**Architecture:** Compile official MinIO modules with `golang:latest` and copy the binaries into `alpine:latest`.
Use the supported Mailpit CLI. Define the RabbitMQ virtual host, demo user, and permissions before its existing topology.

**Tech Stack:** Docker, Go, Alpine Linux, MinIO, mc, Bash, hadolint, Trivy.

---

### Task 1: Confirm the failure

- [x] Read `AGENTS.md` and the MinIO image files.
- [x] Confirm current `main` and the open pull requests.
- [x] Run `docker build --pull --no-cache --progress=plain -t minio:ci-before minio`.
- [x] Confirm that both upstream MinIO image names return `not found`.
- [x] Check the official source-only install instructions and current base image dates.

### Task 2: Replace the obsolete image dependencies

**Files:** `minio/Dockerfile`, `minio/README.md`, `README.md`.

- [x] Install `github.com/minio/minio@latest` and `github.com/minio/mc@latest` in a Go build stage.
- [x] Set `CGO_ENABLED=0` and limit each Go build to eight workers.
- [x] Copy both binaries and their license files into the Alpine runtime.
- [x] Install the current CA bundle and disable the MinIO update check.
- [x] Start `minio server /data --console-address :9001` by default.
- [x] Update the image overview and catalogue with the source-build policy.

### Task 3: Verify the complete image

- [x] Run `docker build --pull --no-cache --progress=plain -t minio:latest minio`.
- [x] Run `bash test-images.sh --no-build minio` and `IMAGE=minio bash ci/test-image.sh`.
- [x] Check both binary versions and the Go module build metadata.
- [x] Run hadolint on `minio/Dockerfile` with the repository configuration.
- [x] Export the image and scan it with Trivy without the Docker socket.
- [x] Record all fixable HIGH and CRITICAL findings. Keep the existing security policy.
- [ ] Check the final diff and stage only the intended files.
- [ ] Commit and push the fix branch. Create a pull request without image publication.
- [ ] Inspect the branch CI and report any remaining failure.

## Local verification result

The final image build, hadolint, and both S3 smoke commands passed. The image has 207 MB.
Trivy used database 2026-10-30 07:16 UTC. The scan found 63 fixable HIGH and five fixable CRITICAL entries.
All findings refer to Go dependencies in the archived upstream modules. The Alpine packages have no reported HIGH or CRITICAL finding.
The build does not change the existing scan policy. The local JSON report is `.ci-minio-checks/trivy.json`.

Task 6 repairs the pre-existing malformed first line in `test-images.sh`.

## Additional matrix failures

The first PR matrix exposed two more failures in existing images.

### Task 4: Restore the Mailpit build

**Files:** `mailpit/Dockerfile`, `mailpit/README.md`.

- [x] Reproduce `mailpit:latest` with `--pull --no-cache`. The version command cannot find `mailpit` in `PATH`.
- [x] Check the official entrypoint and CLI. The binary is `/mailpit` and the version command is `version`.
- [x] Run `/mailpit version --no-release-check` in the Dockerfile. Disable automatic version checks.
- [x] Rebuild the image and run its existing CI smoke wrapper.
- [x] Run hadolint on the changed Dockerfile.

### Task 5: Complete the RabbitMQ demo definitions

**Files:** `rabbitmq/definitions.json`, `rabbitmq/README.md`.

- [x] Rebuild RabbitMQ with `--pull --no-cache`. Reproduce the missing virtual host error on first boot.
- [x] Read the official definition import guide. A blank node does not create the default virtual host or user.
- [x] Define `/`, the documented demo `guest` user hash, and permissions. Retain the exchange, queue, and binding.
- [x] Rebuild the image and run its existing CI smoke wrapper.
- [ ] Review and push both fixes to the same pull request.
- [ ] Inspect the next matrix result without a manual retry or cancellation.

### Task 6: Use the supported HTTP request contracts

**Files:** `test-images.sh`.

- [x] Reproduce the Mailpit POST error. Read the official v1.32.0 Swagger definition.
- [x] Use `/api/v1/send` and `Email` fields. Retain the stored subject assertion.
- [x] Reproduce RabbitMQ HTTP 400 with `{key_missing,ackmode}` after a successful publish.
- [x] Use `ackmode:ack_requeue_false`. Retain the retrieved payload assertion.
- [x] Restore `#!/bin/bash` so that direct script execution works.
- [x] Run both real service smoke tests and the shared script regression checks.

### Task 7: Restore the Russian LaTeX fixture

**Files:** `test-images.sh`.

- [x] Read all 35 jobs through the paginated API. The connector returns only the first 30 jobs.
- [x] Confirm the LaTeX failure: Unicode U+2568 comes from a fixture decoded as CP437 instead of UTF-8.
- [x] Build the current LaTeX image with `--pull --no-cache` and reproduce the failure locally.
- [x] Restore `Привет из контейнера.` and retain the Russian language packages and Boost.Filesystem test.
- [x] Run the real LaTeX CI wrapper and shared-script checks.

## Additional local checks

Mailpit and RabbitMQ build with current upstream images. Both existing CI wrappers pass after the request contract corrections.
All five shared Bash regression suites pass. All 16 Python tests pass. The metadata check covers 34 images.
Actionlint passes all three image workflows. Hadolint passes the three service Dockerfiles.
Full HIGH and CRITICAL Trivy scans of Mailpit and RabbitMQ report no findings.
The full MinIO scan also includes six unfixed upstream findings: 67 HIGH and seven CRITICAL entries in total.

The fresh LaTeX image reproduces the Unicode U+2568 error with the original fixture.
The restored UTF-8 fixture passes the actual CI wrapper and retains the Russian PDF and Boost.Filesystem checks.
