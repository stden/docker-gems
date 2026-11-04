# Multi-stage build: the download stage fetches Allure 2 from Maven Central and checks its SHA-512.
# The final node:slim stage copies only the extracted CLI and installs Allure 3 from npm.
# 'allure' is the Allure Report 3 CLI. 'allure2' is the Allure Report 2 CLI.
FROM debian:stable-slim AS download

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Fetch the newest 2.x release from Maven Central.
# Verify the SHA-512 checksum to confirm the archive is not corrupted or substituted.
WORKDIR /tmp
RUN set -eux; \
    base=https://repo1.maven.org/maven2/io/qameta/allure/allure-commandline; \
    version=$(curl -fsSL "$base/maven-metadata.xml" \
      | sed -n 's:.*<version>\(2\.[0-9]*\.[0-9]*\)</version>.*:\1:p' | sort -V | tail -n 1); \
    archive="allure-commandline-$version.tgz"; \
    curl -fsSLO "$base/$version/$archive"; \
    curl -fsSLO "$base/$version/$archive.sha512"; \
    echo "$(cut -d ' ' -f 1 "$archive.sha512")  $archive" | sha512sum --check; \
    mkdir /opt/allure2; \
    tar -xzf "$archive" -C /opt/allure2 --strip-components=1

FROM node:slim

# Set ALLURE_NO_ANALYTICS=true to disable Allure 2 telemetry.
# Its reports do not load an external analytics script.
ENV ALLURE_NO_ANALYTICS=true

# Allure 2 is a JVM application; node:slim has no JDK.
# Install security updates at the same time to reduce CVE exposure.
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends default-jre-headless \
 && rm -rf /var/lib/apt/lists/*

# Copy only the extracted Allure 2 CLI from the download stage, not the download tools.
COPY --from=download /opt/allure2 /opt/allure2

# npm verifies each package with SHA-512 checksums at install time.
# 'npm audit signatures' confirms the npm registry signature of each installed package.
WORKDIR /opt/allure3
RUN npm init --yes > /dev/null \
 && npm install --no-audit --no-fund allure@latest \
 && npm audit signatures \
 && npm cache clean --force \
 && ln -s /opt/allure3/node_modules/.bin/allure /usr/local/bin/allure \
 && ln -s /opt/allure2/bin/allure /usr/local/bin/allure2 \
 && allure --version \
 && allure2 --version \
 && java -version

WORKDIR /workspace
CMD ["bash"]
