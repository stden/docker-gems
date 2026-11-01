#!/usr/bin/env bash
# Check pinned versions of tools against their GitHub releases.
# Update source files for each outdated tool.
# Exit 0 when all tools are current. Exit 1 when any tool was updated.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

# Set the Authorization header when GITHUB_TOKEN is set.
GITHUB_AUTH=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    GITHUB_AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

# Send a request to the GitHub API.
# Usage: github_api URL
github_api() {
    curl -fsSL --retry 3 \
        -H "Accept: application/vnd.github.v3+json" \
        "${GITHUB_AUTH[@]}" \
        "$1"
}

# Get the latest release tag for a GitHub repository.
# Usage: get_latest OWNER/REPO
get_latest() {
    github_api "https://api.github.com/repos/$1/releases/latest" | jq -r .tag_name
}

# Read the pinned versions from source files.
cur_binstall=$(grep -m1 'ARG BINSTALL_VERSION=' rust-ci/Dockerfile | cut -d= -f2)
cur_typst=$(grep -m1 'ARG TYPST_VERSION=' document-tools/Dockerfile | cut -d= -f2)
cur_crane=$(grep -m1 'CRANE_URL=' ci/install-tools.sh | sed 's|.*/v\([^/]*\)/.*|\1|')
cur_proot=$(grep -m1 'PROOT_URL=' ci/install-tools.sh | sed 's|.*/v\([^/]*\)/.*|\1|')
cur_jq=$(grep -m1 'JQ_URL=' ci/install-tools.sh | sed 's|.*/jq-\([^/]*\)/.*|\1|')

# Query the latest release versions from GitHub.
latest_binstall=$(get_latest cargo-bins/cargo-binstall | sed 's/^v//')
latest_typst=$(get_latest typst/typst | sed 's/^v//')
latest_crane=$(get_latest google/go-containerregistry | sed 's/^v//')
latest_proot=$(get_latest proot-me/proot | sed 's/^v//')
latest_jq=$(get_latest jqlang/jq | sed 's/^jq-//')

updated=0
status_binstall=current
status_typst=current
status_crane=current
status_proot=current
status_jq=current

# Fetch SHA-256 checksums for cargo-binstall. Verify the archives. Update both Dockerfiles.
update_binstall() {
    local new_ver=$1
    local base_url="https://github.com/cargo-bins/cargo-binstall/releases/download/v${new_ver}"
    local x86_sum_url="${base_url}/cargo-binstall-x86_64-unknown-linux-musl.tgz.sha256sum"
    local arm_sum_url="${base_url}/cargo-binstall-aarch64-unknown-linux-musl.tgz.sha256sum"
    local x86_raw="" arm_raw="" x86_sha arm_sha

    x86_raw=$(curl -fsSL --retry 3 "$x86_sum_url" 2>/dev/null) || true
    arm_raw=$(curl -fsSL --retry 3 "$arm_sum_url" 2>/dev/null) || true

    if [ -z "$x86_raw" ] || [ -z "$arm_raw" ]; then
        echo "Individual .sha256sum files not found. Listing release assets..." >&2
        github_api "https://api.github.com/repos/cargo-bins/cargo-binstall/releases/latest" \
            | jq -r '.assets[].name' >&2
        echo "ERROR: Cannot fetch checksums for cargo-binstall v${new_ver}." >&2
        return 1
    fi

    x86_sha=$(printf '%s' "$x86_raw" | awk '{print $1}')
    arm_sha=$(printf '%s' "$arm_raw" | awk '{print $1}')

    # Download the archives and verify them against the fetched checksums.
    local tmp_x86="$WORK_DIR/binstall-x86.tgz"
    local tmp_arm="$WORK_DIR/binstall-arm.tgz"
    curl -fsSL --retry 3 \
        "${base_url}/cargo-binstall-x86_64-unknown-linux-musl.tgz" \
        -o "$tmp_x86"
    echo "$x86_sha  $tmp_x86" | sha256sum -c -

    curl -fsSL --retry 3 \
        "${base_url}/cargo-binstall-aarch64-unknown-linux-musl.tgz" \
        -o "$tmp_arm"
    echo "$arm_sha  $tmp_arm" | sha256sum -c -

    # Update BINSTALL_VERSION and both SHA lines in rust-ci and rust-desktop.
    for df in rust-ci/Dockerfile rust-desktop/Dockerfile; do
        sed -i \
            -e "s/ARG BINSTALL_VERSION=.*/ARG BINSTALL_VERSION=${new_ver}/" \
            -e "s/x86_64) binstall_sha=[0-9a-f]*/x86_64) binstall_sha=${x86_sha}/" \
            -e "s/aarch64) binstall_sha=[0-9a-f]*/aarch64) binstall_sha=${arm_sha}/" \
            "$df"
    done
}

if [ "$cur_binstall" != "$latest_binstall" ]; then
    update_binstall "$latest_binstall"
    status_binstall="updated $cur_binstall -> $latest_binstall"
    updated=1
fi

if [ "$cur_typst" != "$latest_typst" ]; then
    sed -i "s/ARG TYPST_VERSION=.*/ARG TYPST_VERSION=${latest_typst}/" document-tools/Dockerfile
    status_typst="updated $cur_typst -> $latest_typst"
    updated=1
fi

if [ "$cur_crane" != "$latest_crane" ]; then
    sed -i "s|/v${cur_crane}/|/v${latest_crane}/|g" ci/install-tools.sh
    status_crane="updated $cur_crane -> $latest_crane"
    updated=1
fi

if [ "$cur_proot" != "$latest_proot" ]; then
    sed -i "s|/v${cur_proot}/|/v${latest_proot}/|g" ci/install-tools.sh
    status_proot="updated $cur_proot -> $latest_proot"
    updated=1
fi

if [ "$cur_jq" != "$latest_jq" ]; then
    sed -i "s|/jq-${cur_jq}/|/jq-${latest_jq}/|g" ci/install-tools.sh
    status_jq="updated $cur_jq -> $latest_jq"
    updated=1
fi

# Print the summary table.
printf '\n%-16s | %-10s | %-10s | %s\n' 'Tool' 'Current' 'Latest' 'Status'
printf '%-16s-+-%-10s-+-%-10s-+-%s\n' '----------------' '----------' '----------' '------'
printf '%-16s | %-10s | %-10s | %s\n' 'cargo-binstall' "$cur_binstall" "$latest_binstall" "$status_binstall"
printf '%-16s | %-10s | %-10s | %s\n' 'typst'          "$cur_typst"    "$latest_typst"    "$status_typst"
printf '%-16s | %-10s | %-10s | %s\n' 'crane'          "$cur_crane"    "$latest_crane"    "$status_crane"
printf '%-16s | %-10s | %-10s | %s\n' 'proot'          "$cur_proot"    "$latest_proot"    "$status_proot"
printf '%-16s | %-10s | %-10s | %s\n' 'jq'             "$cur_jq"       "$latest_jq"       "$status_jq"
printf '\n'

exit "$updated"
