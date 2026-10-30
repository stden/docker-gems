# Manually written checks for repository structure rules from specs/docker_gems_requirements.md.
Feature: Docker Gems Repository Structure Checks

  # Source: specs/docker_gems_requirements.md:10
  @REQ_AC_6
  Scenario: every image has "languages-and-frameworks" in its category list
    Given all top-level directories with a Dockerfile
    When "ci/hub-categories.json" is checked
    Then every image has "languages-and-frameworks" in its category list.

  # Source: specs/docker_gems_requirements.md:11
  @REQ_AC_7
  Scenario: every image except compilers, latex, and java-eks has both up.sh and up.cmd
    Given all top-level directories with a Dockerfile
    When the "up.sh" and "up.cmd" files are checked
    Then every image except "compilers", "latex", and "java-eks" has both "up.sh" and "up.cmd".

  # Source: specs/docker_gems_requirements.md:12
  @REQ_AC_8
  Scenario: no Dockerfile sets a secret value in an ENV instruction
    Given all top-level Dockerfiles in the repository
    When ENV instructions are checked for secret patterns
    Then no Dockerfile sets a secret value in an ENV instruction.

  # Source: specs/docker_gems_requirements.md:13
  @REQ_AC_9
  Scenario: argocd Dockerfile and kustomization.yaml use the same Argo CD version
    Given "argocd/Dockerfile" and "argocd/kubernetes/kustomization.yaml"
    When the Argo CD version is checked in both files
    Then both files reference the same Argo CD version.

  # Source: specs/docker_gems_requirements.md:14
  @REQ_AC_10
  Scenario: java-ui-browser and android pin the same Gradle version
    Given "java-ui-browser/Dockerfile" and "android/Dockerfile"
    When the Gradle version is checked in both
    Then both files pin the same Gradle version.
