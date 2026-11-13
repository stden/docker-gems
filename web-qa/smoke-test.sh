#!/usr/bin/env bash
set -euo pipefail

work=$(mktemp -d)
server_pid=
cleanup() {
    local status=$?
    if [[ "$status" != 0 ]]; then
        for log in server.log axe.json lighthouse.json; do
            if [[ -f "$work/$log" ]]; then
                printf '\nDiagnostic file: %s\n' "$log" >&2
                cat "$work/$log" >&2
            fi
        done
    fi
    if [[ -n "$server_pid" ]]; then
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
    rm -rf "$work"
    exit "$status"
}
trap cleanup EXIT
cd "$work"

python --version
uv --version
pytest --version
behave --version
python -m playwright --version
google-chrome --version
node --version
npm --version
lighthouse --version
axe --version

cat > index.html <<'HTML'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Web QA smoke test</title>
<meta name="viewport" content="width=device-width, initial-scale=1"></head>
<body><main><h1>Web QA smoke test</h1>
<button type="button" onclick="this.textContent='Passed'">Run test</button>
</main></body></html>
HTML

python -u - <<'PY' > server.log 2>&1 &
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

server = ThreadingHTTPServer(("127.0.0.1", 0), SimpleHTTPRequestHandler)
Path("port").write_text(str(server.server_port))
server.serve_forever()
PY
server_pid=$!
for _attempt in {1..100}; do
    [[ -s port ]] && break
    kill -0 "$server_pid"
    sleep 0.1
done
test -s port
SMOKE_URL="http://127.0.0.1:$(cat port)/"
export SMOKE_URL

cat > test_browser.py <<'PY'
import os

import pytest
from playwright.sync_api import expect, sync_playwright


@pytest.mark.parametrize("channel", [None, "chrome"])
def test_local_page(channel):
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(
            channel=channel, args=["--no-sandbox", "--disable-dev-shm-usage"]
        )
        page = browser.new_page()
        response = page.goto(os.environ["SMOKE_URL"])
        assert response.status == 200
        expect(page).to_have_title("Web QA smoke test")
        page.get_by_role("button", name="Run test").click()
        expect(page.get_by_role("button", name="Passed")).to_be_visible()
        browser.close()
PY
pytest -q test_browser.py

mkdir -p features/steps
cat > features/page.feature <<'FEATURE'
Feature: Local page
  Scenario: The test page is available
    When I request the test page
    Then the page has the test title
FEATURE
cat > features/steps/page.py <<'PY'
import os
from urllib.request import urlopen

from behave import then, when


@when("I request the test page")
def request_page(context):
    with urlopen(os.environ["SMOKE_URL"], timeout=10) as response:
        context.page = response.read().decode()


@then("the page has the test title")
def check_title(context):
    assert "<title>Web QA smoke test</title>" in context.page
PY
behave --no-capture features

# Pipe communication also works when the backup CI runner uses PRoot.
axe "$SMOKE_URL" --exit --chrome-options="no-sandbox,disable-dev-shm-usage,remote-debugging-pipe" \
    --save axe.json
lighthouse "$SMOKE_URL" --quiet --only-categories=accessibility \
    --chrome-flags="--headless --no-sandbox --disable-dev-shm-usage" \
    --output=json --output-path=lighthouse.json
python - <<'PY'
import json
from pathlib import Path

axe = json.loads(Path("axe.json").read_text())
assert axe and not axe[0]["violations"], axe
report = json.loads(Path("lighthouse.json").read_text())
assert not report.get("runtimeError"), report.get("runtimeError")
assert report["categories"]["accessibility"]["score"] == 1, report["categories"]
print("Browser navigation, Behave, axe, and Lighthouse checks passed.")
PY
