# Test PHP projects in CI: PHP CLI, Composer, PHPUnit, pcov for code coverage, and the
# extensions that typical projects use. php:latest is the CLI variant of the newest stable PHP.
FROM php:latest AS phpunit

# Download the newest stable PHPUnit PHAR and verify its GPG signature with the PHPUnit
# release key of Sebastian Bergmann.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /tmp
RUN set -eux; \
    key=D8406D0D82947747293778314AA394086372C20A; \
    apt-get update; \
    apt-get install -y --no-install-recommends gpg gpgv; \
    url=$(curl -fsSL -o phpunit.phar -w '%{url_effective}' https://phar.phpunit.de/phpunit.phar); \
    curl -fsSL -o phpunit.phar.asc "$url.asc"; \
    curl -fsSL "https://keys.openpgp.org/vks/v1/by-fingerprint/$key" | gpg --dearmor > phpunit.gpg; \
    gpgv --status-fd 1 --keyring ./phpunit.gpg phpunit.phar.asc phpunit.phar \
      | grep "^\[GNUPG:\] VALIDSIG $key "; \
    install -m 0755 phpunit.phar /usr/local/bin/phpunit

# Build pcov in its own stage. pcov 1.0.12 does not build on PHP 8.6, and the image has no PECL.
# Build pcov from this upstream commit and verify its SHA-256. Replace the pin with a pcov
# release that builds on the PHP version of php:latest.
FROM php:latest AS pcov
ARG PCOV_COMMIT=3795c08561d69ca7f55f693492de59a65a6a182d
ARG PCOV_SHA256=29e9a0ef0e717305c98aac05b1530dba2c3f05caf7ecdd3f9db50faf51ef1073
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /tmp/pcov
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends autoconf dpkg-dev file g++ gcc libc-dev make pkg-config re2c; \
    rm -rf /var/lib/apt/lists/*; \
    curl -fsSL -o /tmp/pcov.tar.gz "https://github.com/krakjoe/pcov/archive/${PCOV_COMMIT}.tar.gz"; \
    echo "${PCOV_SHA256}  /tmp/pcov.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/pcov.tar.gz --strip-components=1; \
    rm /tmp/pcov.tar.gz
# Install into /out, so that the final stage copies only pcov.so.
RUN phpize && ./configure && make -j"$(nproc)" && make install INSTALL_ROOT=/out

FROM php:latest

# Composer reads its settings and cache from /tmp/composer, so it also works for a
# user without a home directory (docker run --user).
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp/composer

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
COPY --from=phpunit /usr/local/bin/phpunit /usr/local/bin/phpunit
COPY --from=pcov /out/ /

# Install the security updates of the base image. The official image can be days
# behind the security repository of the distribution. Composer must have git and
# unzip. Install a PHP extension only when this base image does not have it. The
# purge keeps the runtime libraries.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN set -eux; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends git unzip; \
    savedAptMark="$(apt-mark showmanual)"; \
    need_dev=0; \
    for ext in bcmath intl mbstring pdo_mysql pdo_pgsql zip; do \
      if ! php -m | grep -Fxq "$ext"; then \
        need_dev=1; \
        break; \
      fi; \
    done; \
    if [ "$need_dev" -eq 1 ]; then \
      apt-get install -y --no-install-recommends libicu-dev libonig-dev libpq-dev libzip-dev; \
      for ext in bcmath intl mbstring pdo_mysql pdo_pgsql zip; do \
        if ! php -m | grep -Fxq "$ext"; then \
          docker-php-ext-install -j"$(nproc)" "$ext"; \
        fi; \
      done; \
    fi; \
    docker-php-ext-enable pcov; \
    apt-mark auto '.*' > /dev/null; \
    printf '%s\n' "$savedAptMark" | xargs -r apt-mark manual > /dev/null; \
    find /usr/local -type f \( -executable -o -name '*.so' \) -exec ldd '{}' ';' 2> /dev/null \
      | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
      | sort -u \
      | xargs -r dpkg-query --search \
      | awk 'sub(":$", "", $1) { print $1 }' \
      | sort -u \
      | xargs -r apt-mark manual; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/* /tmp/pear

# Test settings: show all errors, run assert(), and remove the memory limit for coverage.
RUN cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
 && printf 'memory_limit = -1\n' > "$PHP_INI_DIR/conf.d/memory-limit.ini" \
 && rm -rf /tmp/composer

# Verify the tools at build time. A missing tool stops the build before publication.
RUN php --version && phpunit --version && composer --version

WORKDIR /workspace
CMD ["bash"]
