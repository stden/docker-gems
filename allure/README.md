# stden/allure

Generate Allure 3 and Allure 2 reports in CI from pytest, Java, Behave, and Playwright results.

## Overview

[Allure Report](https://allurereport.org/) converts the `allure-results` files of a test run
to an HTML report with steps, attachments, history, and trends. The Allure adapters of
the test frameworks write these files. This image generates the report from them. It does
not run your tests.

The image contains:

- `allure`: [Allure Report 3](https://github.com/allure-framework/allure3), the newest
  release of the `allure` package on npm. npm checks the SHA-512 of each package. The build
  also checks the npm registry signatures of all installed packages.
- `allure2`: the [Allure Report 2](https://github.com/allure-framework/allure2) CLI, the
  newest 2.x release from Maven Central. The build checks the SHA-512 of the archive.
- Node.js for Allure 3 and the default Java runtime of Debian for Allure 2.

The base image is `node:slim`. The working directory is `/workspace`. The default command
starts Bash. The image sets `ALLURE_NO_ANALYTICS=true`. With this setting, Allure 2 does not
send usage data, and its reports do not load an analytics script. The Awesome and classic
reports of Allure 3 always contain the analytics script of Allure.

### Allure 3 or Allure 2

Both versions read the same `allure-results` format, and the Allure team releases both.

| Command | Use it when |
| --- | --- |
| `allure` (Allure 3) | You start a new report. You get the new Awesome report, history in one file, a single-file report, and quality gates. |
| `allure2` (Allure 2) | Your pipeline already uses Allure 2: its `history` directory, `categories.json`, Allure 2 plugins, or scripts that read the Allure 2 report files. |

`allure classic` of Allure 3 makes a report in the Allure 2 style. `allure migrate` shows
how Allure 2 commands map to Allure 3.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` with the newest Allure 3 and Allure 2 releases. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/allure/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/allure:latest
```

## Tutorial

Do these steps in your project directory. The commands mount the directory at
`/workspace` and run as your user, so the report files belong to you. Set short names for
the commands first:

```sh
alias allure='docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/workspace stden/allure:latest allure'
alias allure2='docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/workspace stden/allure:latest allure2'
```

### Step 1: Write allure-results

Add the Allure adapter to each test project. The adapter writes one JSON file for each
test and one file for each attachment. This tutorial uses three results directories:

| Tests | Adapter | Run the tests | Results directory |
| --- | --- | --- | --- |
| pytest, also with pytest-playwright | `pip install allure-pytest` | `pytest --alluredir=allure-results --clean-alluredir` | `allure-results` |
| Behave | `pip install allure-behave` | `behave -f allure_behave.formatter:AllureFormatter -o allure-results` | `allure-results` |
| JUnit 5 or 6 (Maven) | `io.qameta.allure:allure-jupiter` | `./mvnw verify` | `target/allure-results` |
| Cucumber-JVM (Maven) | `io.qameta.allure:allure-cucumber7-jvm` | `./mvnw verify` | `target/allure-results` |
| Playwright Test in `e2e/` | `npm install -D allure-playwright` | `npx playwright test --reporter=line,allure-playwright` | `e2e/allure-results` |

For Java, set the directory in `src/test/resources/allure.properties`:
`allure.results.directory=target/allure-results`. For Cucumber-JVM, also add the plugin
`io.qameta.allure.cucumber7jvm.AllureCucumber7Jvm` to `cucumber.plugin`. `allure-jupiter`
replaced `allure-junit5`. See the [Allure documentation](https://allurereport.org/docs/)
for each framework.

### Step 2: Add the environment and the executor

The report shows `environment.properties` on the overview page. `executor.json` names the
CI system and the build. Write both files into one results directory after the tests:

```sh
cat > allure-results/environment.properties <<'EOF'
Browser=chromium
Base.URL=https://staging.example.com
EOF
cat > allure-results/executor.json <<'EOF'
{"name": "GitHub Actions", "type": "github", "buildName": "CI #42", "buildOrder": 42,
 "buildUrl": "https://github.com/example/shop/actions/runs/42"}
EOF
```

### Step 3: Generate an Allure 3 report

```sh
allure generate allure-results target/allure-results e2e/allure-results -o allure-report --clean
```

Allure 3 merges the three directories into one report in `allure-report/`. The command
exits with 0 also when tests failed. The report reads its data files over HTTP. To see the
report, serve it with this command:

```sh
docker run --rm --init -p 8080:8080 -v "$PWD":/workspace stden/allure:latest \
  allure open allure-report --host 0.0.0.0 --port 8080
```

Open <http://localhost:8080>. Stop the server with Ctrl+C. In CI, do not serve the report.
Publish the static files.

### Step 4: Make a single HTML file

```sh
allure awesome allure-results target/allure-results e2e/allure-results --single-file -o allure-single
```

`allure-single/index.html` contains all data and attachments. Open it in a browser without
a web server, or attach it to a ticket. Use a directory report for large test runs.

### Step 5: Keep history between runs

Allure 3 keeps the history in one JSON Lines file. Put the settings into `allurerc.json` in
the project directory. `allure generate` reads this file from the current directory:

```json
{
  "name": "Shop tests",
  "output": "allure-report",
  "historyPath": "allure-history.jsonl",
  "historyLimit": 20
}
```

```sh
allure generate allure-results target/allure-results e2e/allure-results --clean
```

Each run adds one line to `allure-history.jsonl`, and `historyLimit` removes the oldest
lines. With history, the report shows trends and finds flaky tests. Keep the file between
CI runs, for example in a CI cache. The image can read `allurerc.json` and `allurerc.yaml`.
An `allurerc.mjs` file can import the `allure` package only if your project installs it.

### Step 6: Use Allure 2

```sh
allure2 generate allure-results target/allure-results e2e/allure-results -o allure2-report --clean
allure2 generate --single-file allure-results target/allure-results e2e/allure-results -o allure2-single --clean
```

Allure 2 keeps the history in the report, in `allure2-report/history`. Before the next
run, copy this directory into a results directory:

```sh
cp -r allure2-report/history allure-results/history
```

`allure2 open` serves a report only on localhost, so it does not work from a container.
Use the single file, or serve `allure2-report` with `allure open` from step 3.

## GitHub Actions

The `test` job runs the tests and uploads the results. The `report` job runs in this image.
It generates the report also when tests failed, keeps the history only for `main`, and
uploads the report as an artifact. On `main`, the `pages` job publishes the report to
GitHub Pages. Set **Settings > Pages > Source** to **GitHub Actions** first. Put
`allurerc.json` from step 5 into the repository.

```yaml
name: Tests
on:
  push:
    branches: [main]
  pull_request:
permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with:
          python-version: "3.x"
      - run: pip install pytest allure-pytest
      - run: pytest --alluredir=allure-results
      - uses: actions/upload-artifact@v7
        if: ${{ !cancelled() }}
        with:
          name: allure-results
          path: allure-results

  report:
    needs: test
    if: ${{ !cancelled() }}
    runs-on: ubuntu-latest
    container: stden/allure:latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/download-artifact@v8
        with:
          name: allure-results
          path: allure-results
      - name: Restore the history of main
        if: github.ref == 'refs/heads/main'
        uses: actions/cache/restore@v6
        with:
          path: allure-history.jsonl
          key: allure-history-${{ github.run_id }}
          restore-keys: allure-history-
      - name: Write the executor
        run: |
          cat > allure-results/executor.json <<EOF
          {"name": "GitHub Actions", "type": "github", "buildOrder": ${{ github.run_number }},
           "buildName": "Run ${{ github.run_number }}",
           "buildUrl": "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"}
          EOF
      - run: allure generate allure-results --clean
      - name: Save the history of main
        if: github.ref == 'refs/heads/main'
        uses: actions/cache/save@v6
        with:
          path: allure-history.jsonl
          key: allure-history-${{ github.run_id }}
      - uses: actions/upload-artifact@v7
        with:
          name: allure-report
          path: allure-report
      - uses: actions/upload-pages-artifact@v5
        if: github.ref == 'refs/heads/main'
        with:
          path: allure-report

  pages:
    needs: report
    if: ${{ !cancelled() && needs.report.result == 'success' && github.ref == 'refs/heads/main' }}
    runs-on: ubuntu-latest
    permissions:
      pages: write
      id-token: write
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v5
```

## GitLab CI

The `allure-report` job runs in this image after the tests. Only pipelines of the default
branch save the history to the cache. Other pipelines only read it. On the default branch,
the `pages` job publishes the report to GitLab Pages.

```yaml
stages: [test, report, deploy]

tests:
  stage: test
  image: python:latest
  script:
    - pip install pytest allure-pytest
    - pytest --alluredir=allure-results
  artifacts:
    when: always
    paths: [allure-results/]
    expire_in: 1 week

allure-report:
  stage: report
  image: stden/allure:latest
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: always
      variables:
        HISTORY_POLICY: pull-push
    - when: always
      variables:
        HISTORY_POLICY: pull
  cache:
    key: allure-history
    paths: [allure-history.jsonl]
    policy: $HISTORY_POLICY
  script:
    - >
      printf '{"name":"GitLab CI","type":"gitlab","buildOrder":%s,"buildName":"Pipeline %s","buildUrl":"%s"}\n'
      "$CI_PIPELINE_IID" "$CI_PIPELINE_IID" "$CI_PIPELINE_URL" > allure-results/executor.json
    - allure generate allure-results --clean
  artifacts:
    when: always
    paths: [allure-report/]
    expose_as: Allure report
    expire_in: 30 days

pages:
  stage: deploy
  image: stden/allure:latest
  needs: [allure-report]
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: always
  script:
    - mv allure-report public
  artifacts:
    paths: [public/]
```

A runner can lose its cache. Then the next report has no history, and the job does not
fail. For Allure 2, use `allure2 generate allure-results -o allure-report --clean`. With
Allure 2, keep the `allure-report/history` directory instead of the history file.

## Best practices

- **Start each run with empty results.** Old result files go into the next report. Use
  `pytest --clean-alluredir` or `mvn clean`, or delete the results directory before the
  tests. In CI, upload the results of each run as a separate artifact.
- **Add the environment and the executor.** Write `environment.properties` (browser, base
  URL, versions) and `executor.json` (CI system, build number, build URL) in each run. Then
  a reader can find the source of each report.
- **Do not commit generated files.** Add `allure-results/`, `allure-report/`, and
  `allure-history.jsonl` to `.gitignore`. Publish reports as CI artifacts or on GitHub Pages
  or GitLab Pages.
- **Keep history only for the default branch.** Then the runs of other branches and merge
  requests do not change the trends of `main`. Set `historyLimit` to keep the history file
  small.
- **Generate the report also when tests fail.** Use `if: ${{ !cancelled() }}` in GitHub
  Actions and `when: always` in GitLab CI. Let the test job decide if the pipeline fails.
- **Protect private data.** Reports contain logs, screenshots, and URLs. GitHub Pages of a
  public repository is public. Do not put secrets in steps, parameters, or attachments.

## Source and checks

The smoke test writes allure-results by hand into three directories. The results contain a
passed pytest test, a failed JUnit test with a step and an attachment, a broken Playwright
test, `environment.properties`, and `executor.json`. The test generates Allure 3 and Allure 2
reports two times. Then it checks the test names, the counts, the attachment, the
environment, the executor, and the history. It also unpacks the single-file report of each
version and checks its data. It does not start a web server.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/allure/Dockerfile)
- [Smoke test](https://github.com/stden/docker-gems/blob/main/allure/smoke-test.sh)
- [Overview source](https://github.com/stden/docker-gems/blob/main/allure/README.md)
- [Allure Report documentation](https://allurereport.org/docs/)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
