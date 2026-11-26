#!/usr/bin/env bash
# Run the steps of the tutorial in codegraph/README.md on a small project.
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

node --version
codegraph --version
mcpo --help > /dev/null
codegraph telemetry | grep -F 'Telemetry: disabled'

mkdir -p src
cat > src/format.ts <<'TS'
export function formatName(name: string): string {
  return name.toUpperCase();
}
TS
cat > src/greeter.ts <<'TS'
import { formatName } from "./format";

export class Greeter {
  greet(name: string): string {
    return formatName(name);
  }
}
TS
cat > src/format.test.ts <<'TS'
import { formatName } from "./format";

test("formats a name", () => expect(formatName("ada")).toBe("ADA"));
TS
cat > src/report.py <<'PY'
def build_report(rows):
    return [format_row(row) for row in rows]


def format_row(row):
    return str(row)
PY

# Step 1: index the project. CodeGraph keeps its database out of git.
codegraph init .
test -s .codegraph/codegraph.db
grep -Fx '*' .codegraph/.gitignore
codegraph status . | tee status.txt
grep -E 'Files: +4$' status.txt
grep -E 'typescript +3$' status.txt
grep -E 'python +1$' status.txt

# Step 2: query symbols and callers.
codegraph query formatName --json > query.json
codegraph callers formatName | tee callers.txt
grep -F 'greet' callers.txt
codegraph callers format_row | grep -F 'build_report'

# Step 3: find the tests for a change.
codegraph affected src/format.ts --json > affected.json

# Step 4: update the index after a code change.
cat > src/shout.ts <<'TS'
import { formatName } from "./format";

export function shout(name: string): string {
  return formatName(name) + "!";
}
TS
codegraph sync .
codegraph callees shout | grep -F 'formatName'
codegraph impact formatName | grep -F 'src/shout.ts'

# Step 5: connect an MCP client.
# Direct mode keeps the MCP server in this process tree.
# The default shared daemon stays alive after the client exits, and PRoot then waits for it.
export CODEGRAPH_NO_DAEMON=1
timeout 60 node - <<'JS'
const assert = require("node:assert/strict");
const { spawn } = require("node:child_process");
const fs = require("node:fs");
const readline = require("node:readline");

const query = JSON.parse(fs.readFileSync("query.json", "utf8"));
assert.equal(query[0].node.kind, "function");
assert.equal(query[0].node.filePath, "src/format.ts");
const affected = JSON.parse(fs.readFileSync("affected.json", "utf8"));
assert.deepEqual(affected.affectedTests, ["src/format.test.ts"]);

const server = spawn("codegraph", ["serve", "--mcp", "--path", process.cwd(), "--no-watch"], {
  stdio: ["pipe", "pipe", "inherit"],
});
const pending = new Map();
readline.createInterface({ input: server.stdout }).on("line", (line) => {
  const message = JSON.parse(line);
  pending.get(message.id)?.(message);
});
let nextId = 1;
function call(method, params) {
  const id = nextId++;
  server.stdin.write(JSON.stringify({ jsonrpc: "2.0", id, method, params }) + "\n");
  return new Promise((resolve) => pending.set(id, resolve));
}

(async () => {
  const init = await call("initialize", {
    protocolVersion: "2025-11-25",
    capabilities: {},
    clientInfo: { name: "docker-gems-smoke-test", version: "1" },
  });
  assert.equal(init.result.serverInfo.name, "codegraph");
  server.stdin.write(JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized" }) + "\n");
  const tools = await call("tools/list", {});
  assert.ok(tools.result.tools.some((tool) => tool.name === "codegraph_explore"), tools);
  const explore = await call("tools/call", {
    name: "codegraph_explore",
    arguments: { query: "Greeter formatName" },
  });
  const text = explore.result.content.map((part) => part.text).join("\n");
  assert.match(text, /formatName/);
  server.stdin.end();
  const code = await new Promise((resolve) => server.on("exit", resolve));
  assert.equal(code, 0);
})().catch((error) => {
  server.kill();
  console.error(error);
  process.exit(1);
});
JS

# Step 6: publish the MCP tools as an OpenAPI server with mcpo.
# CODEGRAPH_MCP_TOOLS adds tools to the default codegraph_explore tool. A project with
# fewer than 500 files gets only explore, search, and node in direct mode.
key=docker-gems-smoke-test
url=http://127.0.0.1:18101
CODEGRAPH_MCP_TOOLS=explore,search,node \
    mcpo --host 127.0.0.1 --port 18101 --api-key "$key" --strict-auth -- \
    codegraph serve --mcp --path "$PWD" --no-watch > mcpo.log 2>&1 &
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
    -H 'Content-Type: application/json' -d '{"symbol": "formatName"}' "$url/codegraph_node")
[[ "$code" == 403 ]]
curl -fsS -X POST -H "Authorization: Bearer $key" -H 'Content-Type: application/json' \
    -d '{"symbol": "formatName"}' "$url/codegraph_node" > node.json
curl -fsS -X POST -H "Authorization: Bearer $key" -H 'Content-Type: application/json' \
    -d '{"query": "Greeter formatName"}' "$url/codegraph_explore" > explore.json
node - <<'JS'
const assert = require("node:assert/strict");
const fs = require("node:fs");

const paths = Object.keys(JSON.parse(fs.readFileSync("openapi.json", "utf8")).paths);
assert.deepEqual(paths.sort(), ["/codegraph_explore", "/codegraph_node", "/codegraph_search"]);
// The node tool lists the callers of the symbol.
assert.match(JSON.parse(fs.readFileSync("node.json", "utf8")), /greet/);
assert.match(JSON.parse(fs.readFileSync("explore.json", "utf8")), /formatName/);
JS
kill "$mcpo_pid"
wait "$mcpo_pid"
mcpo_pid=
# The MCP server must stop with mcpo. A process that stays alive stops the GitLab CI job.
sleep 1
if pgrep -f 'codegraph serve --mcp' > /dev/null; then
    echo 'The CodeGraph MCP server is still running after mcpo stopped.' >&2
    exit 1
fi

# Step 7: remove CodeGraph from the project.
codegraph uninit --force .
test ! -e .codegraph
echo "Indexing, queries, affected tests, sync, MCP, mcpo, and uninit checks passed."
