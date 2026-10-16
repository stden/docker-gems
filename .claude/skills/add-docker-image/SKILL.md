---
name: add-docker-image
description: >-
  Use when you add a new image to this repository. Example requests are "add an
  image with tool X", "create a Docker image for Y", and "make an image and push
  it to Docker Hub". The skill lists every file and every list that must change,
  the smoke test pattern, and the checks to run before the commit. For a change
  to an existing image, read AGENTS.md instead.
---

# Add a Docker image

A top-level directory with a `Dockerfile` is one image. GitHub Actions builds it, runs
its smoke test, and publishes it as `stden/<name>:latest`. The rules are in `AGENTS.md`.
This skill is the checklist. Use a short lowercase name with hyphens, for example `web-qa`.

## 1. Find the current version

Read the "Version policy" and "Find the latest version from a primary source" sections
of `AGENTS.md`. Use the `latest` tag of the base image. Check the package registry
(PyPI, npm, GitHub releases) for the newest stable release of the tool. Before you write
the Dockerfile, run the tool once in the base image:

```sh
docker run --rm python:latest bash -c 'pip install -q <package> && <tool> --version'
```

## 2. Create the files in `<name>/`

| File | Content |
| --- | --- |
| `Dockerfile` | `FROM <base>:latest`. A comment says what the image is for. Install the tool. Then print its version, so that a broken install fails the build. For a tool image, end with `WORKDIR /workspace` and `CMD ["bash"]`. |
| `smoke-test.sh` | A self-contained Bash test. Start with `set -euo pipefail`. Work in a temporary directory from `mktemp -d`. Remove it in a `trap`. Test the main functions on a small sample, not only `--version`. Do not call an external service for which a key is necessary. |
| `README.md` | The Docker Hub overview. Line 1 is `# stden/<name>`. Line 2 is empty. Line 3 is the short description: one line of at most 100 bytes. Use absolute links. Keep the file below 25000 bytes. Copy the section order of `graphify/README.md`. |
| `up.sh` and `up.cmd` | Copy them from `web-qa/`. Then change the image name. |

Make the scripts executable in git: `chmod +x <name>/smoke-test.sh <name>/up.sh`.

A test that starts a server must stop it in the `trap`. In GitLab CI, PRoot waits for
every child process, so a process that stays alive stops the job.

## 3. Update the shared lists

1. `test-images.sh`: add the name to `ALL` (alphabetical order) and to the `test_shared` case in `run_image`.
2. `ci/test-built-image.sh`: add the name to the case that runs `smoke-test.sh` with PRoot.
3. `ci/hub-categories.json`: add one to three search category slugs. Always include `languages-and-frameworks`.
4. `README.md`: the "Images" table, the "Select an image" table, an example command, and the number in the two sentences that start with `The eighteen shared tool images`.
5. `AGENTS.md`: the smoke test table, and the number of shared tool images.
6. `.github/workflows/docker-images.yml`: if the image is larger than about 5 GB, add the name to the "Free space" list.

## 4. Verify

Run the checks in "Verify before you commit" in `AGENTS.md`. This is the short form:

```sh
./test-images.sh <name>
python3 ci/hub_metadata.py --check
python3 -m unittest discover -s ci -p test_hub_metadata.py
bash ci/test-smoke-failures.sh
actionlint .github/workflows/docker-images.yml .github/workflows/docker-hub.yml
shellcheck <name>/smoke-test.sh <name>/up.sh
```

Then rehearse the GitLab path with Kaniko and PRoot (step 3 in `AGENTS.md`). Use a cache
directory in the scratchpad, not in the repository.

## 5. Publish

Use the `publish-docker-images` skill.
