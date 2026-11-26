#!/usr/bin/env bash
# Run the steps of the tutorial in graphify/README.md on a small project.
set -euo pipefail

work=$(mktemp -d)
mcpo_pid=
cleanup() {
    local status=$?
    if [[ "$status" != 0 && -f "$work/mcpo.log" ]]; then
        printf '\nmcpo log:\n' >&2
        tail -n 50 "$work/mcpo.log" >&2
    fi
    if [[ -n "$mcpo_pid" ]]; then
        kill "$mcpo_pid" 2>/dev/null || true
        wait "$mcpo_pid" 2>/dev/null || true
    fi
    rm -rf "$work"
    exit "$status"
}
trap cleanup EXIT
cd "$work"

python --version
graphify --version
mcpo --help > /dev/null
# The optional extras that the Dockerfile installs.
python -c 'import anthropic, docx, graspologic_native, matplotlib, mcp, openai, openpyxl, pypdf, tree_sitter_sql, watchdog'

mkdir -p src generated
cat > src/helpers.py <<'PY'
def format_name(name):
    return name.title()
PY
cat > src/app.py <<'PY'
from helpers import format_name


class Greeter:
    def greet(self, name):
        return format_name(name)
PY
cat > src/client.js <<'JS'
export function loadUser(id) {
  return fetchUser(id);
}

function fetchUser(id) {
  return { id };
}
JS
cat > src/schema.sql <<'SQL'
CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL);
SQL
cat > generated/build.py <<'PY'
def generated_helper():
    return 0
PY
echo 'generated/' > .graphifyignore

# Step 1: build the graph. The check must not call a language model.
export GRAPHIFY_BACKEND=none
graphify extract . --code-only
graphify cluster-only . --no-label
test -s graphify-out/GRAPH_REPORT.md
test -s graphify-out/graph.html

# Step 2: query the graph.
graphify explain format_name | tee explain.txt
grep -F 'calls' explain.txt
grep -F 'src/app.py' explain.txt
graphify path Greeter format_name
graphify query 'Greeter' | grep -F 'format_name()'
graphify explain fetchUser | grep -F 'loadUser()'
# A query without a match exits with code 4.
status=0
graphify query 'no_such_symbol' || status=$?
[[ "$status" == 4 ]]

# Step 3: update the graph after a code change.
cat >> src/helpers.py <<'PY'


def shout(name):
    return format_name(name).upper()
PY
graphify update .
graphify explain 'shout()' | grep -F 'format_name()'

# Step 4: export the graph for a document.
graphify export svg
test -s graphify-out/graph.svg

# Step 5: connect an MCP client.
timeout 60 python - <<'PY'
import json
import subprocess
from pathlib import Path

graph = json.loads(Path("graphify-out/graph.json").read_text())
labels = {node["label"] for node in graph["nodes"]}
expected = {"Greeter", "format_name()", "shout()", "loadUser()", "fetchUser()", "users"}
assert expected <= labels, labels
assert "generated_helper()" not in labels, "The .graphifyignore file was not applied."

server = subprocess.Popen(
    ["graphify-mcp", "graphify-out/graph.json"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    text=True,
)


def send(message):
    server.stdin.write(json.dumps({"jsonrpc": "2.0", **message}) + "\n")
    server.stdin.flush()


def call(request_id, method, params):
    send({"id": request_id, "method": method, "params": params})
    while line := server.stdout.readline():
        message = json.loads(line)
        if message.get("id") == request_id:
            return message
    raise RuntimeError(f"The MCP server stopped before it answered {method}.")


try:
    init = call(
        1,
        "initialize",
        {
            "protocolVersion": "2025-11-25",
            "capabilities": {},
            "clientInfo": {"name": "docker-gems-smoke-test", "version": "1"},
        },
    )
    assert init["result"]["serverInfo"]["name"] == "graphify", init
    send({"method": "notifications/initialized"})
    tools = call(2, "tools/list", {})
    names = {tool["name"] for tool in tools["result"]["tools"]}
    assert {"query_graph", "shortest_path"} <= names, names
    answer = call(3, "tools/call", {"name": "query_graph", "arguments": {"question": "Greeter"}})
    text = "\n".join(part["text"] for part in answer["result"]["content"])
    assert "format_name()" in text, text
    server.stdin.close()
    assert server.wait(timeout=10) == 0
finally:
    if server.poll() is None:
        server.kill()
PY

# Step 6: publish the MCP tools as an OpenAPI server with mcpo.
key=docker-gems-smoke-test
url=http://127.0.0.1:18100
mcpo --host 127.0.0.1 --port 18100 --api-key "$key" --strict-auth -- \
    graphify-mcp graphify-out/graph.json > mcpo.log 2>&1 &
mcpo_pid=$!
for _attempt in {1..120}; do
    code=$(curl -s -o /dev/null -w '%{http_code}' "$url/openapi.json" || true)
    [[ "$code" != 000 ]] && break
    kill -0 "$mcpo_pid"
    sleep 0.5
done
# --strict-auth also protects the API description.
[[ "$code" == 401 ]]
curl -fsS -H "Authorization: Bearer $key" "$url/openapi.json" > openapi.json
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Authorization: Bearer wrong-key' \
    -H 'Content-Type: application/json' -d '{"question": "Greeter"}' "$url/query_graph")
[[ "$code" == 403 ]]
curl -fsS -X POST -H "Authorization: Bearer $key" -H 'Content-Type: application/json' \
    -d '{"question": "Greeter"}' "$url/query_graph" > answer.json
python - <<'PY'
import json
from pathlib import Path

paths = json.loads(Path("openapi.json").read_text())["paths"]
assert {"/query_graph", "/shortest_path", "/get_node"} <= paths.keys(), sorted(paths)
answer = json.loads(Path("answer.json").read_text())
assert "format_name()" in answer, answer
PY
kill "$mcpo_pid"
wait "$mcpo_pid"
mcpo_pid=
# The MCP server must stop with mcpo. A process that stays alive stops the GitLab CI job.
sleep 1
if pgrep -f 'graphify-mcp graphify-out/graph.json' > /dev/null; then
    echo 'graphify-mcp is still running after mcpo stopped.' >&2
    exit 1
fi
echo "Extraction, ignore rules, queries, update, SVG export, MCP, and mcpo checks passed."
