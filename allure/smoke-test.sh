#!/usr/bin/env bash
# Run the offline steps of the tutorial in allure/README.md with hand-written allure-results.
# The test starts no web server: in GitLab CI, PRoot waits for every child process.
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

allure --version
allure2 --version
java -version
node --version

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# Print the value at a dotted path in a JSON file, for example: json summary.json stats.total
json() {
    node -e '
        let value = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
        for (const key of process.argv[2].split(".")) value = value?.[key];
        console.log(typeof value === "string" ? value : JSON.stringify(value));
    ' "$1" "$2"
}

# Check the test counts in a summary file: one passed, one failed, and one broken test.
expect_counts() {
    local file=$1 prefix=$2 pair key
    for pair in total:3 passed:1 failed:1 broken:1; do
        key=${pair%%:*}
        [[ "$(json "$file" "$prefix.$key")" == "${pair#*:}" ]] ||
            fail "$file: $prefix.$key is not ${pair#*:}"
    done
}

# Check that each line of the text occurs in at least one of the files.
expect_text() {
    local texts=$1 text
    shift
    while IFS= read -r text; do
        grep -qF -- "$text" "$@" || fail "'$text' is not in $*"
    done <<< "$texts"
}

# A single-file report embeds each data file as d("path","base64"). Write them to a directory.
unpack_single_file() {
    node - "$1" "$2" <<'JS'
const fs = require("node:fs");
const path = require("node:path");
const [html, out] = process.argv.slice(2);
const pattern = /\bd\((['"])([^'"]+)\1,(['"])([^'"]*)\3\)/g;
let count = 0;
for (const [, , file, , data] of fs.readFileSync(html, "utf8").matchAll(pattern)) {
    fs.mkdirSync(path.dirname(path.join(out, file)), { recursive: true });
    fs.writeFileSync(path.join(out, file), Buffer.from(data, "base64"));
    count += 1;
}
if (count === 0) throw new Error(`${html} contains no embedded report data`);
JS
}

# Step 1: write allure-results for one passed pytest test, one failed JUnit test, and one
# broken Playwright test. Use the documented format, as the adapters do. Each project writes
# its own results directory.
results=(allure-results target/allure-results e2e/allure-results)
mkdir -p "${results[@]}"
cat > allure-results/7f1c2d3e-0a4b-4c5d-8e6f-101112131415-result.json <<'JSON'
{
  "uuid": "7f1c2d3e-0a4b-4c5d-8e6f-101112131415",
  "historyId": "6b0a9a6f4c1e2d3b",
  "testCaseId": "0c9d4f3a2b1e6d5c",
  "name": "test_login",
  "fullName": "tests.test_shop#test_login",
  "status": "passed",
  "stage": "finished",
  "start": 1767225600000,
  "stop": 1767225601000,
  "labels": [
    {"name": "suite", "value": "test_shop"},
    {"name": "feature", "value": "Login"},
    {"name": "severity", "value": "critical"},
    {"name": "framework", "value": "pytest"},
    {"name": "language", "value": "cpython3"}
  ],
  "parameters": [{"name": "browser", "value": "chromium"}],
  "steps": [
    {"name": "Open the login page", "status": "passed", "stage": "finished",
     "start": 1767225600100, "stop": 1767225600400},
    {"name": "Submit valid credentials", "status": "passed", "stage": "finished",
     "start": 1767225600400, "stop": 1767225600900}
  ]
}
JSON
cat > target/allure-results/8a2b3c4d-1e2f-4a5b-9c6d-161718192021-result.json <<'JSON'
{
  "uuid": "8a2b3c4d-1e2f-4a5b-9c6d-161718192021",
  "historyId": "4d3c2b1a0f9e8d7c",
  "testCaseId": "1a2b3c4d5e6f7a8b",
  "name": "shouldAddItemToCart",
  "fullName": "shop.CartTest.shouldAddItemToCart",
  "status": "failed",
  "statusDetails": {
    "message": "expected: <2> but was: <1>",
    "trace": "org.opentest4j.AssertionFailedError: expected: <2> but was: <1>\n\tat shop.CartTest.shouldAddItemToCart(CartTest.java:21)"
  },
  "stage": "finished",
  "start": 1767225601000,
  "stop": 1767225602500,
  "labels": [
    {"name": "suite", "value": "shop.CartTest"},
    {"name": "feature", "value": "Cart"},
    {"name": "framework", "value": "junit-platform"},
    {"name": "language", "value": "java"}
  ],
  "steps": [
    {"name": "Add the item to the cart", "status": "failed", "stage": "finished",
     "start": 1767225601100, "stop": 1767225602400,
     "statusDetails": {"message": "expected: <2> but was: <1>"},
     "attachments": [{"name": "Cart log", "type": "text/plain",
                      "source": "9b3c4d5e-2f3a-4b5c-8d6e-222324252627-attachment.txt"}]}
  ]
}
JSON
printf 'cart items: 1\n' > target/allure-results/9b3c4d5e-2f3a-4b5c-8d6e-222324252627-attachment.txt
cat > e2e/allure-results/a0b1c2d3-3e4f-4a5b-8c6d-282930313233-result.json <<'JSON'
{
  "uuid": "a0b1c2d3-3e4f-4a5b-8c6d-282930313233",
  "historyId": "9e8d7c6b5a4f3e2d",
  "testCaseId": "2b3c4d5e6f7a8b9c",
  "name": "checkout page shows the total",
  "fullName": "checkout.spec.ts#checkout page shows the total",
  "status": "broken",
  "statusDetails": {"message": "TimeoutError: locator.click: Timeout 5000ms exceeded."},
  "stage": "finished",
  "start": 1767225603000,
  "stop": 1767225604000,
  "labels": [
    {"name": "parentSuite", "value": "chromium"},
    {"name": "suite", "value": "checkout.spec.ts"},
    {"name": "framework", "value": "playwright"},
    {"name": "language", "value": "javascript"}
  ],
  "steps": [
    {"name": "Click Checkout", "status": "broken", "stage": "finished",
     "start": 1767225603100, "stop": 1767225603900}
  ]
}
JSON

# Step 2: add the environment and the executor.
cat > allure-results/environment.properties <<'PROPERTIES'
Browser=chromium
Base.URL=https://shop.example.com
PROPERTIES
cat > allure-results/executor.json <<'JSON'
{"name": "GitHub Actions", "type": "github", "buildName": "Shop CI #42", "buildOrder": 42,
 "buildUrl": "https://github.com/example/shop/actions/runs/42"}
JSON

report_texts=$(printf '%s\n' test_login shouldAddItemToCart 'checkout page shows the total' \
    'Add the item to the cart' 'expected: <2> but was: <1>')
attachment_text='cart items: 1'
environment_texts=$(printf '%s\n' Browser chromium https://shop.example.com)
executor_text='Shop CI #42'

# Step 3: generate an Allure 3 report two times. The history file keeps both runs.
cat > allurerc.json <<'JSON'
{
  "name": "Shop tests",
  "output": "allure-report",
  "historyPath": "allure-history.jsonl",
  "historyLimit": 20
}
JSON
allure generate "${results[@]}" --clean
allure generate "${results[@]}" --clean
test -s allure-report/index.html
[[ "$(json allure-report/summary.json name)" == 'Shop tests' ]] || fail 'Allure 3 report name'
expect_counts allure-report/summary.json stats
expect_text "$report_texts" allure-report/data/test-results/*.json
expect_text "$attachment_text" allure-report/data/attachments/*
expect_text "$environment_texts" allure-report/widgets/allure_environment.json
expect_text "$executor_text" allure-report/index.html
[[ "$(wc -l < allure-history.jsonl)" == 2 ]] || fail 'allure-history.jsonl does not have 2 runs'
echo 'Allure 3 report, environment, executor, and history: OK'

# Step 4: generate an Allure 3 report as one HTML file.
allure awesome "${results[@]}" --single-file -o single-report
[[ ! -e single-report/data ]] || fail 'Allure 3 single-file report has a data directory'
unpack_single_file single-report/index.html single-data
expect_counts single-report/summary.json stats
expect_text "$report_texts" single-data/data/test-results/*.json
expect_text "$attachment_text" single-data/data/attachments/*
echo 'Allure 3 single-file report: OK'

# Step 5: generate an Allure 2 report two times. Copy the history of the first report
# into a results directory before the second run.
allure2 generate "${results[@]}" -o allure2-report --clean
cp -r allure2-report/history allure-results/history
allure2 generate "${results[@]}" -o allure2-report --clean
test -s allure2-report/index.html
expect_counts allure2-report/widgets/summary.json statistic
expect_text "$report_texts" allure2-report/data/test-cases/*.json
expect_text "$attachment_text" allure2-report/data/attachments/*
expect_text "$environment_texts" allure2-report/widgets/environment.json
expect_text "$executor_text" allure2-report/widgets/executors.json
[[ "$(json allure2-report/widgets/history-trend.json length)" == 2 ]] ||
    fail 'the Allure 2 history trend does not have 2 runs'
echo 'Allure 2 report, environment, executor, and history: OK'

# Step 6: generate an Allure 2 report as one HTML file.
allure2 generate --single-file "${results[@]}" -o allure2-single --clean
[[ "$(ls allure2-single)" == index.html ]] || fail 'Allure 2 single-file report has other files'
unpack_single_file allure2-single/index.html allure2-single-data
expect_counts allure2-single-data/widgets/summary.json statistic
expect_text "$report_texts" allure2-single-data/data/test-cases/*.json
echo 'Allure 2 single-file report: OK'

echo 'Allure 3 and Allure 2 reports, history, and single-file reports passed.'
