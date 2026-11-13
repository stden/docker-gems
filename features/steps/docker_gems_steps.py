from __future__ import annotations

import json
from pathlib import Path
from behave import given, then, when

REPO_ROOT = Path(__file__).resolve().parents[2]


def _image_dirs() -> list[Path]:
    return sorted(
        p
        for p in REPO_ROOT.iterdir()
        if p.is_dir() and not p.name.startswith(".") and (p / "Dockerfile").is_file()
    )


@given("all top-level directories with a Dockerfile")
def step_given_all_image_dirs(context):
    context.image_dirs = _image_dirs()
    assert len(context.image_dirs) > 0


@when('each image overview "README.md" is checked')
def step_when_readmes_checked(context):
    context.readmes = [(d.name, d / "README.md") for d in context.image_dirs]


@then(
    'each file starts with "# stden/<directory>", has a blank second line, has a third line of at most 100 bytes, and is smaller than 25000 bytes.'
)
def step_then_readmes_valid(context):
    for name, rpath in context.readmes:
        assert rpath.is_file(), f"Missing README.md in {name}"
        raw = rpath.read_bytes()
        assert len(raw) < 25000, f"{name}/README.md exceeds 25000 bytes ({len(raw)})"
        lines = raw.decode("utf-8").splitlines()
        assert len(lines) >= 3, f"{name}/README.md has fewer than 3 lines"
        assert lines[0] == f"# stden/{name}", f"Expected '# stden/{name}', got '{lines[0]}'"
        assert lines[1] == "", f"Second line of {name}/README.md must be blank"
        third_bytes = len(lines[2].encode("utf-8"))
        assert 0 < third_bytes <= 100, f"Third line of {name}/README.md is {third_bytes} bytes"


@when('"ci/hub-categories.json" is checked')
def step_when_hub_categories_checked(context):
    context.categories = json.loads((REPO_ROOT / "ci" / "hub-categories.json").read_text(encoding="utf-8"))


@then("every image has between 1 and 3 Docker Hub categories.")
def step_then_hub_categories_valid(context):
    for d in context.image_dirs:
        assert d.name in context.categories, f"{d.name} missing from ci/hub-categories.json"
        cats = context.categories[d.name]
        assert isinstance(cats, list) and 1 <= len(cats) <= 3, f"Invalid categories for {d.name}: {cats}"


@given("the Java LTS image configurations")
def step_given_java_lts_configs(context):
    context.java_files = {
        "java/Dockerfile": (REPO_ROOT / "java" / "Dockerfile").read_text(encoding="utf-8"),
        "java-eks/pom.xml": (REPO_ROOT / "java-eks" / "pom.xml").read_text(encoding="utf-8"),
        "java-run-swing/Dockerfile": (REPO_ROOT / "java-run-swing" / "Dockerfile").read_text(encoding="utf-8"),
        "android/Dockerfile": (REPO_ROOT / "android" / "Dockerfile").read_text(encoding="utf-8"),
    }


@when(
    'the Java version is checked across "java/Dockerfile", "java-eks/pom.xml", "java-run-swing/Dockerfile", and "android/Dockerfile"'
)
def step_when_java_versions_checked(context):
    context.inspected_java = context.java_files


@then("all four files use Java 25.")
def step_then_all_use_java_25(context):
    assert "maven:3-amazoncorretto-25" in context.inspected_java["java/Dockerfile"]
    assert "<java.version>25</java.version>" in context.inspected_java["java-eks/pom.xml"]
    assert "openjdk25" in context.inspected_java["java-run-swing/Dockerfile"]
    assert "eclipse-temurin:25-jdk" in context.inspected_java["android/Dockerfile"]


@given('the service image "{rel_path}"')
def step_given_service_image(context, rel_path):
    context.service_dockerfile = (REPO_ROOT / rel_path).read_text(encoding="utf-8")


@when("the runtime user configuration is checked")
def step_when_runtime_user_checked(context):
    context.inspected_service = context.service_dockerfile


