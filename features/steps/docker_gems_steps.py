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
