# cargo-binstall 1.26.2 bump and weekly tool-version checker

Two commits land here. The first bumps cargo-binstall from 1.26.1 to 1.26.2 in both
rust-ci and rust-desktop Dockerfiles with the correct version and SHAs from the task spec.
The second adds a bash script that reads five pinned tool versions from source files, queries
GitHub Releases, and updates any outdated tool with verified SHAs, together with a GitHub
Actions workflow that runs the script weekly and opens a PR for any updates found. A prior
CHANGES_REQUESTED pass prompted the coder to extend SHA updates to all five tools (not just
cargo-binstall), which is the correct behaviour. The coder verified the script with shellcheck,
actionlint, and a live dry-run (all five tools current, exit 0).

Watch for: (1) The `actions/checkout` pin carries a `# v7` comment — v7 does not exist; the
current stable release is v4, and the SHA needs verification against the actual v4.x release.
(2) The PR-creation branch name `chore/tool-versions-$(date +%Y-%m-%d)` collides on same-day
re-runs, causing `git push` to fail on the second run.

**Verdict**: CHANGES_REQUESTED

---

## High-level view

The cargo-binstall bump is clean. Both Dockerfiles show version 1.26.2 and both architecture
SHAs match the task spec exactly. hadolint reported no findings on either file.

The check script follows a consistent pattern across all five tools: read the pinned version
from source, call GitHub's `releases/latest` API, compare, and — when outdated — download the
upstream checksum file, verify the archive or binary against it, and write the new version and
SHA back into the source file. The verification step before each update means the script
cannot silently write a wrong hash. The exit-code contract (`0 = current`, `1 = any updated`)
integrates cleanly with the workflow's `continue-on-error` + `outcome == 'failure'` gate.

The workflow permissions are structured correctly: top-level `contents: read`, job-level
`contents: write` and `pull-requests: write`. The runner is ubuntu-24.04. Each step name
carries an emoji with the condition prefix first on the conditional step. Two issues need fixing
before this is mergeable: the checkout action pin comment is wrong, and the branch naming
strategy has no collision guard.

---

<details>
<summary>Issues (4)</summary>

1. **actions/checkout pin comment wrong** — The comment says `# v7` but v7 does not exist; the
   current stable release is v4. The SHA `3d3c42e5aac5ba805825da76410c181273ba90b1` needs
   verification against the actual v4.x release SHA. Replace with the confirmed v4.x SHA and
   the correct `# v4` (or `# v4.x.y`) comment.

2. **Branch name collision on same-day re-runs** — `branch="chore/tool-versions-$(date +%Y-%m-%d)"`
   produces the same name if the workflow runs more than once in one calendar day (e.g., a
   scheduled run and a manual `workflow_dispatch` the same day). The second `git push origin "$branch"`
   fails because the remote branch already exists. Append a uniqueness token such as
   `${{ github.run_number }}` or the run ID to the branch name.

3. **`git add -A` stages all changes** — On a fresh runner only the files modified by the script
   will be dirty, so harm is unlikely in practice. Staging the specific files
   (`rust-ci/Dockerfile`, `rust-desktop/Dockerfile`, `document-tools/Dockerfile`,
   `ci/install-tools.sh`) follows the repository convention and removes the theoretical risk of
   committing runner-generated artefacts.

4. **Version strings with dots unescaped in sed patterns** — `${cur_crane}`, `${cur_proot}`, and
   `${cur_jq}` are interpolated directly into sed regexes, where `.` is a wildcard. For
   structured comment lines the chance of a wrong match is very low, but the patterns are
   technically incorrect. Escape the dots, e.g. `$(printf '%s' "$cur_crane" | sed 's/\./\\./g')`.

</details>

---

<details>
<summary>Details</summary>

### cargo-binstall pin values

Both Dockerfiles change `ARG BINSTALL_VERSION` from `1.26.1` to `1.26.2` and replace both
`binstall_sha` literals:

- x86_64: `9e0e064f189a9abb9f8df5fb93c3c810ef5cc19e7212d998c7a64c9e4d3527d5` — confirmed correct per task spec
- aarch64: `a235250cd684af9bf1e3a1e4c216b1d36e6c553553d5d789744f27689d81c2d6` — confirmed correct per task spec

The changes are symmetric: the same three-line sed transformation applies to both files via a
`for df in rust-ci/Dockerfile rust-desktop/Dockerfile` loop in the script, and the static
Dockerfile edits in this PR match. hadolint passed on both files.

### actions/checkout SHA and comment mismatch (possible)

```yaml
uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1  # v7
```

The actions/checkout action is at v4.x as of this writing; v7 does not exist. The comment is
confirmed wrong. Whether the 40-character SHA itself is the correct pin for a v4.x release
cannot be verified from the diff alone, but the wrong comment is a signal that the pin was not
looked up carefully. actionlint validates workflow syntax but does not check that a pinned SHA
corresponds to a named release. Verify the SHA against `actions/checkout`'s tag list before
merging.

### Branch name collision (confirmed)

```bash
branch="chore/tool-versions-$(date +%Y-%m-%d)"
git checkout -b "$branch"
git push origin "$branch"
```

If this step runs twice on the same calendar date the remote branch already exists, and
`git push` exits non-zero, failing the step. The weekly schedule alone is safe (each Monday
produces a new date), but `workflow_dispatch` can trigger an extra run on any day including
a scheduled Monday. A simple fix:

```bash
branch="chore/tool-versions-$(date +%Y-%m-%d)-${{ github.run_number }}"
```

### Update coverage beyond the task spec

The task spec described other tools as "version string only" updates, but the implementation
correctly updates SHAs alongside versions for Typst (`document-tools/Dockerfile`), crane,
proot, and jq (`ci/install-tools.sh`). Updating only the version while leaving an old SHA
would cause the archive verification step in each Dockerfile or install script to fail, so
the more thorough approach is correct and the spec was imprecise.

### sed unescaped dots (confirmed; very low risk)

The version-reading functions interpolate `${cur_crane}`, `${cur_proot}`, and `${cur_jq}` into
`sed -e "s/..."` patterns. A version like `0.20.2` contains two dots that act as wildcards,
so the pattern `0.20.2` matches `0X20Y2` in the same line. The comment lines being updated
follow a structured format with no plausible ambiguous matches, so the risk of a wrong
substitution is very low. Escaping the dots removes the concern entirely.

### `git add -A` (confirmed rule; possible harm)

AGENTS.md requires specific-file staging. On a fresh ubuntu-24.04 runner with no additional
steps writing files, only the four source files modified by the script will be dirty, so
`git add -A` will not pick up anything extra in practice. Switching to explicit paths aligns
with the convention and eliminates the theoretical edge case.

</details>

---

<details>
<summary>File map</summary>

| File | Change |
|------|--------|
| `rust-ci/Dockerfile` | `BINSTALL_VERSION` bumped to 1.26.2; both arch SHAs updated |
| `rust-desktop/Dockerfile` | Same bump as rust-ci |
| `ci/check-tool-versions.sh` | New executable script; reads, queries, verifies, and updates five pinned tools |
| `.github/workflows/check-tool-versions.yml` | New workflow; weekly schedule + dispatch; creates PR on updates |

Full diff: `git -C c:\x\docker-gems\.worktrees\tool-version-updates diff main...HEAD`

</details>