@then('it sets "{user_directive}".')
def step_then_sets_user(context, user_directive):
    assert user_directive in context.inspected_service


@given("all top-level Dockerfiles in the repository")
def step_given_all_dockerfiles(context):
    context.dockerfiles = [
        (d.name, (d / "Dockerfile").read_text(encoding="utf-8")) for d in _image_dirs()
    ]


@when("package repository instructions are checked")
def step_when_pkg_repos_checked(context):
    context.inspected_dockerfiles = context.dockerfiles


@then('no Dockerfile contains "--allow-insecure-repositories" or "--allow-unauthenticated".')
def step_then_no_insecure_apt(context):
    for name, content in context.inspected_dockerfiles:
        assert "--allow-insecure-repositories" not in content, f"Found in {name}/Dockerfile"
        assert "--allow-unauthenticated" not in content, f"Found in {name}/Dockerfile"


# ---------------------------------------------------------------------------
# AC-6 through AC-10 — manually written structure checks
# ---------------------------------------------------------------------------

import re as _re

_SECRET_ENV_RE = _re.compile(
    r"^\s*(?:ENV|ARG)\s+\S*(?:TOKEN|PASSWORD|SECRET|PRIVATE_KEY|API_KEY)\S*\s*="
    r"\s*(?!\s*$)(?!\$)",
    _re.IGNORECASE | _re.MULTILINE,
)


@then('every image has "languages-and-frameworks" in its category list.')
def step_then_languages_frameworks_in_all(context):
    for d in context.image_dirs:
        cats = context.categories.get(d.name, [])
        assert "languages-and-frameworks" in cats, (
            f'{d.name} is missing "languages-and-frameworks" in ci/hub-categories.json'
        )


@when('the "up.sh" and "up.cmd" files are checked')
def step_when_up_files_checked(context):
    context.up_check_dirs = context.image_dirs


@then('every image except "compilers", "latex", and "java-eks" has both "up.sh" and "up.cmd".')
def step_then_up_pairs_exist(context):
    excluded = {"compilers", "latex", "java-eks"}
    for d in context.up_check_dirs:
        if d.name in excluded:
            continue
        assert (d / "up.sh").is_file(), f"{d.name}/up.sh is missing"
        assert (d / "up.cmd").is_file(), f"{d.name}/up.cmd is missing"


@when("ENV instructions are checked for secret patterns")
def step_when_env_checked_for_secrets(context):
    context.inspected_dockerfiles = context.dockerfiles


@then("no Dockerfile sets a secret value in an ENV instruction.")
def step_then_no_env_secrets(context):
    for name, content in context.inspected_dockerfiles:
        m = _SECRET_ENV_RE.search(content)
        assert m is None, (
            f"{name}/Dockerfile may contain a secret in an ENV/ARG instruction: {m.group()!r}"
        )


@given('"argocd/Dockerfile" and "argocd/kubernetes/kustomization.yaml"')
def step_given_argocd_files(context):
    context.argocd_dockerfile = (REPO_ROOT / "argocd" / "Dockerfile").read_text(encoding="utf-8")
    context.argocd_kustomization = (
        REPO_ROOT / "argocd" / "kubernetes" / "kustomization.yaml"
    ).read_text(encoding="utf-8")


@when("the Argo CD version is checked in both files")
def step_when_argocd_version_checked(context):
    m = _re.search(r"quay\.io/argoproj/argocd:(v[\d.]+)", context.argocd_dockerfile)
    assert m, "Cannot find Argo CD version in argocd/Dockerfile"
    context.argocd_version = m.group(1)


@then("both files reference the same Argo CD version.")
def step_then_argocd_versions_match(context):
    assert context.argocd_version in context.argocd_kustomization, (
        f"Argo CD version {context.argocd_version!r} from Dockerfile "
        f"not found in kustomization.yaml"
    )


@given('"java-ui-browser/Dockerfile" and "android/Dockerfile"')
def step_given_gradle_dockerfiles(context):
    context.java_ui_dockerfile = (REPO_ROOT / "java-ui-browser" / "Dockerfile").read_text(
        encoding="utf-8"
    )
    context.android_dockerfile = (REPO_ROOT / "android" / "Dockerfile").read_text(
        encoding="utf-8"
    )


