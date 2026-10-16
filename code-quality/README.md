# stden/code-quality

Run gitleaks, hadolint, shellcheck, actionlint, typos, and semgrep checks from one image.

## Overview

This image has the static checks that many repositories run in CI:

| Tool | It checks | It exits with an error when |
| --- | --- | --- |
| [gitleaks](https://github.com/gitleaks/gitleaks) | Secrets in files and in the git history | it finds a secret |
| [hadolint](https://github.com/hadolint/hadolint) | Dockerfiles | it finds a problem |
| [shellcheck](https://www.shellcheck.net/) | Shell scripts | it finds a problem |
| [actionlint](https://github.com/rhysd/actionlint) | GitHub Actions workflows, with shellcheck for `run` scripts | it finds a problem |
| [typos](https://github.com/crate-ci/typos) | Spelling in code and documents | it finds a spelling mistake |
| [semgrep](https://semgrep.dev/) | Code patterns from your rules | it finds a match and you set `--error` |

Each build installs the newest stable release of each tool. The build downloads gitleaks,
hadolint, shellcheck, actionlint, and typos from their GitHub releases. It checks each file
with the SHA-256 digest in the release metadata. The build installs Semgrep with pip in its
own environment on the Debian Python.

The base image is `debian:stable-slim`. The image also has git, so gitleaks can read the
commit history. The image trusts all git directories (`safe.directory`). Without this
setting, git does not accept a mounted repository with a different owner, and gitleaks
scans 0 commits and passes. The working directory is `/workspace`. The default command
starts Bash.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` with the newest stable tools. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/code-quality/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/code-quality:latest
```

## Tutorial

Run the commands from the root of your project. The commands mount the project at
`/workspace`. The container runs as your user, so the files that a tool writes belong to
you. Set a short alias:

```sh
alias cq='docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/workspace stden/code-quality:latest'
```

Each tool exits with a non-zero status when it finds a problem. A script or a CI job
then stops.

### Step 1: Find secrets with gitleaks

```sh
cq gitleaks git --redact --no-banner --verbose .
cq gitleaks dir --redact --no-banner .
```

`gitleaks git` scans each commit. `gitleaks dir` scans the files, also the files that you
did not commit. `--redact` replaces the secret value with `REDACTED` in the output. The log
shows the number of scanned commits. If it shows 0 commits, the scan did not read the
history.

A secret that you delete in a new commit stays in the history. Revoke the secret. Then make
a new secret. To accept a known finding, add its `Fingerprint` line to `.gitleaksignore`.
To accept all current findings of an old repository, save a baseline once. Then compare
each scan with it:

```sh
cq gitleaks git --redact --no-banner --report-path gitleaks-baseline.json .
cq gitleaks git --redact --no-banner --baseline-path gitleaks-baseline.json .
```

### Step 2: Check Dockerfiles with hadolint

```sh
cq hadolint Dockerfile
```

To ignore a rule in the project, write `.hadolint.yaml`:

```yaml
ignored:
  - DL3008
```

To ignore a rule for one instruction, write `# hadolint ignore=DL3008` on the line before it.

### Step 3: Check shell scripts with shellcheck

```sh
cq bash -c 'git ls-files -z "*.sh" | xargs -0 --no-run-if-empty shellcheck'
```

To ignore a rule for one command, write `# shellcheck disable=SC2086` on the line before
it. Put project settings in `.shellcheckrc`.

### Step 4: Check GitHub workflows with actionlint

```sh
cq actionlint
```

actionlint reads all files in `.github/workflows`. It finds incorrect keys, incorrect
expressions, and jobs that do not exist. It also runs shellcheck on each `run` script.

### Step 5: Find spelling mistakes with typos

```sh
cq typos
cq typos --write-changes
```

The second command corrects the files. Review the change with `git diff`. To skip files or
accept project words, write `_typos.toml`:

```toml
[files]
extend-exclude = ["*.min.js", "testdata/"]

[default.extend-words]
# Add a project word here as word = "word".
```

### Step 6: Find code patterns with semgrep

Write a rule file `semgrep.yml`:

```yaml
rules:
  - id: no-eval
    languages: [python]
    severity: ERROR
    message: Do not pass data to eval().
    pattern: eval(...)
```

```sh
cq semgrep scan --config semgrep.yml --metrics=off --error
```

`--error` makes semgrep exit with status 1 when it finds a match. Without it, semgrep
exits with status 0. With `--metrics=off`, semgrep does not send usage data. A local rule
file does not use the network. A registry rule set, for example `--config p/default`,
downloads its rules from semgrep.dev.

To skip a file, add it to `.semgrepignore`. To accept one line, write `# nosemgrep: no-eval`
on it.

## Use in CI

### GitHub Actions

The job runs in the image. The image has git, so `actions/checkout` makes a real clone.
`fetch-depth: 0` gets the full history for gitleaks.

```yaml
name: Code quality
on:
  push:
  pull_request:
permissions:
  contents: read
jobs:
  checks:
    runs-on: ubuntu-latest
    container: stden/code-quality:latest
    defaults:
      run:
        shell: bash
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - run: gitleaks git --redact --no-banner .
      - run: hadolint Dockerfile
      - run: git ls-files -z '*.sh' | xargs -0 --no-run-if-empty shellcheck
      - run: actionlint
      - run: typos
      - run: semgrep scan --config semgrep.yml --metrics=off --error
```

### GitLab CI

`GIT_DEPTH: 0` gets the full history for gitleaks.

```yaml
code-quality:
  image: stden/code-quality:latest
  variables:
    GIT_DEPTH: 0
  script:
    - gitleaks git --redact --no-banner .
    - hadolint Dockerfile
    - git ls-files -z '*.sh' | xargs -0 --no-run-if-empty shellcheck
    - typos
    - semgrep scan --config semgrep.yml --metrics=off --error
```

## Best practices

- **Make the pipeline fail on findings.** Do not add `|| true`, `continue-on-error`, or
  `allow_failure`. Always give semgrep `--error`.
- **Keep the baseline and the ignore files in git.** Commit `.gitleaksignore` or the gitleaks
  baseline, `.hadolint.yaml`, `.shellcheckrc`, `_typos.toml`, and `.semgrepignore`.
  Review each change to them as you review code. Write the reason next to each inline
  ignore comment.
- **Never print found secrets in logs.** Always use `gitleaks --redact`. CI logs stay for
  a long time, and many people can read them. Do not upload a report without `--redact`
  as a CI artifact.
- **Revoke a leaked secret first.** Each person who can read the repository can see a secret
  in a pushed commit. A new commit that deletes it does not remove it from the history.
- **Scan the full history once, then each change.** In a merge request, scan only the new
  commits, for example `gitleaks git --redact --log-opts="origin/main..HEAD" .`.
- **Use local rules for repeatable semgrep scans.** Keep the rule file in git. Use
  `--metrics=off`. Registry rule sets change without a change in your repository.
- **Control tool updates.** The `latest` tag gets new tool versions, and a new version can
  find new problems. To choose when this happens, pin the image digest. Update the digest
  with Dependabot or Renovate.
- **Run the same checks before you push.** The same image gives the same results on your
  computer and in CI.

## Source and checks

The smoke test works offline. It makes small sample files. It checks that each tool finds a
known problem and accepts the clean file. The known problems are:

- A fake AWS key in a file and in the git history of a repository with a different owner.
- A Dockerfile with `ADD`.
- A shell script and a workflow `run` script with an unquoted variable.
- A workflow job with a `needs` entry for a job that does not exist.
- A spelling mistake.
- Code that matches a local semgrep rule.

The test also checks that gitleaks does not print the secret, that a gitleaks baseline
accepts a known finding, and that typos corrects a file.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/code-quality/Dockerfile)
- [Smoke test](https://github.com/stden/docker-gems/blob/main/code-quality/smoke-test.sh)
- [Overview source](https://github.com/stden/docker-gems/blob/main/code-quality/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
