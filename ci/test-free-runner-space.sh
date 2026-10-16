#!/bin/bash
# Check that the runner cleanup deletes directories at the same time.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin"
export PATH="$WORK/bin:$PATH" TRACE="$WORK/trace" FAIL_PATH=

cat > "$WORK/bin/sudo" <<'MOCK'
#!/bin/bash
set -euo pipefail
path=${*: -1}
printf 'start %s\n' "$path" >> "$TRACE"
for _ in $(seq 1 50); do
  count=$(grep -c '^start ' "$TRACE" || true)
  [[ "$count" -ge 3 ]] && break
  sleep 0.05
done
if [[ "${FAIL_PATH:-}" == "$path" ]]; then
  printf 'fail %s\n' "$path" >> "$TRACE"
  exit 1
fi
rm -rf -- "$path"
printf 'done %s\n' "$path" >> "$TRACE"
MOCK
chmod +x "$WORK/bin/sudo"

failures=0

assert_overlap() {
  python3 - "$TRACE" <<'PY'
import sys

starts = dones = fails = 0
early = False
for line in open(sys.argv[1], encoding="utf-8"):
    kind = line.split()[0]
    if kind == "start":
        if dones or fails:
            early = True
        starts += 1
    elif kind == "done":
        dones += 1
    elif kind == "fail":
        fails += 1
ok = starts == 3 and dones + fails == 3 and not early
sys.exit(0 if ok else 1)
PY
}

run_case() {
  local scenario=$1 expected=$2
  shift 2
  local status=0
  mkdir -p "$WORK/a" "$WORK/b" "$WORK/c"
  : > "$TRACE"
  bash "$ROOT/ci/free-runner-space.sh" "$WORK/a" "$WORK/b" "$WORK/c" > "$WORK/output" 2>&1 || status=$?
  if [[ "$status" != "$expected" ]]; then
    echo "FAIL $scenario: expected exit $expected, got $status"
    cat "$WORK/output"
    failures=$((failures + 1))
    return
  fi
  if ! assert_overlap; then
    echo "FAIL $scenario: deletes did not overlap"
    cat "$TRACE"
    failures=$((failures + 1))
    return
  fi
  if [[ "$scenario" == "one-delete-fails" ]]; then
    if [[ -e "$WORK/a" || ! -e "$WORK/b" || -e "$WORK/c" ]]; then
      echo "FAIL $scenario: the failed directory must stay"
      failures=$((failures + 1))
      return
    fi
  elif [[ -e "$WORK/a" || -e "$WORK/b" || -e "$WORK/c" ]]; then
    echo "FAIL $scenario: a directory remains"
    failures=$((failures + 1))
    return
  fi
  echo "OK $scenario"
}

FAIL_PATH=
run_case all-delete 0
FAIL_PATH=$WORK/b
run_case one-delete-fails 1

if [[ "$failures" != 0 ]]; then
  echo "FAIL $failures runner cleanup checks"
  exit 1
fi
echo "Runner cleanup checks passed."
