# Generate Allure test reports in CI from allure-results of pytest, JUnit 5 or 6, Cucumber,
# Behave, and Playwright. `allure` is Allure Report 3. `allure2` is the Allure Report 2 CLI.
FROM debian:stable-slim AS download

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

# Download the newest stable Allure Report 2 release from Maven Central and check its SHA-512.
RUN set -eux; \
    base=https://repo1.maven.org/maven2/io/qameta/allure/allure-commandline; \
    version=$(curl -fsSL "$base/maven-metadata.xml" \
      | sed -n 's:.*<version>\(2\.[0-9]*\.[0-9]*\)</version>.*:\1:p' | sort -V | tail -n 1); \
    archive="allure-commandline-$version.tgz"; \
    cd /tmp; \
    curl -fsSLO "$base/$version/$archive"; \
    curl -fsSLO "$base/$version/$archive.sha512"; \
    echo "$(cut -d ' ' -f 1 "$archive.sha512")  $archive" | sha512sum --check; \
    mkdir /opt/allure2; \
    tar -xzf "$archive" -C /opt/allure2 --strip-components=1

FROM node:slim

# Allure 2 does not send usage data, and its reports do not load an analytics script.
ENV ALLURE_NO_ANALYTICS=true

# Allure Report 2 runs on Java.
RUN apt-get update \
 && apt-get install -y --no-install-recommends default-jre-headless \
 && rm -rf /var/lib/apt/lists/*

COPY --from=download /opt/allure2 /opt/allure2

# Install the newest Allure Report 3 from npm. npm checks the SHA-512 of each package.
# "npm audit signatures" also checks the registry signatures of all installed packages.
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