@when("the Gradle version is checked in both")
def step_when_gradle_versions_checked(context):
    m1 = _re.search(r"GRADLE_VERSION=([\d.]+)", context.java_ui_dockerfile)
    m2 = _re.search(r"GRADLE_VERSION=([\d.]+)", context.android_dockerfile)
    assert m1, "GRADLE_VERSION not found in java-ui-browser/Dockerfile"
    assert m2, "GRADLE_VERSION not found in android/Dockerfile"
    context.gradle_versions = (m1.group(1), m2.group(1))


@then("both files pin the same Gradle version.")
def step_then_same_gradle_version(context):
    ui, android = context.gradle_versions
    assert ui == android, (
        f"Gradle version mismatch: java-ui-browser uses {ui!r}, android uses {android!r}"
    )


# ---------------------------------------------------------------------------
# AC-11 through AC-22 — additional structure and toolchain checks
# ---------------------------------------------------------------------------

import shutil as _shutil
import subprocess as _subprocess
import tempfile as _tempfile
import os as _os

# Images that keep their own CMD or WORKDIR and are not checked for AC-11/AC-12.
SERVICE_IMAGES = {
    # Service images: keep their upstream CMD and entrypoint.
    "java-eks", "open-webui", "my-python-app",
    "argocd", "kafka", "rabbitmq", "mailpit", "minio", "wiremock",
    "postgres-vector-graph",
    # Special-purpose images with non-standard WORKDIR or CMD.
    "compilers", "java-run-swing",
}


@given('all shell scripts in the "ci/" directory')
def step_given_ci_scripts(context):
    context.ci_scripts = sorted((REPO_ROOT / "ci").glob("*.sh"))


@given('the "java-17/Dockerfile" file')
def step_given_java17_dockerfile(context):
    path = REPO_ROOT / "java-17" / "Dockerfile"
    if not path.is_file():
        context.scenario.skip("java-17/Dockerfile not found")
        return
    context.java17_content = path.read_text(encoding="utf-8")


@given('the "docker-gems.typ" file at the repository root')
def step_given_typst_file(context):
    path = REPO_ROOT / "docker-gems.typ"
    if not path.is_file():
        context.scenario.skip("docker-gems.typ not found")
        return
    context.typst_file = path


@given('the ".gitignore" file at the repository root')
def step_given_gitignore(context):
    path = REPO_ROOT / ".gitignore"
    assert path.is_file(), ".gitignore not found"
    context.gitignore_content = path.read_text(encoding="utf-8")


@when("Dockerfile instructions are checked for WORKDIR")
def step_when_workdir_checked(context):
    pass


@when("CMD instructions are checked in each Dockerfile")
def step_when_cmd_checked(context):
    pass


@when("RUN instructions with pipes are checked")
def step_when_pipes_checked(context):
    pass


@when("the last RUN instruction is checked for version commands")
def step_when_last_run_checked(context):
    pass


@when("pip install instructions are checked")
def step_when_pip_checked(context):
    pass


@when("npm install instructions are checked")
def step_when_npm_checked(context):
    pass


@when("each file is checked for a UTF-8 BOM")
def step_when_bom_checked(context):
    pass


@when('each image "README.md" is checked for a "What you learn" heading')
def step_when_readme_heading_checked(context):
    pass


@when("the base image tag is checked for the JDK version")
def step_when_jdk_tag_checked(context):
    pass


@when("the .gitignore entries are checked")
def step_when_gitignore_checked(context):
    pass


@when('"typst compile" is run on it')
def step_when_typst_compile(context):
    if not _shutil.which("typst"):
        context.scenario.skip("typst not on PATH")
        return
    with _tempfile.TemporaryDirectory() as tmp:
        result = _subprocess.run(
            ["typst", "compile", str(context.typst_file),
             _os.path.join(tmp, "out.pdf")],
            capture_output=True, cwd=str(REPO_ROOT)
        )
    context.typst_result = result


