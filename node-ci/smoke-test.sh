#!/usr/bin/env bash
# Run a small script with Node.js, Bun, and pnpm. The test is offline and removes its files on exit.
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

cat > package.json <<'SRC'
{ "name": "smoke", "version": "1.0.0", "private": true, "scripts": { "start": "node index.mjs" } }
SRC
cat > index.mjs <<'SRC'
console.log("node-ok");
SRC

[[ "$(node index.mjs)" == node-ok ]] || fail "Node.js did not run the script"
echo "OK: Node.js runs a script"
[[ "$(npm run --silent start)" == node-ok ]] || fail "npm did not run the start script"
echo "OK: npm runs the start script"
[[ "$(bun run index.mjs)" == node-ok ]] || fail "Bun did not run the script"
echo "OK: Bun runs the script"
[[ "$(pnpm --silent run start)" == node-ok ]] || fail "pnpm did not run the start script"
echo "OK: pnpm runs the start script"
echo "All Node.js tools work."
