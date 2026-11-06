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
    local new_ver="$1"
    local base_url="https://github.com/cargo-bins/cargo-binstall/releases/download/v${new_ver}"
    local x86_sum_url="${base_url}/cargo-binstall-x86_64-unknown-linux-musl.tgz.sha256sum"
    local arm_sum_url="${base_url}/cargo-binstall-aarch64-unknown-linux-musl.tgz.sha256sum"
    local x86_raw="" arm_raw="" x86_sha arm_sha

    x86_raw=$(curl -fsSL --retry 3 "$x86_sum_url" 2>/dev/null) || true
    arm_raw=$(curl -fsSL --retry 3 "$arm_sum_url" 2>/dev/null) || true

    if [ -z "$x86_raw" ] || [ -z "$arm_raw" ]; then
        echo "Individual .sha256sum files not found. List release assets." >&2
        github_api "https://api.github.com/repos/cargo-bins/cargo-binstall/releases/latest" \
            | jq -r '.assets[].name' >&2
        echo "ERROR: Cannot fetch checksums for cargo-binstall v${new_ver}." >&2
        return 1
    fi

    x86_sha=$(printf '%s' "$x86_raw" | awk '{print $1}')
    arm_sha=$(printf '%s' "$arm_raw" | awk '{print $1}')

    # Download the archives and verify them.
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

# Fetch SHA-256 digests for Typst from release assets. Update document-tools/Dockerfile.
update_typst() {
    local new_ver="$1"
    local base_url="https://github.com/typst/typst/releases/download/v${new_ver}"
    local x86_sha_url="${base_url}/typst-x86_64-unknown-linux-musl.tar.xz.sha256"
    local arm_sha_url="${base_url}/typst-aarch64-unknown-linux-musl.tar.xz.sha256"
    local x86_raw="" arm_raw="" x86_digest arm_digest

    x86_raw=$(curl -fsSL --retry 3 "$x86_sha_url" 2>/dev/null) || true
    arm_raw=$(curl -fsSL --retry 3 "$arm_sha_url" 2>/dev/null) || true

    if [ -z "$x86_raw" ] || [ -z "$arm_raw" ]; then
        echo "Typst .sha256 files not found. List release assets." >&2
        github_api "https://api.github.com/repos/typst/typst/releases/latest" \
            | jq -r '.assets[].name' >&2
        echo "ERROR: Cannot fetch digests for Typst v${new_ver}." >&2
        return 1
    fi

    x86_digest=$(printf '%s' "$x86_raw" | awk '{print $1}' | sed 's/^sha256://')
    arm_digest=$(printf '%s' "$arm_raw" | awk '{print $1}' | sed 's/^sha256://')

    # Update TYPST_VERSION and both digest lines in document-tools/Dockerfile.
    sed -i \
        -e "s/ARG TYPST_VERSION=.*/ARG TYPST_VERSION=${new_ver}/" \
        -e "s/amd64) arch=x86_64; digest=[0-9a-f]*/amd64) arch=x86_64; digest=${x86_digest}/" \
        -e "s/arm64) arch=aarch64; digest=[0-9a-f]*/arm64) arch=aarch64; digest=${arm_digest}/" \
        document-tools/Dockerfile
}

# Fetch crane checksums. Verify the archive. Compute the binary SHA. Update ci/install-tools.sh.
update_crane() {
    local new_ver="$1"
    local base_url="https://github.com/google/go-containerregistry/releases/download/v${new_ver}"
    local archive_name="go-containerregistry_Linux_x86_64.tar.gz"
    local checksums_raw="" new_archive_sha new_crane_sha

    checksums_raw=$(curl -fsSL --retry 3 "${base_url}/checksums.txt" 2>/dev/null) || true
    if [ -z "$checksums_raw" ]; then
        echo "ERROR: Cannot fetch checksums.txt for crane v${new_ver}." >&2
        return 1
    fi

    new_archive_sha=$(printf '%s' "$checksums_raw" | grep "$archive_name" | awk '{print $1}')
    if [ -z "$new_archive_sha" ]; then
        echo "ERROR: Cannot find ${archive_name} in crane checksums.txt." >&2
        return 1
    fi

    # Download the archive and verify it against the fetched checksum.
    local tmp_archive="$WORK_DIR/crane.tar.gz"
    curl -fsSL --retry 3 "${base_url}/${archive_name}" -o "$tmp_archive"
    echo "$new_archive_sha  $tmp_archive" | sha256sum -c -

    # Extract the crane binary and compute its SHA-256.
    tar -xzf "$tmp_archive" -C "$WORK_DIR" crane
    new_crane_sha=$(sha256sum "$WORK_DIR/crane" | awk '{print $1}')

    # Update the comment, URL, and both SHA constants in ci/install-tools.sh.
    sed -i \
        -e "s/# crane ${cur_crane}\\./# crane ${new_ver}./" \
        -e "s|/v${cur_crane}/|/v${new_ver}/|g" \
        -e "s/CRANE_ARCHIVE_SHA=[0-9a-f]*/CRANE_ARCHIVE_SHA=${new_archive_sha}/" \
        -e "s/CRANE_SHA=[0-9a-f]*/CRANE_SHA=${new_crane_sha}/" \
        ci/install-tools.sh
}

