#!/usr/bin/env bash
# Each check must find a known problem and accept clean input. The test is offline.
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

gitleaks version
hadolint --version
shellcheck --version
actionlint -version
typos --version
semgrep --version

# Usage: expect_finding STATUS TEXT COMMAND...
# COMMAND must exit with STATUS and print TEXT. Its output is in $output.
expect_finding() {
    local expected=$1 text=$2 status=0
    shift 2
    output=$("$@" 2>&1) || status=$?
    printf '%s\n' "$output"
    if [[ "$status" != "$expected" || "$output" != *"$text"* ]]; then
        echo "FAIL: '$*' exited with $status, not $expected, or did not print '$text'." >&2
        exit 1
    fi
}

# gitleaks: a fake AWS access key in a file and in the git history.
# The test joins the key at run time, so that secret scanners do not report this file.
fake_key="AKIA""LALEMEL33243OLIA"
mkdir -p secrets/clean secrets/leak
printf 'region = "us-east-1"\n' > secrets/clean/config.ini
printf 'aws_access_key_id = "%s"\n' "$fake_key" > secrets/leak/config.ini
gitleaks dir --no-banner --redact secrets/clean
expect_finding 1 aws-access-token gitleaks dir --no-banner --redact --verbose secrets/leak
if [[ "$output" == *"$fake_key"* ]]; then
    echo 'FAIL: gitleaks printed the secret although --redact is set.' >&2
    exit 1
fi
# A baseline accepts the known finding, so that only new findings fail.
expect_finding 1 'leaks found: 1' \
    gitleaks dir --no-banner --redact --report-path baseline.json secrets/leak
gitleaks dir --no-banner --redact --baseline-path baseline.json secrets/leak

# A deleted secret stays in the history. The repository has a different owner, as a
# mounted repository often has. Git must still read it.
git init -q -b main history
cp secrets/leak/config.ini history/
git -C history add config.ini
git -C history -c user.name=Test -c user.email=test@example.com commit -qm 'Add settings'
git -C history rm -q config.ini
git -C history -c user.name=Test -c user.email=test@example.com commit -qm 'Remove settings'
chown -R 12345:12345 history
expect_finding 1 aws-access-token gitleaks git --no-banner --redact --verbose history

# hadolint: ADD for a local file gives DL3020.
mkdir docker
printf 'echo Hello\n' > docker/hello.sh
printf 'FROM debian:stable-slim\nADD hello.sh /usr/local/bin/hello.sh\nCMD ["hello.sh"]\n' \
    > docker/Dockerfile.bad
printf 'FROM debian:stable-slim\nCOPY hello.sh /usr/local/bin/hello.sh\nCMD ["hello.sh"]\n' \
    > docker/Dockerfile.good
hadolint docker/Dockerfile.good
expect_finding 1 DL3020 hadolint docker/Dockerfile.bad

# ShellCheck: an unquoted variable gives SC2086.
mkdir shell
cat > shell/good.sh <<'SH'
#!/bin/sh
echo "$1"
SH
cat > shell/bad.sh <<'SH'
#!/bin/sh
echo $1
SH
shellcheck shell/good.sh
expect_finding 1 SC2086 shellcheck shell/bad.sh

# actionlint: a job has a needs key for a job that does not exist, and shellcheck finds an
# unquoted variable in a run step.
mkdir -p .github/workflows
cat > .github/workflows/good.yml <<'YAML'
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "$GREETING"
        env:
          GREETING: Hello
YAML
cat > .github/workflows/bad.yml <<'YAML'
on: push
jobs:
  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: echo $GREETING
YAML
actionlint .github/workflows/good.yml
expect_finding 1 '[job-needs]' actionlint .github/workflows/bad.yml
[[ "$output" == *SC2086*'[shellcheck]'* ]] || {
    echo 'FAIL: actionlint did not run shellcheck.' >&2
    exit 1
}

# typos: find a spelling mistake, accept a word from the project dictionary, and fix the file.
# The test joins the wrong word at run time, so that typos accepts this file.
wrong_word="te""h"
mkdir spelling
printf 'Check %s results.\n' "$wrong_word" > spelling/notes.txt
printf 'Check the results.\n' > spelling/clean.txt
printf '[default.extend-words]\n%s = "%s"\n' "$wrong_word" "$wrong_word" > typos-accept.toml
typos spelling/clean.txt
expect_finding 2 'should be' typos spelling/notes.txt
typos --config typos-accept.toml spelling/notes.txt
typos --write-changes spelling/notes.txt
grep -Fx 'Check the results.' spelling/notes.txt

# semgrep: a local rule finds eval(). The scan uses no registry and sends no metrics.
mkdir semgrep
cat > semgrep/rules.yml <<'YAML'
rules:
  - id: no-eval
    languages: [python]
    severity: ERROR
    message: Do not pass data to eval().
    pattern: eval(...)
YAML
printf 'print(eval(input()))\n' > semgrep/bad.py
printf 'print(int(input()))\n' > semgrep/good.py
semgrep scan --config semgrep/rules.yml --metrics=off --error --quiet semgrep/good.py
expect_finding 1 no-eval semgrep scan --config semgrep/rules.yml --metrics=off --error semgrep/bad.py

echo "gitleaks, hadolint, shellcheck, actionlint, typos, and semgrep checks passed."
