# MinIO Source Build Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to execute each task. Check each result before the next task.

**Goal:** Restore the MinIO image build and its S3 smoke test without obsolete upstream images.

**Architecture:** Compile the official MinIO server and client modules with `golang:latest`. Copy static binaries into `alpine:latest`.
Keep ports 9000 and 9001. Set an explicit server command for the documented run example.

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

`test-images.sh` has a pre-existing malformed first line. Explicit Bash runs print that warning and complete the S3 smoke test.