# Fetch SHA-256 for proot from SHA256SUMS. Verify the binary. Update ci/install-tools.sh.
update_proot() {
    local new_ver="$1"
    local base_url="https://github.com/proot-me/proot/releases/download/v${new_ver}"
    local shasums_url="${base_url}/SHA256SUMS"
    local shasums_raw="" new_proot_sha

    shasums_raw=$(curl -fsSL --retry 3 "$shasums_url" 2>/dev/null) || true
    if [ -z "$shasums_raw" ]; then
        echo "ERROR: Cannot fetch SHA256SUMS for proot v${new_ver}." >&2
        return 1
    fi

    new_proot_sha=$(printf '%s' "$shasums_raw" | grep 'proot$' | awk '{print $1}')
    if [ -z "$new_proot_sha" ]; then
        echo "ERROR: Cannot find proot entry in SHA256SUMS." >&2
        return 1
    fi

    # Download the proot binary and verify it.
    local tmp_proot="$WORK_DIR/proot"
    curl -fsSL --retry 3 "${base_url}/proot" -o "$tmp_proot"
    echo "$new_proot_sha  $tmp_proot" | sha256sum -c -

    # Update the comment, URL, and PROOT_SHA constant in ci/install-tools.sh.
    sed -i \
        -e "s|# proot ${cur_proot}, from [^ ]*|# proot ${new_ver}, from ${shasums_url}|" \
        -e "s|/v${cur_proot}/|/v${new_ver}/|g" \
        -e "s/PROOT_SHA=[0-9a-f]*/PROOT_SHA=${new_proot_sha}/" \
        ci/install-tools.sh
}

# Fetch SHA-256 for jq from sha256sum.txt. Verify the binary. Update ci/install-tools.sh.
update_jq() {
    local new_ver="$1"
    local base_url="https://github.com/jqlang/jq/releases/download/jq-${new_ver}"
    local sha256_url="${base_url}/sha256sum.txt"
    local sha256_raw="" new_jq_sha

    sha256_raw=$(curl -fsSL --retry 3 "$sha256_url" 2>/dev/null) || true
    if [ -z "$sha256_raw" ]; then
        echo "ERROR: Cannot fetch sha256sum.txt for jq ${new_ver}." >&2
        return 1
    fi

    new_jq_sha=$(printf '%s' "$sha256_raw" | grep 'jq-linux-amd64' | awk '{print $1}')
    if [ -z "$new_jq_sha" ]; then
        echo "ERROR: Cannot find jq-linux-amd64 in sha256sum.txt." >&2
        return 1
    fi

    # Download the jq binary and verify it.
    local tmp_jq="$WORK_DIR/jq"
    curl -fsSL --retry 3 "${base_url}/jq-linux-amd64" -o "$tmp_jq"
    echo "$new_jq_sha  $tmp_jq" | sha256sum -c -

    # Update the comment, URL, and JQ_SHA constant in ci/install-tools.sh.
    sed -i \
        -e "s|# jq ${cur_jq}, from [^ ]*|# jq ${new_ver}, from ${sha256_url}|" \
        -e "s|/jq-${cur_jq}/|/jq-${new_ver}/|g" \
        -e "s/JQ_SHA=[0-9a-f]*/JQ_SHA=${new_jq_sha}/" \
        ci/install-tools.sh
}

if [ "$cur_binstall" != "$latest_binstall" ]; then
    update_binstall "$latest_binstall"
    status_binstall="updated $cur_binstall -> $latest_binstall"
    updated=1
fi

if [ "$cur_typst" != "$latest_typst" ]; then
    update_typst "$latest_typst"
    status_typst="updated $cur_typst -> $latest_typst"
    updated=1
fi

if [ "$cur_crane" != "$latest_crane" ]; then
    update_crane "$latest_crane"
    status_crane="updated $cur_crane -> $latest_crane"
    updated=1
fi

if [ "$cur_proot" != "$latest_proot" ]; then
    update_proot "$latest_proot"
    status_proot="updated $cur_proot -> $latest_proot"
    updated=1
fi

if [ "$cur_jq" != "$latest_jq" ]; then
    update_jq "$latest_jq"
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
