# Test PHP projects in CI: PHP CLI, Composer, PHPUnit, pcov for code coverage, and the
# extensions that typical projects use. php:latest is the CLI variant of the newest stable PHP.
FROM php:latest AS phpunit

# Download the newest stable PHPUnit PHAR and verify its GPG signature with the PHPUnit
# release key of Sebastian Bergmann.
RUN set -eux; \
    key=D8406D0D82947747293778314AA394086372C20A; \
    apt-get update; \
    apt-get install -y --no-install-recommends gpg gpgv; \
    cd /tmp; \
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

# Composer must have git and unzip. The -dev packages are necessary only for the build.
# The purge keeps the runtime libraries that the extensions use.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends git unzip; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get install -y --no-install-recommends libicu-dev libpq-dev libzip-dev; \
    docker-php-ext-install -j"$(nproc)" bcmath intl pdo_mysql pdo_pgsql zip; \
    pecl install pcov; \
    docker-php-ext-enable pcov; \
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark > /dev/null; \
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