@when('"ci/lint-presentation.sh docker-gems.typ" is run')
def step_when_lint_presentation(context):
    if not _shutil.which("typst"):
        context.scenario.skip("typst not on PATH")
        return
    # Use relative paths so that Git Bash resolves them from cwd.
    typst_rel = context.typst_file.relative_to(REPO_ROOT).as_posix()
    result = _subprocess.run(
        ["bash", "ci/lint-presentation.sh", typst_rel],
        capture_output=True, cwd=str(REPO_ROOT)
    )
    context.lint_result = result


@then('every tool Dockerfile sets "WORKDIR /workspace".')
def step_then_workdir_workspace(context):
    for name, content in context.dockerfiles:
        if name in SERVICE_IMAGES:
            continue
        assert "WORKDIR /workspace" in content, (
            f"{name}/Dockerfile does not set WORKDIR /workspace"
        )


@then('every tool image ends with CMD ["bash"].')
def step_then_cmd_bash(context):
    for name, content in context.dockerfiles:
        if name in SERVICE_IMAGES:
            continue
        lines = [
            l.rstrip() for l in content.splitlines()
            if l.strip() and not l.strip().startswith("#")
        ]
        last = lines[-1].strip() if lines else ""
        assert last == 'CMD ["bash"]', (
            f'{name}/Dockerfile last instruction is {last!r}, expected CMD ["bash"]'
        )


@then('every Dockerfile with a pipe in a RUN has SHELL ["/bin/bash", "-o", "pipefail", "-c"] before it.')
def step_then_pipefail_shell(context):
    for name, content in context.dockerfiles:
        joined = []
        buf = ""
        for raw in content.splitlines():
            line = raw.rstrip()
            if line.endswith("\\"):
                buf += line[:-1] + " "
            else:
                buf += line
                joined.append(buf)
                buf = ""
        if buf:
            joined.append(buf)
        pipefail_set = False
        for line in joined:
            s = line.strip()
            if s.startswith("FROM"):
                pipefail_set = False
            elif s.startswith("SHELL") and "pipefail" in s:
                pipefail_set = True
            elif (s.startswith("RUN ") or s == "RUN") and "|" in s[3:]:
                assert pipefail_set, (
                    f'{name}/Dockerfile has a pipe in a RUN without '
                    f'SHELL ["/bin/bash", "-o", "pipefail", "-c"] before it'
                )


@then("every Dockerfile that installs tools ends with a version check RUN.")
def step_then_version_check_run(context):
    INSTALL_RE = _re.compile(
        r"\bRUN\b.+\b(pip\d*\s+install|apt-get\s+install|npm\s+install|"
        r"cargo\s+install|apk\s+add|gem\s+install|go\s+install)\b",
        _re.DOTALL,
    )
    for name, content in context.dockerfiles:
        if not INSTALL_RE.search(content):
            continue
        run_lines = [
            l.strip() for l in content.splitlines()
            if l.strip().startswith("RUN ")
        ]
        if not run_lines:
            continue
        last_run = run_lines[-1]
        assert "--version" in last_run or "-version" in last_run, (
            f"{name}/Dockerfile installs tools but the last RUN has no version check. "
            f"Last RUN: {last_run[:120]!r}"
        )


@then('every pip install uses "--no-cache-dir".')
def step_then_pip_no_cache(context):
    PIP_RE = _re.compile(r"pip\d*\s+install\b")
    for name, content in context.dockerfiles:
        for lineno, line in enumerate(content.splitlines(), 1):
            if PIP_RE.search(line) and "--no-cache-dir" not in line:
                # uv pip install uses --no-cache, not --no-cache-dir.
                if _re.search(r"\buv\s+pip\b", line):
                    continue
                assert False, (
                    f"{name}/Dockerfile line {lineno}: pip install missing --no-cache-dir"
                )


