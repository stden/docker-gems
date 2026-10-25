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

FROM php:latest

# Composer reads its settings and cache from /tmp/composer, so it also works for a
# user without a home directory (docker run --user).
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp/composer

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
COPY --from=phpunit /usr/local/bin/phpunit /usr/local/bin/phpunit

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
    for ext in bcmath intl pdo_mysql pdo_pgsql zip; do \
      if ! php -m | grep -Fxq "$ext"; then \
        need_dev=1; \
        break; \
      fi; \
    done; \
    if [ "$need_dev" -eq 1 ]; then \
      apt-get install -y --no-install-recommends libicu-dev libpq-dev libzip-dev; \
      for ext in bcmath intl pdo_mysql pdo_pgsql zip; do \
        if ! php -m | grep -Fxq "$ext"; then \
          docker-php-ext-install -j"$(nproc)" "$ext"; \
        fi; \
      done; \
    fi; \
    if ! php -m | grep -Fxq pcov; then \
      pecl install pcov; \
      docker-php-ext-enable pcov; \
    fi; \
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
 && php --version \
 && php -r 'echo "pcov ", phpversion("pcov"), PHP_EOL;' \
 && composer --version \
 && phpunit --version \
 && rm -rf /tmp/composer

WORKDIR /workspace
CMD ["bash"]
