---
name: publish-docker-images
description: >-
  Use when the user asks to build and push images to Docker Hub, or to "publish",
  "release", or "git push" image changes. Also use when the user asks to check
  whether a Docker Hub image and its overview are up to date. The skill covers the
  checks before the push, how to watch GitHub Actions, and how to check the result
  on Docker Hub.
---

# Publish Docker images

GitHub Actions publishes the images. A push to `main` builds and tests every image, then
pushes each tested image to `stden/<name>:latest` and saves its Docker Hub overview. A
Docker Hub login on your computer is not necessary.

## 1. Before the push

1. Run the checks in "Verify before you commit" in `AGENTS.md` for each changed image.
2. Look at `git status`. Another person or tool can work in the same tree. Stage only
   the files of this task.
3. Commit the staged files with a message in Simplified Technical English. End the message with the
   attribution trailer that the session specifies.

## 2. Push and watch

```sh
git push origin main
gh run list --limit 3
gh run watch <run-id> --exit-status
```

Every push builds all images. One job runs for each image, and the jobs run in parallel.
A run takes about 10 minutes. The time limit of a job is 180 minutes. Runs on the same
branch wait for each other. A newer pending run replaces an older pending run.

For `graphify`, `codegraph`, `java-eks`, `argocd`, and `crossplane`, the job also deploys the
Kubernetes manifests to a kind cluster with `ci/test-kubernetes.sh` before the push. The job
summary shows this step as `Kubernetes test`.

To show only the jobs that are not successful:

```sh
gh run view <run-id> --json jobs \
  --jq '.jobs[] | select(.conclusion != "success") | "\(.name): \(.status) \(.conclusion)"'
```

If a job fails, read its log with `gh run view <run-id> --log-failed`. Fix the cause.
Test again. Then push again. A failed job does not change the published image.

## 3. Check the result on Docker Hub

```sh
curl -fsS https://hub.docker.com/v2/repositories/stden/<name>/ \
  | jq '{description, categories: [.categories[].name], last_updated}'
curl -fsS https://hub.docker.com/v2/repositories/stden/<name>/tags/latest \
  | jq '{digest, full_size, last_updated}'
```

The short description must be the third line of `<name>/README.md`. The `last_updated`
time must be after the push.

## 4. Rewrite the history only on request

Squash commits or force-push only when the user asks for it. Then do these steps:

1. Run `git fetch origin`. Then check that `origin/main` is the commit that you expect.
2. Record the old commit ID. You can use it to restore the old history:
   `git reset --hard <old-id>`.
3. Squash the commits. Then check that `git rev-parse HEAD^{tree}` did not change.
4. Push with `git push --force-with-lease=main:<old-id> origin main`.