@then('every npm install uses "--no-audit" and "--no-fund".')
def step_then_npm_no_audit_fund(context):
    NPM_RE = _re.compile(r"npm\s+install\b")
    for name, content in context.dockerfiles:
        for lineno, line in enumerate(content.splitlines(), 1):
            if NPM_RE.search(line):
                assert "--no-audit" in line, (
                    f"{name}/Dockerfile line {lineno}: npm install missing --no-audit"
                )
                assert "--no-fund" in line, (
                    f"{name}/Dockerfile line {lineno}: npm install missing --no-fund"
                )


@then("no file starts with a UTF-8 BOM.")
def step_then_no_bom(context):
    UTF8_BOM = bytes([0xEF, 0xBB, 0xBF])
    for path in context.ci_scripts:
        data = path.read_bytes()
        assert not data.startswith(UTF8_BOM), (
            f"ci/{path.name} has a UTF-8 BOM"
        )


@then('every image README.md contains a "What you learn" section.')
def step_then_readme_what_you_learn(context):
    for d in context.image_dirs:
        readme = d / "README.md"
        assert readme.is_file(), f"{d.name}/README.md not found"
        content = readme.read_text(encoding="utf-8")
        assert "What you learn" in content, (
            f"{d.name}/README.md has no 'What you learn' section"
        )


@then('the base image tag contains "17" and not "18", "19", "20", "21", "25", or "26".')
def step_then_java17_tag(context):
    m = _re.search(r"^FROM\s+(\S+)", context.java17_content, _re.MULTILINE)
    assert m, "No FROM instruction in java-17/Dockerfile"
    tag = m.group(1)
    assert "17" in tag, f"Base image {tag!r} does not contain '17'"
    for bad in ("18", "19", "20", "21", "25", "26"):
        assert bad not in tag, f"Base image {tag!r} contains forbidden version {bad!r}"


@then("it exits 0.")
def step_then_typst_exits_0(context):
    assert context.typst_result.returncode == 0, (
        f"typst compile failed:\n{context.typst_result.stderr.decode(errors='replace')}"
    )


@then("the script exits 0.")
def step_then_lint_exits_0(context):
    assert context.lint_result.returncode == 0, (
        f"ci/lint-presentation.sh failed:\n{context.lint_result.stderr.decode(errors='replace')}"
    )


@then('".gitignore" contains entries for "*.pdf" and ".worktrees/".')
def step_then_gitignore_entries(context):
    lines = {l.strip() for l in context.gitignore_content.splitlines()}
    assert "*.pdf" in lines, '.gitignore has no "*.pdf" entry'
    assert ".worktrees/" in lines, '.gitignore has no ".worktrees/" entry'



# ---------------------------------------------------------------------------
# AC-23 through AC-27 — presentation and CI workflow checks
# ---------------------------------------------------------------------------

import re as _re_local


@when("slide headings are counted")
def step_when_slide_headings_counted(context):
    source = (REPO_ROOT / "docker-gems.typ").read_text(encoding="utf-8")
    context.slide_count = len(_re_local.findall(r"^== ", source, _re_local.MULTILINE))


@then("the presentation has at least 6 slides.")
def step_then_at_least_6_slides(context):
    assert context.slide_count >= 6, (
        f"Expected at least 6 slides, found {context.slide_count}"
    )


@when("the slide content is checked for an AI prompts section")
def step_when_ai_prompts_checked(context):
    source = (REPO_ROOT / "docker-gems.typ").read_text(encoding="utf-8")
    context.has_ai_prompts = "AI Prompts" in source


@then('the presentation contains a slide with "AI Prompts".')
def step_then_has_ai_prompts(context):
    assert context.has_ai_prompts, (
        "No slide with 'AI Prompts' found in docker-gems.typ"
    )


@given('the ".github/workflows/docker-security-scan.yml" file')
def step_given_security_scan_workflow(context):
    path = REPO_ROOT / ".github" / "workflows" / "docker-security-scan.yml"
    assert path.is_file(), "docker-security-scan.yml not found"
    context.security_scan_yml = path.read_text(encoding="utf-8")


