#!/usr/bin/env bash
# Test a small PHP project offline. No network is necessary. The test checks the extensions,
# the Composer autoloader, PHPUnit with pcov code coverage, and the exit code of a failed test.
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
# Keep the Composer files in the work directory. /tmp/composer can be a mounted cache.
export COMPOSER_HOME="$work/composer"

php --version
composer --version
phpunit --version
git --version
unzip -v | sed -n 1p

# Step 1: the extensions load without a startup warning and do their work.
modules=$(php -m 2>&1)
if grep -i 'warning' <<< "$modules"; then
    echo 'FAIL: PHP printed a startup warning.' >&2
    exit 1
fi
for extension in bcmath intl mbstring pcov pdo_mysql pdo_pgsql zip; do
    if ! grep -Fxq "$extension" <<< "$modules"; then
        echo "FAIL: php -m does not list $extension." >&2
        exit 1
    fi
done

cat > extensions.php <<'PHP'
<?php
function check(string $name, bool $passed): void
{
    if (!$passed) {
        fwrite(STDERR, "FAIL: $name\n");
        exit(1);
    }
    echo "$name: OK\n";
}

check('bcmath', bcadd('0.1', '0.2', 1) === '0.3');
check('intl', (new NumberFormatter('de_DE', NumberFormatter::DECIMAL))->format(1234.5) === '1.234,5');
check('mbstring', mb_strtoupper('straße') === 'STRASSE');
check('PDO drivers', array_diff(['mysql', 'pgsql'], PDO::getAvailableDrivers()) === []);
$zip = new ZipArchive();
check('zip write', $zip->open('test.zip', ZipArchive::CREATE) === true
    && $zip->addFromString('note.txt', 'zip works') && $zip->close());
check('zip read', $zip->open('test.zip') === true && $zip->getFromName('note.txt') === 'zip works');
check('memory limit', ini_get('memory_limit') === '-1');
PHP
php extensions.php
test "$(unzip -p test.zip note.txt)" = 'zip works'

# Step 2: write a project with a PSR-4 autoloader and no external dependencies.
mkdir src tests failing
cat > composer.json <<'JSON'
{
    "name": "docker-gems/calculator",
    "description": "Smoke test project for the stden/php image.",
    "type": "project",
    "license": "MIT",
    "require": {
        "php": ">=8.2"
    },
    "autoload": {
        "psr-4": {"App\\": "src/"}
    },
    "autoload-dev": {
        "psr-4": {"Tests\\": "tests/"}
    }
}
JSON
cat > src/Calculator.php <<'PHP'
<?php

declare(strict_types=1);

namespace App;

final class Calculator
{
    public function add(int $a, int $b): int
    {
        return $a + $b;
    }

    public function divide(int $a, int $b): float
    {
        if ($b === 0) {
            throw new \DivisionByZeroError('Division by zero.');
        }

        return $a / $b;
    }
}
PHP
cat > tests/CalculatorTest.php <<'PHP'
<?php

declare(strict_types=1);

namespace Tests;

use App\Calculator;
use PHPUnit\Framework\TestCase;

final class CalculatorTest extends TestCase
{
    public function testAdd(): void
    {
        $this->assertSame(5, (new Calculator())->add(2, 3));
    }

    public function testDivide(): void
    {
        $this->assertSame(2.0, (new Calculator())->divide(6, 3));
    }
}
PHP
cat > failing/FailingTest.php <<'PHP'
<?php

declare(strict_types=1);

use App\Calculator;
use PHPUnit\Framework\TestCase;

final class FailingTest extends TestCase
{
    public function testWrongSum(): void
    {
        $this->assertSame(6, (new Calculator())->add(2, 3));
    }
}
PHP
cat > phpunit.xml <<'XML'
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
XML

# Step 3: validate composer.json. Then generate the autoloader.
composer validate --strict --no-check-lock
composer dump-autoload --no-interaction
test -f vendor/autoload.php

# Step 4: run the tests with pcov coverage. The tests do not reach the exception line,
# so they cover 3 of the 4 executable lines.
phpunit --colors=never --coverage-text | tee coverage.log
grep -F 'with PCOV' coverage.log
grep -F 'OK (2 tests, 2 assertions)' coverage.log
grep -E '^ +Methods: +50\.00% \(1/2\)' coverage.log
grep -E '^ +Lines: +75\.00% \(3/4\)' coverage.log

# Step 5: if a test fails, PHPUnit exits with status 1.
status=0
phpunit --colors=never failing > failing.log || status=$?
cat failing.log
if [[ "$status" != 1 ]] || ! grep -Fq 'FAILURES!' failing.log; then
    echo "FAIL: a failing test gave exit status $status, not 1." >&2
    exit 1
fi
echo "Extension, Composer, PHPUnit, pcov coverage, and failing test checks passed."
