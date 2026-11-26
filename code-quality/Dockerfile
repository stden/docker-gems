# Multi-stage build: the download stage fetches 6 tool binaries from GitHub and
# checks each one with a SHA-256 digest. The final stage copies only the binaries.
# Semgrep installs separately with pip in the final stage.
# Tools: gitleaks, hadolint, shellcheck, shfmt, actionlint, typos, trivy, semgrep.
FROM debian:stable-slim AS download

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl jq \
 && rm -rf /var/lib/apt/lists/*

# Fetch each tool from its GitHub release. Verify the SHA-256 from the release metadata
# so the build fails if the downloaded file does not match the expected checksum.
# Usage: fetch TOOL REPOSITORY ASSET_REGEX.
WORKDIR /tmp/download
RUN set -eux; \
    mkdir /out; \
    fetch() { \
      curl -fsSL "https://api.github.com/repos/$2/releases/latest" -o "$1.json"; \
      url=$(jq -er --arg re "$3" '.assets[] | select(.name | test($re)) | .browser_download_url' "$1.json"); \
      digest=$(jq -er --arg re "$3" '.assets[] | select(.name | test($re)) | .digest | ltrimstr("sha256:")' "$1.json"); \
      curl -fsSL "$url" -o "$1.download"; \
      echo "$digest  $1.download" | sha256sum --check; \
      case $url in \
        *.tar.gz) mkdir "$1.d"; tar -xzf "$1.download" -C "$1.d"; \
                  find "$1.d" -type f -name "$1" -exec install -m 0755 {} /out/ \; ;; \
        *) install -m 0755 "$1.download" "/out/$1" ;; \
      esac; \
      test -x "/out/$1"; \
    }; \
    fetch gitleaks gitleaks/gitleaks '^gitleaks_.*_linux_x64\.tar\.gz$'; \
    fetch hadolint hadolint/hadolint '^hadolint-linux-x86_64$'; \
    fetch shellcheck koalaman/shellcheck '^shellcheck-.*\.linux\.x86_64\.tar\.gz$'; \
    fetch actionlint rhysd/actionlint '^actionlint_.*_linux_amd64\.tar\.gz$'; \
    fetch typos crate-ci/typos '^typos-.*-x86_64-unknown-linux-musl\.tar\.gz$'; \
    fetch trivy aquasecurity/trivy '^trivy_.*_Linux-64bit\.tar\.gz$'

FROM debian:stable-slim

# ENV disables telemetry and configures each tool for non-interactive CI use.
# Semgrep writes its log and settings to /tmp so it works for any user (docker run --user).
# Trivy stores its vulnerability database in /opt/trivy-cache for offline scans.
ENV PYTHONDONTWRITEBYTECODE=1 \
    SEMGREP_ENABLE_VERSION_CHECK=0 \
    SEMGREP_LOG_FILE=/tmp/semgrep.log \
    SEMGREP_SETTINGS_FILE=/tmp/semgrep-settings.yml \
    TRIVY_DISABLE_TELEMETRY=true \
    TRIVY_SKIP_VERSION_CHECK=true \
    TRIVY_CACHE_DIR=/opt/trivy-cache

# gitleaks reads the commit history with git. Semgrep runs on the Debian Python.
# A mounted repository often has a different owner than the container user. Git
# then refuses to read it, and gitleaks scans 0 commits and passes without finding secrets.
# Trust all directories in this single-purpose container to prevent that silent pass.
# Install security updates before the tools to reduce CVE exposure in the final image.
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends ca-certificates git python3 python3-venv shfmt \
 && rm -rf /var/lib/apt/lists/* \
 && git config --system --add safe.directory '*'

# Semgrep runs in its own venv so pip does not change the Debian Python packages.
RUN python3 -m venv /opt/semgrep \
 && /opt/semgrep/bin/pip install --no-cache-dir semgrep \
 && ln -s /opt/semgrep/bin/semgrep /usr/local/bin/semgrep

COPY --from=download /out/ /usr/local/bin/
RUN gitleaks version \
 && hadolint --version \
 && shellcheck --version \
 && shfmt --version \
 && actionlint -version \
 && typos --version \
 && semgrep --version \
 && trivy --version \
 && mkdir -p /opt/trivy-cache /tmp/trivy-empty \
 && trivy filesystem --download-db-only /tmp/trivy-empty \
 && chmod -R a+rX /opt/trivy-cache \
 && rm -rf /tmp/semgrep*

# Verify the tools at build time.
RUN gitleaks --version && shellcheck --version && hadolint --version

WORKDIR /workspace
CMD ["bash"]
