#!/usr/bin/env bash
# Start Open WebUI with a temporary data directory and check its HTTP API.
set -euo pipefail

work=$(mktemp -d)
server_pid=
cleanup() {
    local status=$?
    if [[ "$status" != 0 && -f "$work/server.log" ]]; then
        printf '\nServer log:\n' >&2
        tail -n 100 "$work/server.log" >&2
    fi
    if [[ -n "$server_pid" ]]; then
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
    rm -rf "$work"
    exit "$status"
}
trap cleanup EXIT

# Never use the data directory of a real installation.
# Do not connect to a model backend. The image already has its embedding models.
export DATA_DIR="$work/data" \
    WEBUI_SECRET_KEY=docker-gems-smoke-test \
    HOST=127.0.0.1 \
    PORT=18080 \
    ENABLE_OLLAMA_API=false \
    ENABLE_OPENAI_API=false \
    OFFLINE_MODE=true
mkdir -p "$DATA_DIR"
url="http://127.0.0.1:$PORT"

python --version
bash /app/backend/start.sh > "$work/server.log" 2>&1 &
server_pid=$!
for _attempt in {1..180}; do
    curl -fsS "$url/health" > "$work/health.json" 2>/dev/null && break
    kill -0 "$server_pid"
    sleep 1
done
jq -e '.status == true' "$work/health.json"

curl -fsS "$url/api/config" > "$work/config.json"
jq -e '.name | contains("Open WebUI")' "$work/config.json"
jq -r '"Open WebUI " + .version' "$work/config.json"
curl -fsS "$url/" | grep -F '<title>Open WebUI</title>'

# The first account becomes the administrator.
jq -n '{name: "Smoke Test", email: "admin@example.com", password: "Smoke-test-password-1"}' \
    | curl -fsS -H 'Content-Type: application/json' -d @- "$url/api/v1/auths/signup" \
    > "$work/signup.json"
jq -e '.role == "admin" and (.token | length > 0)' "$work/signup.json"
token=$(jq -r '.token' "$work/signup.json")

curl -fsS -H "Authorization: Bearer $token" "$url/api/v1/auths/" > "$work/session.json"
jq -e '.email == "admin@example.com" and .role == "admin"' "$work/session.json"
curl -fsS -H "Authorization: Bearer $token" "$url/api/models" > "$work/models.json"
jq -e '.data | type == "array"' "$work/models.json"
# A request without a token must fail.
code=$(curl -sS -o /dev/null -w '%{http_code}' "$url/api/v1/auths/")
[[ "$code" == 401 || "$code" == 403 ]]
test -s "$DATA_DIR/webui.db"
echo "Server start, health, configuration, sign-up, sessions, and the models API passed."
