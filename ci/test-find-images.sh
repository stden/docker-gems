#!/bin/bash
# Check the full push range and safe fallbacks for the image matrix.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/repo/alpha" "$WORK/repo/beta"
cd "$WORK/repo"
git init -q
git config user.name 'Image matrix test'
git config user.email 'matrix@example.invalid'
git config commit.gpgsign false
printf 'FROM scratch\n' > alpha/Dockerfile
printf 'FROM scratch\n' > beta/Dockerfile
git add alpha/Dockerfile beta/Dockerfile
git -c core.hooksPath=/dev/null commit -qm 'Create two image fixtures'
base=$(git rev-parse HEAD)

printf '# image change\n' >> alpha/Dockerfile
git add alpha/Dockerfile
git -c core.hooksPath=/dev/null commit -qm 'Change alpha'
image_change=$(git rev-parse HEAD)
printf 'Documentation\n' > README.md
git add README.md
git -c core.hooksPath=/dev/null commit -qm 'Change documentation'

check_matrix() {
    local name=$1 before=$2 event=$3 expected=$4 actual
    : > "$WORK/output"
    GITHUB_OUTPUT="$WORK/output" GITHUB_EVENT_NAME="$event" BEFORE_SHA="$before" \
        bash "$ROOT/ci/find-images.sh"
    actual=$(sed -n 's/^images=//p' "$WORK/output")
    [[ "$actual" == "$expected" ]] || {
        echo "FAIL $name: expected $expected, got $actual" >&2
        exit 1
    }
    echo "PASS $name"
}

check_matrix multi_commit_push "$base" push '["alpha"]'
check_matrix documentation_only "$image_change" push '[]'
check_matrix missing_base deadbeef push '["alpha","beta"]'
check_matrix new_branch 0000000000000000000000000000000000000000 push '["alpha","beta"]'
check_matrix manual_build '' workflow_dispatch '["alpha","beta"]'

mkdir ci
printf 'CI fixture\n' > ci/check.sh
git add ci/check.sh
git -c core.hooksPath=/dev/null commit -qm 'Change shared CI'
check_matrix shared_ci "$base" push '["alpha","beta"]'