@when("the workflow triggers are checked")
def step_when_triggers_checked(context):
    context.inspected_triggers = context.security_scan_yml


@then('the workflow has a "schedule" trigger with a cron expression.')
def step_then_has_schedule_trigger(context):
    assert "schedule:" in context.inspected_triggers, (
        "No 'schedule:' trigger found in docker-security-scan.yml"
    )
    assert "cron:" in context.inspected_triggers, (
        "No 'cron:' expression found in docker-security-scan.yml"
    )


@given('the ".github/workflows/docker-images.yml" file')
def step_given_docker_images_workflow(context):
    path = REPO_ROOT / ".github" / "workflows" / "docker-images.yml"
    assert path.is_file(), "docker-images.yml not found"
    context.docker_images_yml = path.read_text(encoding="utf-8")


@when("the workflow jobs are checked")
def step_when_jobs_checked(context):
    context.inspected_jobs = context.docker_images_yml


@then('the workflow contains a "static-checks" job.')
def step_then_has_static_checks_job(context):
    assert "static-checks:" in context.inspected_jobs, (
        "No 'static-checks:' job found in docker-images.yml"
    )


@given('the "ci/find-images.sh" script')
def step_given_find_images_script(context):
    path = REPO_ROOT / "ci" / "find-images.sh"
    assert path.is_file(), "ci/find-images.sh not found"
    context.find_images_sh = path.read_text(encoding="utf-8")


@when("the script content is checked for path filtering")
def step_when_path_filtering_checked(context):
    context.inspected_find_images = context.find_images_sh


@then('the script references "GITHUB_EVENT_NAME" to filter images on push.')
def step_then_uses_github_event_name(context):
    assert "GITHUB_EVENT_NAME" in context.inspected_find_images, (
        "ci/find-images.sh does not reference GITHUB_EVENT_NAME for path filtering"
    )
    assert '"push"' in context.inspected_find_images or "'push'" in context.inspected_find_images, (
        "ci/find-images.sh does not check for push event"
    )


# ---------------------------------------------------------------------------
# AC-28 through AC-29 — typos config and Dependabot suppression
# ---------------------------------------------------------------------------

@given('the ".typos.toml" file at the repository root')
def step_given_typos_toml(context):
    path = REPO_ROOT / ".typos.toml"
    assert path.is_file(), ".typos.toml not found at repository root"
    context.typos_toml = path.read_text(encoding="utf-8")


@when("the typos configuration is checked")
def step_when_typos_config_checked(context):
    context.inspected_typos = context.typos_toml


@then('".typos.toml" contains an exception for "certifi".')
def step_then_typos_has_certifi(context):
    assert "certifi" in context.inspected_typos, (
        ".typos.toml does not contain an exception for 'certifi'"
    )


@given('the ".github/dependabot.yml" file')
def step_given_dependabot_yml(context):
    path = REPO_ROOT / ".github" / "dependabot.yml"
    assert path.is_file(), ".github/dependabot.yml not found"
    context.dependabot_yml = path.read_text(encoding="utf-8")


@when("the Dependabot configuration is checked for java-17")
def step_when_dependabot_java17_checked(context):
    context.inspected_dependabot = context.dependabot_yml


@then('the java-17 directory has "open-pull-requests-limit: 0".')
def step_then_java17_suppressed(context):
    text = context.inspected_dependabot
    # Search for the specific directory entry, not a comment that mentions java-17.
    idx = text.find("directory: /java-17")
    assert idx != -1, "java-17 directory entry not found in dependabot.yml"
    section = text[idx:idx + 200]
    assert "open-pull-requests-limit: 0" in section, (
        "java-17 section does not have open-pull-requests-limit: 0"
    )


# ---------------------------------------------------------------------------
# AC-30 through AC-37 — exec bit, HTTPS, ubuntu-24.04, CMD form,
#                        dockerignore, apk, ARG secrets, fail-fast
# ---------------------------------------------------------------------------

