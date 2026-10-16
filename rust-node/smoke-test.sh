#!/usr/bin/env bash
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

rustc --version
cargo --version
node --version
npm --version
git --version
cmake --version

cargo init --lib --name smoke --vcs none .
cargo test --offline
cargo fmt --check
cargo clippy --offline --all-targets -- -D warnings

cat > package.json <<'JSON'
{"name":"smoke","private":true,"scripts":{"test":"node --test smoke.test.cjs"}}
JSON
cat > smoke.test.cjs <<'JS'
const assert = require('node:assert/strict');
const test = require('node:test');
test('Node.js runs application code', () => {
    assert.equal([1, 2, 3].reduce((sum, value) => sum + value, 0), 6);
});
JS
npm --offline test

cat > openssl.c <<'C'
#include <openssl/evp.h>
#include <stdio.h>
int main(void) {
    unsigned char digest[EVP_MAX_MD_SIZE];
    unsigned int length = 0;
    if (EVP_Digest("test", 4, digest, &length, EVP_sha256(), NULL) != 1
            || length != 32 || digest[0] != 0x9f || digest[31] != 0x08) {
        return 1;
    }
    puts("OpenSSL compile, link, and SHA-256 checks passed.");
    return 0;
}
C
# pkg-config returns the separate compiler and linker arguments.
# shellcheck disable=SC2046
cc -Wall -Wextra -Werror openssl.c -o openssl-check $(pkg-config --cflags --libs openssl)
./openssl-check
echo "Rust, Node.js, and native library checks passed."
