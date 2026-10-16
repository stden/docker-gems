# stden/php

Test PHP projects in CI with PHP CLI, Composer, PHPUnit, pcov code coverage, and common extensions.

## Overview

This image runs the tests of a PHP project on a computer or in a CI job. It contains:

- PHP CLI, newest stable release. The base image is the official `php:latest` (Debian).
- [Composer](https://getcomposer.org/), newest release, from the official `composer:latest` image.
- [PHPUnit](https://phpunit.de/), newest stable PHAR, as the `phpunit` command. The build
  checks the GPG signature of the PHAR with the PHPUnit release key.
- [pcov](https://github.com/krakjoe/pcov) for fast line coverage in PHPUnit.
- The extensions `bcmath`, `intl`, `pdo_mysql`, `pdo_pgsql`, and `zip`, and the built-in
  `mbstring`, `pdo_sqlite`, `curl`, `dom`, `openssl`, `sodium`, and `xml`.
- `git` and `unzip`, which Composer uses to download packages.

The image uses `php.ini-development`, so PHP shows all errors and runs `assert()`. The memory
limit is off (`memory_limit = -1`), because the coverage of a large project uses much memory.
Composer keeps its settings and its cache in `/tmp/composer` (`COMPOSER_HOME`), so it also
works for a user without a home directory. `COMPOSER_ALLOW_SUPERUSER=1` stops the warning
when a CI job runs Composer as `root`. The working directory is `/workspace`. The default
command starts Bash.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` with the newest stable tools. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/php/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/php:latest
docker run --rm stden/php:latest bash -c 'php --version && composer --version && phpunit --version'
```

## Tutorial

Run the commands from the root of your project, where `composer.json` is. The commands
mount the project directory at `/workspace`. `--user "$(id -u):$(id -g)"` runs the container
as your user, so `vendor/`, `composer.lock`, and the coverage reports belong to you.

### Step 1: Install the dependencies with Composer

```sh
mkdir -p "$HOME/.cache/composer"
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/workspace \
  -v "$HOME/.cache/composer":/tmp/composer/cache \
  stden/php:latest composer install --no-interaction --prefer-dist
```

The second volume keeps the Composer download cache between runs. Create the cache
directory before the first run. If Docker creates it, it belongs to `root`.

### Step 2: Run PHPUnit

```sh
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/workspace \
  stden/php:latest vendor/bin/phpunit
```

`vendor/bin/phpunit` is the PHPUnit version that `composer.lock` sets. If `phpunit/phpunit`
is not a dependency of the project, use the `phpunit` command of the image. To get a shell
in the project, add `-it` and do not give a command. The default command is `bash`.

### Step 3: Measure the code coverage with pcov

PHPUnit must have a `<source>` element in `phpunit.xml`. This element tells PHPUnit which
files to report:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit bootstrap="vendor/autoload.php" cacheDirectory=".phpunit.cache"
         failOnWarning="true" failOnRisky="true">
    <testsuites>
        <testsuite name="unit">
            <directory>tests</directory>
        </testsuite>
    </testsuites>
    <source>
        <include>
            <directory>src</directory>
        </include>
    </source>
</phpunit>
```

```sh
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/workspace \
  stden/php:latest vendor/bin/phpunit --coverage-text --coverage-html coverage
```

Open `coverage/index.html` for the report. The `Runtime:` line of the PHPUnit output must
show `with PCOV`. pcov collects data only for files in the directory `pcov.directory`. By
default, this is `src`, `lib`, or `app` in the current directory. If none of them exists, it
is the current directory. If your code is in a different directory, set it:

```sh
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/workspace stden/php:latest \
  php -d pcov.directory=/workspace/modules vendor/bin/phpunit --coverage-text
```

### Step 4: Test with a database

Integration tests must have a database server. Start PostgreSQL in a Docker network. Give
the connection settings to the tests in environment variables. The test code reads them,
for example `new PDO(getenv('DB_DSN'), getenv('DB_USER'), getenv('DB_PASSWORD'))`.

```sh
docker network create php-tests
docker run -d --name php-tests-db --network php-tests \
  -e POSTGRES_PASSWORD=test -e POSTGRES_DB=app_test postgres:latest
until docker exec php-tests-db pg_isready -h localhost -U postgres; do sleep 1; done

docker run --rm --user "$(id -u):$(id -g)" --network php-tests -v "$PWD":/workspace \
  -e DB_DSN="pgsql:host=php-tests-db;dbname=app_test" -e DB_USER=postgres -e DB_PASSWORD=test \
  stden/php:latest vendor/bin/phpunit

docker rm -f php-tests-db
docker network rm php-tests
```

For MySQL, use `mysql:latest` with `MYSQL_ROOT_PASSWORD` and `MYSQL_DATABASE`, and the DSN
`mysql:host=php-tests-db;dbname=app_test`. The password `test` is a placeholder for a
disposable test database.

### Step 5: Add an extension in a child image

The image has the `docker-php-ext-install`, `docker-php-ext-enable`, and `pecl` tools of
the official PHP image. Add the extensions that are necessary for your project:

```dockerfile
FROM stden/php:latest
RUN apt-get update \
 && apt-get install -y --no-install-recommends libpng-dev \
 && docker-php-ext-install gd \
 && rm -rf /var/lib/apt/lists/*
```

## Use the image in CI

### GitHub Actions

The job runs in the image. The PostgreSQL service has the host name `postgres`.

```yaml
name: PHP tests
on: [push, pull_request]
permissions:
  contents: read
jobs:
  phpunit:
    runs-on: ubuntu-latest
    container: stden/php:latest
    services:
      postgres:
        image: postgres:latest
        env:
          POSTGRES_DB: app_test
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 5s
          --health-timeout 5s
          --health-retries 10
    env:
      DB_DSN: pgsql:host=postgres;dbname=app_test
      DB_USER: postgres
      DB_PASSWORD: test
    steps:
      - uses: actions/checkout@v7
      - uses: actions/cache@v6
        with:
          path: /tmp/composer/cache
          key: composer-${{ hashFiles('composer.lock') }}
          restore-keys: composer-
      - run: composer validate --strict
      - run: composer install --no-interaction --prefer-dist --no-progress
      - run: vendor/bin/phpunit --coverage-text --coverage-clover coverage.xml
```

### GitLab CI

The job runs in the image. The MySQL service has the host name `mysql`. GitLab reads the
coverage percentage from the `Lines:` line and shows the test results in the merge request.

```yaml
phpunit:
  image: stden/php:latest
  services:
    - name: mysql:latest
      alias: mysql
  variables:
    MYSQL_DATABASE: app_test
    MYSQL_ROOT_PASSWORD: test
    DB_DSN: "mysql:host=mysql;dbname=app_test"
    DB_USER: root
    DB_PASSWORD: test
    COMPOSER_CACHE_DIR: "$CI_PROJECT_DIR/.composer-cache"
  cache:
    key:
      files: [composer.lock]
    paths: [.composer-cache/]
  script:
    - composer validate --strict
    - composer install --no-interaction --prefer-dist --no-progress
    - vendor/bin/phpunit --colors=never --coverage-text --log-junit junit.xml --coverage-cobertura coverage.xml
  coverage: '/^\s*Lines:\s*\d+\.\d+%/'
  artifacts:
    when: always
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
```

GitLab caches only files in the project directory. For this reason, `COMPOSER_CACHE_DIR`
points into the project.

## Best practices

- **Commit `composer.lock`.** Then CI installs the same package versions as your computer.
  Run `composer install` in CI. Run `composer update` only when you want new versions.
- **Install without questions.** Use `composer install --no-interaction --prefer-dist`.
  `--prefer-dist` downloads release archives and does not clone git repositories. This is
  faster and uses less disk space. Add `--no-progress` to keep the CI log short.
- **Cache the Composer cache, not `vendor/`.** Use `composer.lock` in the cache key. With a
  warm cache, `composer install` does not download the packages again.
- **Use pcov for coverage, not Xdebug.** pcov collects only line coverage, and it is much
  faster. Use Xdebug only for branch coverage or a step debugger. Do not load pcov and
  Xdebug together.
- **Use the PHPUnit version of the project.** Add `phpunit/phpunit` to `require-dev`. Run
  `vendor/bin/phpunit`. Then all developers and CI use the same version.
- **Make PHPUnit strict.** Set `failOnWarning` and `failOnRisky` in `phpunit.xml`. Put the
  PHPUnit cache in `.phpunit.cache`. Add this directory to `.gitignore`.
- **Check the dependencies.** Run `composer validate --strict` on each change. Run
  `composer audit` to find packages with known security problems. It must have network access.
- **Use a disposable test database.** Start a new database service for each job. Do not
  connect tests to a shared or production database. Keep real passwords in the secret
  store of your CI system.
- **Run as your user on your computer.** Use `--user "$(id -u):$(id -g)"`, so that the
  container does not create files that belong to `root` in your project.

## Source and checks

The smoke test writes a small project with a PSR-4 autoloader and no external
dependencies. It validates `composer.json`, generates the autoloader with Composer, runs
PHPUnit with pcov, and checks the exact coverage numbers. If a test fails, PHPUnit must
exit with status 1. The test also checks that each extension loads without a warning and
works. It runs without network access.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/php/Dockerfile)
- [Smoke test](https://github.com/stden/docker-gems/blob/main/php/smoke-test.sh)
- [Overview source](https://github.com/stden/docker-gems/blob/main/php/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
- [Composer documentation](https://getcomposer.org/doc/)
- [PHPUnit documentation](https://docs.phpunit.de/)
