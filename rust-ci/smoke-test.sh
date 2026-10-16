#!/usr/bin/env bash
set -euo pipefail

cargo nextest --version
cargo audit --version
cargo llvm-cov --version
cargo tarpaulin --version
cargo deny --version
cargo sqlx --version
cargo mutants --version
sccache --version
rustc --version
cargo --version
clang --version
mold --version
ld.lld --version
jq --version

work_dir=$(mktemp -d)
trap 'sccache --stop-server >/dev/null 2>&1 || true; rm -rf "$work_dir"' EXIT
export SCCACHE_DIR="$work_dir/cache"
export RUSTC_WRAPPER=sccache
export CARGO_INCREMENTAL=0
cd "$work_dir"
cargo init --lib --name rust_ci_smoke --vcs none .
cat >src/lib.rs <<'RS'
pub fn add(left: u64, right: u64) -> u64 {
    left + right
}

#[test]
fn adds_two_numbers() {
    assert_eq!(add(20, 22), 42);
}
RS
cargo fmt --check
cargo clippy --offline --all-targets -- -D warnings
cargo nextest run --offline
sccache --zero-stats
cargo build --offline --lib
cargo clean --offline
cargo build --offline --lib
sccache --show-stats --stats-format=json >cache-stats.json
jq -e '.stats.cache_hits.counts.Rust > 0' cache-stats.json

rust_host=$(rustc -vV | sed -n 's/^host: //p')
llvm_bin="$(rustc --print sysroot)/lib/rustlib/$rust_host/bin"
"$llvm_bin/llvm-cov" --version
"$llvm_bin/llvm-profdata" --version
printf 'int main(void) { return 0; }\n' >linker.c
for linker in mold lld; do
    clang -Wall -Werror -fuse-ld="$linker" linker.c -o "linker-$linker"
    "./linker-$linker"
done

# The sample test runs every line of the library. The ptrace engine of Tarpaulin must have
# extra container privileges, so use its LLVM engine.
cargo llvm-cov --offline --summary-only --fail-under-lines 100
cargo tarpaulin --offline --engine llvm --fail-under 100 --color never

# cargo-deny must reject a license that the policy does not allow.
# The licenses and bans checks do not use the advisory database.
sed -i '/^edition/a license = "MIT"' Cargo.toml
printf '[licenses]\nallow = ["Apache-2.0"]\n' >deny.toml
if cargo deny --offline check licenses >deny.log 2>&1; then
    echo "cargo-deny accepted a license that is not allowed." >&2
    exit 1
fi
grep -F 'license is not explicitly allowed' deny.log
cat >deny.toml <<'TOML'
[licenses]
allow = ["MIT"]

[bans]
multiple-versions = "deny"
TOML
cargo deny --offline check licenses bans

# sqlx-cli applies a migration to an SQLite file. This check does not use a database server.
export DATABASE_URL="sqlite://$work_dir/app.db"
cargo sqlx migrate add --sequential create_items
printf 'CREATE TABLE items (id INTEGER PRIMARY KEY);\n' >migrations/0001_create_items.sql
cargo sqlx database setup
cargo sqlx migrate info | tee migrate-info.txt
grep -qF '1/installed create items' migrate-info.txt

# List the mutants. Do not run them.
cargo mutants --list | tee mutants.txt
grep -qF 'replace + with - in add' mutants.txt
printf 'Rust CI smoke test passed.\n'
