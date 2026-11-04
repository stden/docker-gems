# Educational refactor: teaching comments and "What you learn" sections across seven images

This PR adds educational inline comments to seven Dockerfiles and "What you learn" sections to their
READMEs, targeting school-olympiad students new to Docker. Comments shift from narrating WHAT each
instruction does to explaining WHY: build-cache order, pipefail semantics, multi-stage separation,
ENTRYPOINT clearing, and Playwright's apt dependency chain. All 14 commits are single-image and
the ordering (one refactor commit per image, then fix commits for byte-limit corrections) is clean.
Smoke tests passed locally for five images; allure and web-qa defer to CI because SSL inspection on
the build host blocked HTTPS downloads. Watch for: a confirmed STE regression in the top-level
`README.md` ("needs a database" replaces the approved form "is necessary"), and six of seven image
short descriptions that omit the Docker concept — deferring it entirely to "What you learn" — in
conflict with the stated review criterion.

**Verdict**: CHANGES_REQUESTED

## High-level view

The comment rewrite correctly prioritizes the WHY throughout. `my-python-app` explains the
caching layer-order pattern twice — once at the requirements copy and once at the source copy — which
reinforces the principle from both sides. `web-qa`'s Playwright/security-upgrade ordering comment
is the most educational addition: the original comment had this backward (it said "before the tools"
when Playwright actually runs first), and the new comment correctly explains the apt package
dependency chain.

`allure` gains two structural improvements alongside the comments: `SHELL ["/bin/bash", "-o",
"pipefail", "-c"]` is placed correctly before the pipe-heavy Maven Central download `RUN`, and
`WORKDIR /tmp` replaces an inline `cd /tmp`. Both satisfy AGENTS.md rules and fix the latent
DL4006 hadolint issue that existed in the original.

The `my-python-app` WORKDIR changed from `/x` to `/workspace`. The smoke test uses
`docker compose up --build` and does not reference the working directory path, so it passes
without change. The top-level `README.md` tutorial table and `docker run tree` example are updated
consistently.

One confirmed STE regression in the `refactor(README)` commit: "A database is necessary for the
`my-python-app` application" became "The `my-python-app` application needs a database." The
AGENTS.md word list prohibits "needs."

Fix commits shortened six of seven image short descriptions to stay under the 100-byte AGENTS.md
limit by removing Docker concept phrases. The commit messages document this as intentional:
"Docker concept is covered by the 'What you learn' section." `web-qa` successfully fits both in
one line ("in a multi-stage Python image"). Compact Docker-concept descriptors are feasible for
the six others within 100 bytes.

<details>
<summary>Issues (4)</summary>

1. **STE regression: "needs" in README.md** — "The `my-python-app` application needs a database"
   must become "must have a database" or revert to "A database is necessary for the `my-python-app`
   application." AGENTS.md explicitly prohibits "needs."

2. **Six short descriptions omit Docker concept** — allure, code-quality, java, my-python-app,
   python, and rust name only the tool purpose. The review criterion requires the first paragraph to
   name the Docker concept shown. Examples within 100 bytes:
   - code-quality → "Run seven static-analysis tools with multi-stage SHA-256 verification." (70 bytes)
   - rust → "Build, test, format, and lint Rust projects using rustup component add." (71 bytes)
   - python → "Test Python code with pytest, Ruff, mypy, and uv via COPY --from." (66 bytes)
   - java → "Build and test Java projects from an official JDK image with ENTRYPOINT reset." (77 bytes)
   - allure → "Generate Allure test reports using a multi-stage build with checksum verification." (82 bytes)
   - my-python-app → "A Python app showing build-cache layer order, Compose, and health checks." (73 bytes)

