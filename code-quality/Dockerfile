# Static checks that many repositories run in CI: gitleaks (secrets), hadolint
# (Dockerfiles), shellcheck (shell scripts), actionlint (GitHub workflows), typos
# (spelling), and semgrep (code patterns).
FROM debian:stable-slim AS download

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl jq \
 && rm -rf /var/lib/apt/lists/*

# Download the newest stable GitHub release of each tool. Check the file with the
# SHA-256 digest in the release metadata. Usage: fetch TOOL REPOSITORY ASSET_REGEX.
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
    fetch typos crate-ci/typos '^typos-.*-x86_64-unknown-linux-musl\.tar\.gz$'

FROM debian:stable-slim

# Semgrep does not check for a new version at each run. The image gets the newest
# release at each build. Semgrep writes its log and settings to /tmp, so it also
# works for a user without a home directory (docker run --user).
ENV PYTHONDONTWRITEBYTECODE=1 \
    SEMGREP_ENABLE_VERSION_CHECK=0 \
    SEMGREP_LOG_FILE=/tmp/semgrep.log \
    SEMGREP_SETTINGS_FILE=/tmp/semgrep-settings.yml

# gitleaks reads the commit history with git. Semgrep runs on the Debian Python.
# The mounted repository often has a different owner than the container user. Git
# then refuses to read it, and gitleaks finds 0 commits and passes. Trust all
# directories in this single-purpose container.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates git python3 python3-venv \
 && rm -rf /var/lib/apt/lists/* \
 && git config --system --add safe.directory '*'

# Semgrep has its own environment, so pip does not change the Debian Python packages.
RUN python3 -m venv /opt/semgrep \
 && /opt/semgrep/bin/pip install --no-cache-dir semgrep \
 && ln -s /opt/semgrep/bin/semgrep /usr/local/bin/semgrep

COPY --from=download /out/ /usr/local/bin/
RUN gitleaks version \
 && hadolint --version \
 && shellcheck --version \
 && actionlint -version \
 && typos --version \
 && semgrep --version \
 && rm -rf /tmp/semgrep*

WORKDIR /workspace
CMD ["bash"]