@given('all shell scripts in the repo root and "ci/" directory')
def step_given_root_and_ci_scripts(context):
    root_scripts = sorted(REPO_ROOT.glob("*.sh"))
    ci_scripts = sorted((REPO_ROOT / "ci").glob("*.sh"))
    context.all_sh_files = root_scripts + ci_scripts
    assert len(context.all_sh_files) > 0


@when("the git file mode is checked for each script")
def step_when_git_mode_checked(context):
    result = _subprocess.run(
        ["git", "ls-files", "--stage"],
        cwd=str(REPO_ROOT),
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, f"git ls-files failed: {result.stderr}"
    modes = {}
    for line in result.stdout.splitlines():
        parts = line.split("\t", 1)
        if len(parts) == 2:
            mode_part = parts[0].split()[0]
            path = parts[1]
            modes[path] = mode_part
    context.git_modes = modes


@then("every .sh file has mode 100755 in git.")
def step_then_sh_files_exec(context):
    for path in context.all_sh_files:
        rel = path.relative_to(REPO_ROOT).as_posix()
        mode = context.git_modes.get(rel)
        assert mode is not None, (
            f"{rel} is not tracked by git"
        )
        assert mode == "100755", (
            f"{rel} has mode {mode!r} in git; expected 100755 (exec bit not set). "
            f"Fix: git update-index --chmod=+x {rel}"
        )


@when("RUN instructions are checked for HTTP download URLs")
def step_when_http_urls_checked(context):
    context.inspected_dockerfiles = context.dockerfiles


@then("no Dockerfile downloads over plain HTTP.")
def step_then_no_http_downloads(context):
    HTTP_DL_RE = _re.compile(r"\b(?:curl|wget)\b[^\n]*\bhttp://", _re.IGNORECASE)
    for name, content in context.inspected_dockerfiles:
        for lineno, line in enumerate(content.splitlines(), 1):
            stripped = line.strip()
            if stripped.startswith("#"):
                continue
            if HTTP_DL_RE.search(line):
                assert False, (
                    f"{name}/Dockerfile line {lineno}: download uses plain HTTP: {stripped!r}"
                )


@given("all GitHub Actions workflow files")
def step_given_github_workflows(context):
    wf_dir = REPO_ROOT / ".github" / "workflows"
    context.workflow_files = sorted(wf_dir.glob("*.yml"))
    assert len(context.workflow_files) > 0


@when('each file is checked for "ubuntu-latest"')
def step_when_ubuntu_latest_checked(context):
    context.inspected_workflows = [
        (f.name, f.read_text(encoding="utf-8")) for f in context.workflow_files
    ]


@then('no workflow file contains "ubuntu-latest".')
def step_then_no_ubuntu_latest(context):
    for name, content in context.inspected_workflows:
        assert "ubuntu-latest" not in content, (
            f".github/workflows/{name} contains 'ubuntu-latest'; use 'ubuntu-24.04' instead"
        )


@when("CMD instructions are checked for shell form")
def step_when_cmd_shell_form_checked(context):
    context.inspected_dockerfiles = context.dockerfiles


# Images that use shell-form CMD intentionally (wrapper scripts that need shell expansion).
# Add an image name here if a legitimate shell-form CMD is found during test runs.
_CMD_SHELL_FORM_EXCEPTIONS: set = set()


@then("every explicit CMD instruction uses JSON array form.")
def step_then_cmd_json_form(context):
    SHELL_CMD_RE = _re.compile(r"^\s*CMD\s+(?!\[)", _re.MULTILINE)
    for name, content in context.inspected_dockerfiles:
        if name in _CMD_SHELL_FORM_EXCEPTIONS:
            continue
        m = SHELL_CMD_RE.search(content)
        assert m is None, (
            f"{name}/Dockerfile has a shell-form CMD: {m.group().strip()!r}. "
            f'Use JSON form: CMD ["..."]'
        )


@when('each Dockerfile is checked for "COPY . ." and a .dockerignore file')
def step_when_copy_dot_checked(context):
    context.inspected_dockerfiles = context.dockerfiles


# Images where COPY . . is used but no .dockerignore is needed.
# Add an image name here only if the directory has no meaningful files to exclude.
_DOCKERIGNORE_EXCEPTIONS: set = set()


@then('every Dockerfile with "COPY . ." has a ".dockerignore" in the same directory.')
def step_then_dockerignore_present(context):
    COPY_DOT_RE = _re.compile(r"^\s*COPY\s+\.\s+", _re.MULTILINE)
    for name, content in context.inspected_dockerfiles:
        if name in _DOCKERIGNORE_EXCEPTIONS:
            continue
        if COPY_DOT_RE.search(content):
            dockerignore = REPO_ROOT / name / ".dockerignore"
            assert dockerignore.is_file(), (
                f"{name}/Dockerfile contains 'COPY . .' but {name}/.dockerignore does not exist"
            )


@when('"apk add" instructions are checked for "--no-cache"')
def step_when_apk_checked(context):
    context.inspected_dockerfiles = context.dockerfiles


@then('every "apk add" uses "--no-cache".')
def step_then_apk_no_cache(context):
    APK_RE = _re.compile(r"\bapk\s+add\b")
    for name, content in context.inspected_dockerfiles:
        for lineno, line in enumerate(content.splitlines(), 1):
            stripped = line.strip()
            if stripped.startswith("#"):
                continue
            if APK_RE.search(line) and "--no-cache" not in line:
                assert False, (
                    f"{name}/Dockerfile line {lineno}: apk add missing --no-cache: {stripped!r}"
                )


@when("ARG instructions are checked for secret-like names")
def step_when_arg_secrets_checked(context):
    context.inspected_dockerfiles = context.dockerfiles


# Matches ARG names that end with PASSWORD, TOKEN, SECRET, or KEY
# as a whole word or after an underscore.
# Examples flagged: MY_TOKEN, API_KEY, DB_PASSWORD, SECRET
# Examples NOT flagged: BINSTALL_VERSION, GRADLE_VERSION, MONKEY (no _KEY suffix)
_SECRET_ARG_NAME_RE = _re.compile(
    r"^\s*ARG\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s*=.*)?$",
    _re.MULTILINE,
)
_SECRET_SUFFIX_RE = _re.compile(
    r"(?:^|_)(?:PASSWORD|TOKEN|SECRET|KEY)$",
    _re.IGNORECASE,
)


@then("no ARG name contains PASSWORD, TOKEN, SECRET, or KEY as a whole word or suffix.")
def step_then_no_secret_arg(context):
    for name, content in context.inspected_dockerfiles:
        for m in _SECRET_ARG_NAME_RE.finditer(content):
            arg_name = m.group(1)
            if _SECRET_SUFFIX_RE.search(arg_name):
                assert False, (
                    f"{name}/Dockerfile has ARG with a secret-like name: {arg_name!r}. "
                    f"Use RUN --mount=type=secret instead."
                )


@when("the matrix strategy is checked for fail-fast")
def step_when_fail_fast_checked(context):
    context.inspected_fail_fast = context.docker_images_yml


@then('the workflow sets "fail-fast: false" in its matrix strategy.')
def step_then_fail_fast_false(context):
    assert "fail-fast: false" in context.inspected_fail_fast, (
        "docker-images.yml does not contain 'fail-fast: false' in its matrix strategy"
    )


# ---------------------------------------------------------------------------
# AC-38 — git committer email
# ---------------------------------------------------------------------------

import subprocess as _sp


@given("the git configuration for the repository")
def step_given_git_config(context):
    result = _sp.run(
        ["git", "config", "user.email"],
        cwd=str(REPO_ROOT),
        capture_output=True,
        text=True,
    )
    context.git_email = result.stdout.strip()


@when("the committer email is read")
def step_when_email_read(context):
    pass  # value already captured in Given


@then('the email is "{expected_email}".')
def step_then_email_is(context, expected_email):
    assert context.git_email == expected_email, (
        f"Expected git user.email '{expected_email}', got '{context.git_email}'.\n"
        f"Fix: git config user.email \"{expected_email}\""
    )
