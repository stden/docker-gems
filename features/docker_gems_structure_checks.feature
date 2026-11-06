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

  # Source: specs/docker_gems_requirements.md:15
  @REQ_AC_11
  Scenario: every tool Dockerfile sets WORKDIR /workspace
    Given all top-level Dockerfiles in the repository
    When Dockerfile instructions are checked for WORKDIR
    Then every tool Dockerfile sets "WORKDIR /workspace".

  # Source: specs/docker_gems_requirements.md:16
  @REQ_AC_12
  Scenario: every tool image ends with CMD ["bash"]
    Given all top-level Dockerfiles in the repository
    When CMD instructions are checked in each Dockerfile
    Then every tool image ends with CMD ["bash"].

  # Source: specs/docker_gems_requirements.md:17
  @REQ_AC_13
  Scenario: every Dockerfile pipe has SHELL pipefail set before it
    Given all top-level Dockerfiles in the repository
    When RUN instructions with pipes are checked
    Then every Dockerfile with a pipe in a RUN has SHELL ["/bin/bash", "-o", "pipefail", "-c"] before it.

  # Source: specs/docker_gems_requirements.md:18
  @REQ_AC_14
  Scenario: every installing Dockerfile ends with a version check RUN
    Given all top-level Dockerfiles in the repository
    When the last RUN instruction is checked for version commands
    Then every Dockerfile that installs tools ends with a version check RUN.

  # Source: specs/docker_gems_requirements.md:19
  @REQ_AC_15
  Scenario: every pip install uses --no-cache-dir
    Given all top-level Dockerfiles in the repository
    When pip install instructions are checked
    Then every pip install uses "--no-cache-dir".

  # Source: specs/docker_gems_requirements.md:20
  @REQ_AC_16
  Scenario: every npm install uses --no-audit and --no-fund
    Given all top-level Dockerfiles in the repository
    When npm install instructions are checked
    Then every npm install uses "--no-audit" and "--no-fund".

  # Source: specs/docker_gems_requirements.md:21
  @REQ_AC_17
  Scenario: no ci/ shell script has a UTF-8 BOM
    Given all shell scripts in the "ci/" directory
    When each file is checked for a UTF-8 BOM
    Then no file starts with a UTF-8 BOM.

  # Source: specs/docker_gems_requirements.md:22
  @REQ_AC_18
  Scenario: every image README.md contains a "What you learn" section
    Given all top-level directories with a Dockerfile
    When each image "README.md" is checked for a "What you learn" heading
    Then every image README.md contains a "What you learn" section.

  # Source: specs/docker_gems_requirements.md:23
  @REQ_AC_19
  Scenario: java-17/Dockerfile uses JDK 17
    Given the "java-17/Dockerfile" file
    When the base image tag is checked for the JDK version
    Then the base image tag contains "17" and not "18", "19", "20", "21", "25", or "26".

  # Source: specs/docker_gems_requirements.md:24
  @REQ_AC_20
  Scenario: docker-gems.typ compiles without errors
    Given the "docker-gems.typ" file at the repository root
    When "typst compile" is run on it
    Then it exits 0.

  # Source: specs/docker_gems_requirements.md:25
  @REQ_AC_21
  Scenario: ci/lint-presentation.sh exits 0 for docker-gems.typ
    Given the "docker-gems.typ" file at the repository root
    When "ci/lint-presentation.sh docker-gems.typ" is run
    Then the script exits 0.

  # Source: specs/docker_gems_requirements.md:26
  @REQ_AC_22
  Scenario: .gitignore contains entries for *.pdf and .worktrees/
    Given the ".gitignore" file at the repository root
    When the .gitignore entries are checked
    Then ".gitignore" contains entries for "*.pdf" and ".worktrees/".

  # Source: specs/docker_gems_requirements.md:27
  @REQ_AC_23
  Scenario: docker-gems.typ has at least 6 content slides
    Given the "docker-gems.typ" file at the repository root
    When slide headings are counted
    Then the presentation has at least 6 slides.

  # Source: specs/docker_gems_requirements.md:28
  @REQ_AC_24
  Scenario: docker-gems.typ contains an AI prompts slide
    Given the "docker-gems.typ" file at the repository root
    When the slide content is checked for an AI prompts section
    Then the presentation contains a slide with "AI Prompts".

  # Source: specs/docker_gems_requirements.md:29
  @REQ_AC_25
  Scenario: docker-security-scan.yml has a weekly schedule trigger
    Given the ".github/workflows/docker-security-scan.yml" file
    When the workflow triggers are checked
    Then the workflow has a "schedule" trigger with a cron expression.

  # Source: specs/docker_gems_requirements.md:30
  @REQ_AC_26
  Scenario: docker-images.yml has a static-checks job
    Given the ".github/workflows/docker-images.yml" file
    When the workflow jobs are checked
    Then the workflow contains a "static-checks" job.

  # Source: specs/docker_gems_requirements.md:31
  @REQ_AC_27
  Scenario: ci/find-images.sh uses GITHUB_EVENT_NAME for path filtering
    Given the "ci/find-images.sh" script
    When the script content is checked for path filtering
    Then the script references "GITHUB_EVENT_NAME" to filter images on push.

  # Source: specs/docker_gems_requirements.md:32
  @REQ_AC_28
  Scenario: .typos.toml allows the word "certifi"
    Given the ".typos.toml" file at the repository root
    When the typos configuration is checked
    Then ".typos.toml" contains an exception for "certifi".

  # Source: specs/docker_gems_requirements.md:33
  @REQ_AC_29
  Scenario: dependabot.yml suppresses PRs for java-17
    Given the ".github/dependabot.yml" file
    When the Dependabot configuration is checked for java-17
    Then the java-17 directory has "open-pull-requests-limit: 0".

  # Source: specs/docker_gems_requirements.md:34
  @REQ_AC_30
  Scenario: every .sh file in the repo root and ci/ has the exec bit set in git
    Given all shell scripts in the repo root and "ci/" directory
    When the git file mode is checked for each script
    Then every .sh file has mode 100755 in git.

  # Source: specs/docker_gems_requirements.md:35
  @REQ_AC_31
  Scenario: every curl and wget download in a Dockerfile uses HTTPS, not HTTP
    Given all top-level Dockerfiles in the repository
    When RUN instructions are checked for HTTP download URLs
    Then no Dockerfile downloads over plain HTTP.

  # Source: specs/docker_gems_requirements.md:36
  @REQ_AC_32
  Scenario: all GitHub Actions workflow files use ubuntu-24.04, not ubuntu-latest
    Given all GitHub Actions workflow files
    When each file is checked for "ubuntu-latest"
    Then no workflow file contains "ubuntu-latest".

  # Source: specs/docker_gems_requirements.md:37
  @REQ_AC_33
  Scenario: every CMD instruction in a Dockerfile uses JSON form, not shell form
    Given all top-level Dockerfiles in the repository
    When CMD instructions are checked for shell form
    Then every explicit CMD instruction uses JSON array form.

  # Source: specs/docker_gems_requirements.md:38
  @REQ_AC_34
  Scenario: every Dockerfile that contains "COPY . ." also has a .dockerignore file
    Given all top-level Dockerfiles in the repository
    When each Dockerfile is checked for "COPY . ." and a .dockerignore file
    Then every Dockerfile with "COPY . ." has a ".dockerignore" in the same directory.

  # Source: specs/docker_gems_requirements.md:39
  @REQ_AC_35
  Scenario: every apk add instruction uses --no-cache
    Given all top-level Dockerfiles in the repository
    When "apk add" instructions are checked for "--no-cache"
    Then every "apk add" uses "--no-cache".

  # Source: specs/docker_gems_requirements.md:40
  @REQ_AC_36
  Scenario: no ARG instruction uses a name that suggests a secret
    Given all top-level Dockerfiles in the repository
    When ARG instructions are checked for secret-like names
    Then no ARG name contains PASSWORD, TOKEN, SECRET, or KEY as a whole word or suffix.

  # Source: specs/docker_gems_requirements.md:41
  @REQ_AC_37
  Scenario: the build-and-publish job in docker-images.yml has fail-fast: false
    Given the ".github/workflows/docker-images.yml" file
    When the matrix strategy is checked for fail-fast
    Then the workflow sets "fail-fast: false" in its matrix strategy.

  # Source: specs/docker_gems_requirements.md:38
  @REQ_AC_38
  Scenario: git user.email is set to the GitHub address for this repository
    Given the git configuration for the repository
    When the committer email is read
    Then the email is "super.denis@gmail.com".