3. **allure and web-qa: no confirmed local test pass** — Both commits defer to CI ("CI validates
   the full build") because SSL inspection blocked HTTPS downloads on the build host. `allure` has
   functional changes (SHELL pipefail, WORKDIR /tmp); `web-qa` is comment-only. The review
   criterion requires test-pass confirmation from commit messages. For `allure`, the CI run result
   is not shown in the commit message — "CI validates the full build" is forward-looking, not a
   confirmed result.

4. **my-python-app CMD comment uses label-colon form** — "JSON array form: the OS sends signals
   to Python directly, without a shell wrapper." is not an imperative sentence. STE requires
   "Use the JSON array form. The OS then sends signals directly to Python, without a shell wrapper."

</details>

<details>
<summary>Details</summary>

### Build-cache layering: the my-python-app comment pair

`my-python-app` explains the caching pattern from two directions: "Copy requirements.txt before the
source code so pip runs only when dependencies change" and "Copy source files after dependencies so
a code change reuses the pip layer above." The top-level `README.md` table also promotes the same
idea, changing the COPY description from "Copies the dependency file from the build directory" to
"Copies the dependency file before the source code." A student who reads both files gets the same
teaching point twice, which is the right pattern for a concept that confuses most Docker beginners.

### web-qa: correcting a wrong original comment

The original `web-qa` Dockerfile said "Install the security updates of the base image before the
tools" — but the code installs Playwright first, then runs the security upgrade. The new comment
sequence correctly describes the actual behavior and explains WHY: "Playwright calls apt-get
internally to add browser dependencies. The security upgrade in the next step covers those packages
too." This is not just a comment polish; it fixes a misleading instruction that contradicted the
code. A student following the original comment would expect the security upgrade to run first and
would not understand why Playwright appears above it.

### allure: SHELL pipefail placement

`SHELL ["/bin/bash", "-o", "pipefail", "-c"]` is placed in the `download` stage after the apt-get
`RUN` (no pipe, no SHELL needed there) and before the Maven Central download `RUN` that uses
`| sed -n ... | sort -V | tail -n 1`. The `node:slim` final stage has no pipes, so no SHELL is
needed there. `WORKDIR /tmp` replaces `cd /tmp;` inside the `RUN`; this is the Docker-idiomatic
approach — WORKDIR applies to all subsequent `RUN` instructions in the stage and is more readable
than an inline directory change. Both changes are behavioral (they affect shell semantics and
working directory), not comment-only, which is why Issue 3 flags the missing local test confirmation.

### code-quality ENV comment loses specificity

The original comment explained what each ENV variable does:
> Semgrep does not check for a new version at each run... Trivy does not send usage data and does not
> call check.trivy.dev... A scan can pass --skip-db-update and stay offline.

The replacement reads: "ENV disables telemetry and configures each tool for non-interactive CI use."
This is too abstract for a beginner. A student reading `SEMGREP_ENABLE_VERSION_CHECK=0` will not
know what check it suppresses or why suppressing it matters in CI. One sentence restores the signal:
"SEMGREP_ENABLE_VERSION_CHECK=0 stops Semgrep from calling its update endpoint; TRIVY_NO_PROGRESS=1
suppresses the download progress bar in CI." The `code-quality` image is itself a teaching tool
for CI patterns — specificity here has direct educational value.

### Short description gap: 100-byte constraint vs. Docker-concept requirement

The fix commits shortened descriptions to under 100 bytes by removing Docker-concept phrases. The
commit bodies explicitly note: "Docker concept is covered by the 'What you learn' section." The
tension is real: fitting a clear Docker-concept descriptor alongside six to ten tool names is a
word-count puzzle. `web-qa` solved it by moving tools out ("Playwright, Chrome, axe, and Lighthouse")
and making the Docker concept the suffix ("in a multi-stage Python image"). The same pattern is
available for the other six images — see the Issue 2 examples. All proposed rewrites fit within
100 bytes.

### Test verification detail

java, python, rust, my-python-app: `bash test-images.sh → OK` in commit messages. code-quality:
smoke test passed via direct `docker run`; `test-images.sh` file-mount fails on Windows Git Bash
due to a path-translation issue in the runner, not the image. allure and web-qa: local builds
blocked by SSL inspection. For `allure`, the SHELL and WORKDIR changes alter build semantics (shell
mode and working directory); for `web-qa`, all Dockerfile changes are comments. The allure `RUN`
with `set -eux` and pipe already behaves correctly under bash, so SHELL pipefail strengthens it
rather than changing its success path. The absence of a confirmed CI-pass result remains a gap
against the review criterion.

</details>

<details>
<summary>File map (diff: 7c0228e0..HEAD, 15 files)</summary>

| File | Change |
|------|--------|
| `README.md` | Tutorial paragraphs tightened; WORKDIR reference and `docker run tree` example updated `/x` → `/workspace`; STE regression introduced ("needs a database") |
| `allure/Dockerfile` | Header comment rewritten for multi-stage teaching; SHELL pipefail added before Maven Central pipe; WORKDIR /tmp replaces inline cd; ENV, COPY, and npm supply-chain comments clarified |
| `allure/README.md` | Short description shortened to 50 bytes; "What you learn" section added |
| `code-quality/Dockerfile` | Header and ENV block comments simplified; fetch/verify comment expanded with "so the build fails if…" |
| `code-quality/README.md` | Short description shortened to 47 bytes; "What you learn" section added |
| `java/Dockerfile` | Base image source, ENTRYPOINT clearing rationale, and build-time version-check comments added |
| `java/README.md` | "What you learn" section added |
| `my-python-app/Dockerfile` | WORKDIR changed `/x` → `/workspace`; WHY comments replace WHAT comments; apt-get RUN reformatted as multi-line |
| `my-python-app/README.md` | Short description shortened to 53 bytes; WORKDIR reference updated; "What you learn" section added |
| `python/Dockerfile` | COPY --from rationale and one-layer pip comment added |
| `python/README.md` | Short description shortened to 67 bytes; "What you learn" section added |
| `rust/Dockerfile` | rustup identity and optional-component rationale comments added |
| `rust/README.md` | Short description shortened to 44 bytes; "What you learn" section added |
| `web-qa/Dockerfile` | Stage label, ENV rationale, COPY --from, npm symlink, and Playwright/security-upgrade ordering comments added; original "before the tools" comment corrected |
| `web-qa/README.md` | Short description updated to name multi-stage concept; "What you learn" section added |

</details>
