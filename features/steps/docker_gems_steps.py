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
