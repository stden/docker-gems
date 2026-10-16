# Agent rules for docker-gems

This repository contains Docker images and examples for a QA course. Every agent must read this file.

## Language

- Use Simplified Technical English (ASD-STE100) for all repository content. The content is the
  documentation, image overviews, skills, prompts, comments, script messages, sample output, and
  commit messages.
- Write instructions as commands. Write one instruction in each sentence. Put a condition first.
- Write at most 20 words in an instruction and at most 25 words in a description.
  Write at most six sentences in a paragraph.
- Use the active voice and simple tenses. Use "must" and "can".
  Do not use "should", "may", "might", or "would".
- Do not use -ing forms or contractions, except in technical names.
  If a single verb can replace a phrasal verb, use the single verb.
  Keep technical verbs, for example "log in" and "sign in".
- Use approved words. Write "give" or "has" for "provide". Write "must have" or "is necessary"
  for "need" and "require". Write "make sure" for "ensure" and "for example" for "e.g.".
- Use one term for one thing. Use the terms that the repository already uses.
- Keep the emoji lines in `README.md`. Each main section starts with one emoji line.
  The line is a short tip in STE. A rewrite must not remove these lines.
- Keep commands, identifiers, and external API names unchanged when you translate text.
- Keep non-English text only if a test uses it to check the language support.

## What this repository is

- Each top-level directory with a `Dockerfile` defines one image. GitHub Actions publishes it
  to Docker Hub as `stden/<directory>:latest` after its smoke test passes.
- `README.md` contains the Docker tutorial, the image catalogue, and a reusable Claude Code prompt.
- `java-eks/` is a Spring Boot application with its own `README.md`, Maven Wrapper and
  Kubernetes manifests.
- `docker-compose.yml` runs the `my-python-app` image against MySQL.
- `aws/` is the guide for Amazon ECR and EKS. It has the eksctl cluster file, the Auto Mode
  StorageClass and IngressClass, and the ECR lifecycle policy. `copy-to-ecr.sh` copies the tested
  images to ECR and applies the policy to each repository.
- `.claude/skills/` has Claude Code skills for this repository. Its `README.md` lists them.
- The top-level `*.sh` and `*.cmd` files are course demos. `test-images.sh` is the Docker
  smoke test for every image. GitHub Actions uses this script directly.
  `ci/test-built-image.sh` runs the equivalent checks in GitLab CI.

## Layout of an image directory

- `Dockerfile` — the image.
- `README.md` — the Docker Hub overview. Start with `# stden/<directory>`, a blank line,
  and a single-line purpose sentence of at most 100 bytes. This sentence is the short description.
  Keep the complete file below 25000 bytes. Use absolute links so they also work on Docker Hub.
- `ci/hub-categories.json` selects one to three Docker Hub search categories for every image.
  When you add an image, update this file. Image tags and search categories are different fields.
- `up.sh` and `up.cmd` — build, run `test-images.sh --no-build`, then tag and push.
  They are a pair. Change both. A failed test must not push. `compilers` and `latex` have only
  `up.sh`. `java-eks` has no `up` scripts. Publish it with `ci/publish-image.sh java-eks`.
- `r.sh` and `r.cmd` (in some images) — build and run locally.
- `kubernetes/` (in some images) — manifests for Kubernetes and EKS, with a `kustomization.yaml`
  that sets the namespace and a `namespace.yaml` with Pod Security labels. See "Kubernetes manifests".
- The eighteen shared tool images have a self-contained `smoke-test.sh`.
  Both CI runners mount this file and run it with Bash. Keep the test files outside the built image.
  Their `up.sh` and `up.cmd` scripts call `ci/publish-image.sh`. This script must run on `main`.
  It stops before publication if a test fails.

## Version policy

- Use the `latest` tag for base images. The images must have the current stable tools.
- When you update dependencies, use `docker build --pull --no-cache`. This command downloads the
  current base image and installs the packages again. Do not use cached package layers.
- For Java, use the newest LTS major. It is 25 now. The next LTS is 29. To move to a new LTS,
  change all of these together:
  - `java/Dockerfile` (`maven:3-amazoncorretto-25`)
  - `java-eks/pom.xml` (`java.version`)
  - `java-eks/Dockerfile` (both `FROM` lines)
  - `java-eks/build.cmd`
  - `java-run-swing/Dockerfile` (`openjdk25`)
  - `android/Dockerfile` (`eclipse-temurin:25-jdk`)
  - the `openjdk version "25` checks and the `maven:3-amazoncorretto-25` command in
    `test-images.sh`, `ci/test-built-image.sh`, and `ci/test-smoke-failures.sh`
  - the `java` row and the `mvn -B verify` command in this file
  - the image table in `README.md`, `java/README.md`, `java-run-swing/README.md`,
    `java-eks/README.md`, and `android/README.md`
- `java-ui-browser` uses the current stable JDK for browser UI tests.
  It is 27 now (`eclipse-temurin:27-jdk-resolute`). When a new stable JDK is available, change
  all of these together:
  - `java-ui-browser/Dockerfile` (`FROM`)
  - the `openjdk 27` checks in `test-images.sh` and `ci/test-built-image.sh`
  - the `java-ui-browser` row in this file
  - the image table and the base image note (`uses the current JDK 27`) in `README.md`, and
    `java-ui-browser/README.md`
- Pin an exact version only where the tool must have one:
  - `java-eks/pom.xml`: the Spring Boot parent, springdoc, the JaCoCo plugin
  - `java-eks/.mvn/wrapper/maven-wrapper.properties`: the Maven version for `./mvnw`
  - `java-ui-browser/Dockerfile` and `android/Dockerfile`: the Gradle distribution and its SHA-256.
    Change the Gradle version in both Dockerfiles, `test-images.sh`, `ci/test-built-image.sh`,
    this file, `README.md`, `java-ui-browser/README.md`, and `android/README.md` together.
  - `.gitlab-ci.yml`: the Kaniko image
  - `ci/install-tools.sh`: proot, jq, and crane
  - `document-tools/Dockerfile`: the Typst version and its SHA-256
  - `rust-ci/Dockerfile` and `rust-desktop/Dockerfile`: the cargo-binstall version and its SHA-256
    for x86_64 and aarch64. Change both files together.
  - Downloaded tool archives: use a stable release. If a checksum is available, verify it.
  - `cpp-cuda/Dockerfile`: use the newest available stable NVIDIA development image.
  - `postgres-vector-graph/Dockerfile`: the pgvector and Apache AGE releases. Change the versions in
    `postgres-vector-graph/README.md` together. Keep the PostgreSQL major compatible with the stable
    AGE release.
  - `graphify/Dockerfile` and `codegraph/Dockerfile`: mcpo 0.0.20 fails with `mcp` 2 and with FastAPI
    0.145 or later. Install it in its own environment `/opt/mcpo` with `mcp<2` and `fastapi<0.145`.
    Change both files together. When a new mcpo release supports these versions, remove the limits.
  - `argocd/Dockerfile`: the newest stable Argo CD release. The upstream `latest` tag is a nightly
    build. Change the version in `argocd/kubernetes/kustomization.yaml` (the install manifest URL)
    together. The kind test fails when the two versions differ.
  - `android/Dockerfile`: the Android command-line tools 22.0 with their SHA-256, the Build-tools
    37.0.0 and 36.0.0, and the SDK platforms `android-34` to `android-37.2`. Build-tools 36.0.0 is
    the default of the newest stable Android Gradle Plugin. Change the versions in
    `android/README.md`, the `android` row in `README.md`, and `android/smoke-test.sh` together.
    In command-line tools 23.0, `sdkmanager` downloads an unchecked binary at its first start and
    fails offline. Check each new release.
  - `php/Dockerfile`: the fingerprint of the PHPUnit signing key. The build checks the PHAR signature
    with it. Change it only when PHPUnit announces a new key.
  - `crossplane/kubernetes/providers.yaml`: the AWS provider packages. Use the same newest
    release for `provider-family-aws` and each service provider.
- For `web-qa`, install Playwright. Then install the browser revision of this Playwright release
  in the same build. Do not mix browser files from a different Playwright release.
- Do not specify an exact distribution package version in an `apt-get` or `apk` line, for example
  `libboost-filesystem1.81.0`. A later distribution can remove it. Use the `-dev` package.
- Do not add an apt repository with `--allow-insecure-repositories` or `--allow-unauthenticated`.
  Download from the vendor over HTTPS instead, like the DMD step in `compilers/Dockerfile`.
- Do not use a base image that is no longer updated. Check the `last_updated` field on Docker Hub.

## Find the latest version from a primary source

Check the version numbers at the primary source:

```sh
# Maven Central: latest release of an artifact
curl -fsS https://repo1.maven.org/maven2/org/springframework/boot/spring-boot-starter-parent/maven-metadata.xml | grep -E "<(latest|release)>"
# Docker Hub: tags and the date of the last update
curl -fsS "https://hub.docker.com/v2/repositories/library/maven/tags?page_size=25&ordering=last_updated"
# Does a tag exist?
docker manifest inspect amazoncorretto:25 >/dev/null && echo exists
# Distribution packages
docker run --rm debian:stable-slim sh -c 'apt-get update -qq && apt-cache policy mono-mcs'
docker run --rm alpine:latest sh -c 'apk update -q && apk search openjdk'
```

The Maven `release` field can contain a preview, such as `4.2.0-M2`. Use the newest stable release.

## Docker best practices

The sources are the Docker guide [Building best practices](https://docs.docker.com/build/building/best-practices/)
and the [Dockerfile reference](https://docs.docker.com/reference/dockerfile/). The version policy
above gives the rules for base images, exact versions, and `--pull --no-cache`.

- Start from a trusted source. Docker names three programs: Official Images, Verified Publisher
  images, and Docker-Sponsored Open Source images. The image of the upstream project is also a
  trusted source, for example `quay.io/argoproj/argocd` in `argocd` and `texlive/texlive` in
  `latex`. When the tools allow it, use the small variant, for example `debian:stable-slim` in
  `code-quality` and `node:slim` in `allure`.
- When a step downloads or compiles a tool, use a multi-stage build. Copy only the result into
  the final image, for example in `crossplane`, `php`, `allure`, and `postgres-vector-graph`.
- Download only over HTTPS. If the vendor gives a checksum or a signature, verify the archive
  with it in the same `RUN` instruction (see "Version policy"). Examples are the Gradle archive
  in `android` and the PHPUnit PHAR in `php`.
- Install the packages of a step in one `RUN` instruction. Put `apt-get update`,
  `apt-get install -y --no-install-recommends`, and `rm -rf /var/lib/apt/lists/*` in the same
  instruction. Use `pip --no-cache-dir` and `npm --no-audit --no-fund`. Delete temporary files
  in the instruction that creates them.
- If a `RUN` instruction has a pipe, put `SHELL ["/bin/bash", "-o", "pipefail", "-c"]` before it.
  Put it in the same stage, as in `code-quality`. Without `pipefail`, the shell checks only the
  exit code of the last command in the pipe. hadolint reports a pipe without this `SHELL` instruction as
  DL4006. A pipe from `yes` fails under `pipefail`, because `yes` gets SIGPIPE when the reader
  stops. Write `(yes || true) |`, for example before `sdkmanager --licenses` in `android`.
- Order the instructions from stable to variable, so that the build cache stays valid. Install
  the tools first. Copy the project files last.
- Set a variable for one step in the `RUN` instruction, for example
  `RUN DEBIAN_FRONTEND=noninteractive apt-get ...`. A variable in `ENV` stays in the image and
  changes the behavior of the tools for the user.
- Use the JSON form for `CMD` and `ENTRYPOINT`. The shell form starts the process under
  `/bin/sh -c`, which does not pass signals to it. If a shell wrapper is necessary, start the
  process with `exec`, as in `java-eks`. If the base image has an entrypoint that the image must
  not keep, set `ENTRYPOINT []`. Then set `CMD`, as in `java` and `crossplane`, because a new
  `ENTRYPOINT` resets the inherited `CMD`. Set `WORKDIR /workspace` in a new tool image, as the
  `add-docker-image` skill says. The user mounts the project there.
- Disable the telemetry, the analytics, and the update checks of each tool, for example
  `ALLURE_NO_ANALYTICS=true`, `SEMGREP_ENABLE_VERSION_CHECK=0`, and
  `cargo binstall --disable-telemetry`. A test run must not send usage data to a vendor.
- Check the installed tools at the end of the build with their version commands, for example
  `RUN java -version && mvn -version`. Keep the smoke test outside the image (see "Layout of an
  image directory").
- An image that runs as a pod must work as a numeric non-root user with a read-only root
  filesystem (see "Kubernetes manifests"). If the Dockerfile sets the `ENTRYPOINT` or `CMD` of
  the service, set `USER` to the UID and GID of its manifest. `java-eks` sets `USER 10001:10001`,
  the values of `runAsUser` and `runAsGroup`, so that `docker run` also starts it without root.
  An image that keeps the upstream entrypoint also keeps the upstream user, for example `argocd`
  and `postgres-vector-graph`. The process writes only to a volume, an `emptyDir`, or `/tmp`.
  A tool image for CI can run as root, because the runner mounts the workspace.
- Do not put a secret into the image. Do not `COPY` credentials. Do not put a token into `ENV`
  or `ARG`. If a build must have a secret, use `RUN --mount=type=secret`. The images of this
  repository must have no secret at build time.
- The images are for `linux/amd64`. If a download is for one architecture, check
  `dpkg --print-architecture` or `uname -m` in the build. Stop the build on an architecture
  without a checked download, as in `android` (amd64) and `rust-ci` (x86_64 and aarch64).
- When the build context has files that the image does not use, add a `.dockerignore` file.
  Docker does not read `.gitignore`. `java-eks/.dockerignore` removes `target/`, `kubernetes/`,
  and the documentation from the build context, which `COPY . .` copies into the build stage.
- Run hadolint from the `code-quality` image on each new or changed Dockerfile. Run it from the
  repository root, so that hadolint reads `.hadolint.yaml`. Fix the findings in the lines that
  you change. The file `.hadolint.yaml` ignores the rules that ask for exact versions of base
  images and packages. The version policy permits an exact version only where the tool must
  have one.

  ```sh
  docker run --rm -v "$PWD":/workspace stden/code-quality hadolint <directory>/Dockerfile
  ```

- Keep the image small. Do not install documentation packages, build tools, or caches into the
  final stage. Compare the size with `docker image ls` before and after a change.

## Verify before you commit

Every push to GitHub starts a build for every image, also when the push changes only documentation.
Publish images only from `main`, after the test of each image passes. Before you commit:

1. Run `./test-images.sh <directory>`. The script builds the image and runs its smoke test.
   With no arguments, the script checks every image. It builds `<directory>:test` itself.
   `./test-images.sh --no-build <directory>` checks `<directory>:latest` and does not build.

   GitLab CI runs the same checks after Kaniko writes the image and before `crane` pushes it.
   GitLab runners cannot start a container. GitLab CI unpacks the Kaniko tar and runs the commands
   with PRoot (`ci/test-built-image.sh`). Keep that script and `test-images.sh` in agreement.

   Docker is necessary for the `my-python-app` Compose check. GitLab CI checks the Python library
   imports and compiles `my-test.py` and `my-sql-test.py`. GitHub Actions runs the full Compose
   check. The checks are:

   | Image            | Smoke test                                                                                     |
   |------------------|------------------------------------------------------------------------------------------------|
   | `compilers`      | `docker run --rm compilers:test` prints five `== Program in ...` blocks                      |
   | `cpp`            | Compile a file with `g++ --coverage`, run it, then `gcovr` and `valgrind --error-exitcode=1`   |
   | `java`           | `docker run --rm java:test bash -c 'java -version && mvn -version'` prints Java 25 and Maven 3 |
   | `java-eks`       | `mvn -B verify` (below), then run the container and get HTTP 200 from `/api/health`, `/api-docs` and `/swagger-ui/index.html` |
   | `java-run-swing` | `docker run --rm -v <dir with Hello.class>:/app java-run-swing:test xvfb-run -a java Hello` shows a `JFrame` and exits 0 |
   | `java-ui-browser` | `docker run --rm java-ui-browser:test bash -c 'java --version && gradle --version && google-chrome --version && git --version && python3 --version'` prints Java 27, Gradle 9.8.2, Google Chrome, git and Python 3. `python3 -c 'import venv'` and `libatomic.so.1` must load |
   | `latex`          | `pdflatex` a small Russian document, then compile and link a Boost.Filesystem program          |
   | `my-python-app`  | `docker compose up --build --abort-on-container-exit --exit-code-from app` twice (new volume, then the same volume), then `docker compose down -v` |
   | `python`         | `docker run --rm python:test bash -c 'python --version && uv --version && pytest --version && behave --version && ruff --version && mypy --version'` prints Python, uv, pytest, Behave, Ruff and mypy |
   | `rust`           | `docker run --rm rust:test bash -c 'rustc --version && cargo --version && rustfmt --version && cargo clippy --version'` prints rustc, Cargo, rustfmt and Clippy |
   | `rust-node` | Build and test Rust code, run Node.js, and check native build libraries |
   | `rust-ci` | Run Rust tests with Nextest, check coverage, licenses, mutants, and SQLx migrations, and check compiler caching |
   | `rust-desktop` | Compile desktop code and open a GTK window under Xvfb |
   | `web-qa` | Open a local page in a browser and run Python and accessibility checks |
   | `document-tools` | Compile Typst, convert a document with LibreOffice, and read PDF text |
   | `python-media` | Generate and convert audio, then check its properties |
   | `cpp-vulkan` | Compile a shader and check a software Vulkan device |
   | `cpp-cuda` | Compile and link CUDA code and run host C++ code, without GPU execution |
   | `postgres-vector-graph` | Start a temporary cluster and run vector and Cypher queries |
   | `graphify` | Run the README tutorial offline: extract, query, update, export, MCP, and mcpo |
   | `codegraph` | Run the README tutorial: index, query, affected tests, sync, MCP, mcpo, and uninit |
   | `open-webui` | Start the server with a temporary data directory, create an administrator account, and call the API |
   | `argocd` | Write an Application, test an RBAC policy, render kustomize and Helm sources, start each component with `--help` |
   | `crossplane` | Build a Configuration package, convert an XRD, validate good and bad examples, check Helm and kubectl |
   | `code-quality` | Each tool finds a planted problem and passes clean input: gitleaks, hadolint, shellcheck, actionlint, typos, semgrep |
   | `allure` | Generate Allure 3 and Allure 2 reports, history, and single-file reports from hand-written results |
   | `php` | Run PHPUnit with pcov coverage on a small Composer project, check a test that fails, and check the extensions |
   | `android` | Build, unit-test, and lint a Kotlin and Java app, check the APK, and check that no daemon stays alive |

   PostgreSQL smoke tests run as the `postgres` user. They must use a temporary data directory
   and socket. Never connect the smoke test to a database that already exists or to a
   persistent volume.

   The `graphify` and `codegraph` tests follow the tutorial in the image README. Change both together.
   The `graphify` test sets `GRAPHIFY_BACKEND=none` and must not call a language model.
   The `codegraph` MCP check sets `CODEGRAPH_NO_DAEMON=1`. The shared daemon continues to run after
   the client stops, and PRoot then waits for it. The mcpo checks stop mcpo and then check that its
   MCP server stopped.

   The `open-webui` test must not connect to a model backend or a persistent data directory.
   The Vulkan test uses a software driver. The CUDA test must clearly state that it did not run a
   GPU kernel. Do not make physical GPU access necessary on the standard GitHub runner.

   Run the `java-eks` tests and the 95% JaCoCo coverage check without a local JDK:

   ```sh
   docker run --rm -v "$PWD/java-eks":/app -w /app maven:3-amazoncorretto-25 mvn -B verify
   ```

   The tests use `src/test/resources/application.yml` instead of the main `application.yml`.
   Run the container to verify the main configuration.

2. After you change the GitHub workflow or the smoke tests, run:

   ```sh
   actionlint .github/workflows/docker-images.yml
   actionlint .github/workflows/docker-hub.yml
   bash ci/test-smoke-failures.sh
   python3 -m unittest discover -s ci -p test_hub_metadata.py
   python3 ci/hub_metadata.py --check
   ```

3. Rehearse one image without a push. Build it with the same Kaniko image as GitLab CI. Then run
   the CI smoke test. Do not run `crane push` against Docker Hub during a rehearsal. For `latex`,
   tens of gigabytes under `/cache` are necessary for the tar and the unpacked rootfs.

   ```sh
   KANIKO=$(sed -n 's/^ *name: \(.*kaniko.*\)$/\1/p' .gitlab-ci.yml)
   docker run --rm -v "$PWD":/builds/repo -w /builds/repo -v /tmp/image-test:/cache \
     --entrypoint "" "$KANIKO" sh -c 'set -eu
     sh ci/install-tools.sh /cache/my-docker-images-tools
     export JQ=/cache/my-docker-images-tools/jq
     export PROOT=/cache/my-docker-images-tools/proot
     export PROOT_TMP_DIR=/cache/proot-tmp
     mkdir -p "$PROOT_TMP_DIR"
     dir=java
     /kaniko/executor --context "/builds/repo/$dir" --dockerfile "/builds/repo/$dir/Dockerfile" \
       --no-push --tarPath /cache/image.tar --cleanup
     sh ci/test-built-image.sh "$dir" /cache/image.tar /cache/rootfs'
   ```

4. After you change `.gitlab-ci.yml`, run `glab ci lint .gitlab-ci.yml`.

5. After you change a `kubernetes/` directory or an image that has one, run the kind test.
   The kind test must have Docker, kind, kubectl, and jq, and the images as `<directory>:latest`:

   ```sh
   bash ci/test-kubernetes.sh open-webui graphify codegraph java-eks
   bash ci/test-kubernetes.sh argocd crossplane
   ```

   Test `argocd` without `java-eks`, so that its GitOps check deploys `java-eks` from GitHub.
   GitHub Actions runs it for `graphify`, `codegraph`, `java-eks`, `argocd`, and `crossplane`
   before the push.
   The `open-webui` image is too large for the runner disk, so run that test locally.

6. After you change `aws/copy-to-ecr.sh` or `aws/ecr-lifecycle-policy.json`, run
   `bash ci/test-copy-to-ecr.sh`. It uses a mock AWS CLI and a local registry, and it
   copies `stden/codegraph:latest` from Docker Hub. Also run `actionlint` on
   `.github/workflows/aws-ecr.yml`. When you change `aws/eks-cluster.yaml`, validate it against
   the schema of `eksctl utils schema`.

## Kubernetes manifests

- Every pod of a course image sets `nodeSelector: kubernetes.io/arch: amd64`. The repository builds the
  images for amd64 only. The Crossplane pods use upstream multi-arch images and have no node selector.
- Every pod runs as a numeric non-root user with `allowPrivilegeEscalation: false`, all
  capabilities dropped, the `RuntimeDefault` seccomp profile, a read-only root filesystem, and
  `automountServiceAccountToken: false`. The Argo CD and Crossplane pods come from upstream, so only
  the `restricted` level applies to them. Each namespace enforces the `restricted` level.
- Set requests and a memory limit on every container. A pod with a ReadWriteOnce volume has
  one replica and `strategy: Recreate`.
- Do not put a secret in a manifest. The guide creates each Secret with `kubectl create secret`.
- Use the Docker Hub image `stden/<directory>:latest` without `imagePullPolicy`. The kind test
  and the ECR overlay replace the image with kustomize.
- Open WebUI keeps its volume at `/data` with `DATA_DIR=/data`, because a volume at
  `/app/backend/data` hides the embedding models in the image.
- `graphify extract` starts one worker for each CPU of the node. Set `GRAPHIFY_MAX_WORKERS`.
- Use the IngressClass name `alb`. `aws/ingressclass.yaml` creates it for EKS Auto Mode.
- `argocd/kubernetes` uses the upstream install manifest. It changes only the image and adds the
  amd64 node selector. The upstream manifest sets `imagePullPolicy: Always` and no resource
  requests. The kind test changes the pull policy, so that the node uses the loaded image.
  ECR Public limits the anonymous pulls of each address. If it refuses an image of
  `public.ecr.aws/docker/library`, the kind test pulls the same tag from Docker Hub.
- Crossplane comes from its Helm chart with `crossplane/kubernetes/helm-values.yaml`, which adds
  the settings of the restricted level. The kind test installs the chart with the helm of the
  tested image (`prepare_crossplane`). Its kustomization has no `namespace` field, because the
  Crossplane objects are cluster-scoped. The test reads the namespace from `namespace.yaml`.

## AWS EKS best practices

The guide `aws/README.md` has the section "Best practices for EKS". Its sources are the
[Amazon EKS Best Practices Guide](https://docs.aws.amazon.com/eks/latest/best-practices/introduction.html)
and the Kubernetes documentation. Keep that section and this list in agreement. The rules for
the manifests are in "Kubernetes manifests" above.

- Use short-term credentials. People use IAM Identity Center. GitHub Actions uses OIDC (see
  "GitHub Actions"). Do not store an AWS access key in a file or an image.
- Give each person an access entry with a namespace-scoped policy, for example
  `AmazonEKSEditPolicy`. Keep one emergency administrator role.
- If a pod calls AWS APIs, give it its own IAM role through EKS Pod Identity. Never give it the
  node role. The Crossplane provider uses `source: PodIdentity` in
  `crossplane/kubernetes/provider-config.yaml`. The course applications call no AWS API.
- Use EKS Auto Mode (`aws/eks-cluster.yaml`). Auto Mode manages the nodes, the EBS storage, and
  the load balancers. Use the newest Kubernetes version in standard support and the `STANDARD`
  support type. Upgrade the cluster before its version leaves standard support.
- Use kubectl with the minor version of the cluster, or one minor version newer or older. Limit
  public access to the API endpoint to known networks, or use the private endpoint.
- Copy the tested images to ECR in the Region of the cluster with `aws/copy-to-ecr.sh`. The
  script keeps the digest. ECR does not charge for the transfer in the same Region, and the
  pulls do not count toward the Docker Hub limit. Without VPC endpoints for ECR and S3, the NAT
  gateway charges for each GB of a pull (step 7 of the guide).
- Make the tags immutable, except `latest`. Keep the lifecycle policy
  `aws/ecr-lifecycle-policy.json`. Untagged images expire 14 days after the push, and ECR keeps
  the 10 newest tagged images. Scan the images on push. Read the findings before a deployment.
  Pin the image by digest in production.
- Use a startup probe for a slow start and a readiness probe for traffic. Use a liveness probe
  that checks only the application, not an external service such as the database. Add a
  PodDisruptionBudget and a topology spread constraint to a Deployment with two or more
  replicas. The constraint spreads the replicas over nodes and Availability Zones with
  `whenUnsatisfiable: ScheduleAnyway`. Auto Mode replaces each node after at most 21 days and
  respects the budget.
- Add a short `preStop` delay to a pod behind an ALB with `target-type: ip`. Also enable pod
  readiness gates with the label `elbv2.k8s.aws/pod-readiness-gate-inject: enabled` on its
  namespace. The gate keeps the old pods until the ALB reports the new pods healthy.
- Use `kubectl port-forward` for administration pages, for example Open WebUI and Argo CD.
  Publish a service only with HTTPS, a known host name, and `inbound-cidrs`. The `java-eks`
  Ingress of the course is the exception. It uses HTTP for the demo.
- For production, add NetworkPolicy objects to each namespace. Start with a policy that denies
  all ingress and egress traffic. Then allow DNS and the connections that each application must
  have. Examples are the ALB to `java-eks` and Open WebUI to the tool servers. EKS Auto Mode
  enforces network policies without an add-on. The course manifests have no NetworkPolicy.
- Do not put a secret in a manifest (see "Kubernetes manifests"). For production, keep the
  secrets in AWS Secrets Manager. Mount them with the Secrets Store CSI Driver. Encrypt data at
  rest. Keep `encrypted: "true"` in `aws/storageclass.yaml` and the AES-256 encryption of the
  ECR repositories in `aws/copy-to-ecr.sh`.
- Deploy with GitOps. The AppProject `docker-gems` in `argocd/applications/project.yaml` limits
  the source repository and the destination namespaces. The ApplicationSet deploys from `main`
  with `prune` and `selfHeal`. A PersistentVolumeClaim has the annotation
  `argocd.argoproj.io/sync-options: Prune=false`, so that Argo CD does not delete the data.
- Create AWS resources with Crossplane from the cluster. `crossplane/kubernetes/providers.yaml`
  gives each provider a `DeploymentRuntimeConfig` with the restricted settings. Delete the
  managed resources before you delete the cluster, or the AWS resources stay.
- Delete the cluster after each lesson. Then check for EBS volumes, load balancers, and
  CloudFormation stacks that remain (step 8 of the guide). If you enable control plane logging,
  set a retention period on the CloudWatch log group. For a production cluster, enable GuardDuty
  EKS Protection and GuardDuty Runtime Monitoring. EKS Protection analyzes the audit logs.
  Runtime Monitoring checks the processes in the containers, also on Auto Mode nodes.
- Test the manifests without AWS with the kind test, `ci/test-kubernetes.sh` (step 5 of "Verify
  before you commit"). kind does not test the EBS StorageClass, the load balancers, or IAM.

## GitHub Actions

- `.github/workflows/docker-images.yml` finds all top-level directories with a `Dockerfile`.
  Each image has a separate Ubuntu runner. A failed job does not cancel the other image jobs.
- The workflows use `runs-on: ubuntu-24.04`, not `ubuntu-latest`. GitHub moves `ubuntu-latest`
  to Ubuntu 26.04 with Docker 29 in stages, so one run can use two different images. After a test
  run on the new image, change the label in all workflows together.
- Every push to any branch or tag builds and tests all images. Do not add push path filters.
  Pushes to `main` publish images after their tests pass. Other pushes do not publish images.
- Pull requests to `main` build and test when a subdirectory, `.github/workflows/docker-images.yml`,
  `docker-compose.yml`, or `test-images.sh` changes.
  Pull requests do not publish images. Manual runs publish only from `main`.
- Build each image as `<directory>:latest` with `--pull --no-cache`.
  Run `./test-images.sh --no-build <directory>` before you publish.
  Tag the same tested image as `stden/<directory>:latest`. Then push it.
  Do not rebuild it after the test.
- Use the GitHub repository secret `DOCKER_HUB_TOKEN` for a Docker Hub personal access token
  with **Repo Read, Write, Delete** permission. This level is necessary for updates of the
  repository metadata. The Docker Hub username is `stden`. Do not put the token in a file or log.
- Log in before the build on `main` to authenticate base image pulls. Push only after the tests pass.
- After a successful image push, `ci/hub_metadata.py` publishes the image README, the short
  description, and the search categories. Then it reads the saved values and fails if they do not
  match. Keep credentials in memory. Never print authentication responses.
  Use the separate `/categories` API endpoint with a top-level array of full category objects.
  Include `Languages & frameworks` for every image, because the repository owner asked for this
  category.
- The manual `Hub pages` workflow updates all overviews and search categories. It does not rebuild
  the images. It publishes only from `main` and shares the concurrency group of the image workflow.
- Keep `contents: read` permissions. Pull requests must not log in to Docker Hub or push images.
- `.github/workflows/aws-ecr.yml` copies images to Amazon ECR. It runs only by hand from
  `main`. Only its job has `id-token: write`, for GitHub OIDC. It must have the repository
  variables `AWS_ROLE_ARN` and `AWS_REGION`. Do not store an AWS access key in GitHub.
- Keep the concurrency group. Runs for the same branch must not publish at the same time.
- The jobs for large images remove unused tools from their temporary runners to make space for
  the image.

## GitLab CI

The GitLab configuration remains available for the `origin-backup` remote.

- The runners are not privileged, so the `docker:dind` service cannot start. Do not add it again.
  Rootless BuildKit also fails, because the runner host sets
  `kernel.apparmor_restrict_unprivileged_userns=1`. Kaniko works.
- Google archived the original Kaniko in 2025. Use the maintained fork
  `ghcr.io/osscontainertools/kaniko`, the `-debug` variant. GitLab must have the shell of
  this variant.
- One container builds all images. Keep `--cleanup`, or the next image gets the files of the
  previous image. The smoke-test tools and the image tar are on `/cache`, which is a mount, so
  `--cleanup` does not delete them. Delete the tar and the rootfs after the push.
- The job tests an image before it pushes that image. A failed test must leave `:latest` unchanged.
  Push the Kaniko tar with `crane`. Do not pass `--destination` to the Kaniko command that
  builds the image. This option pushes the image before the test.
- PRoot runs the unpacked rootfs. It does not apply the image `ENV`, `WORKDIR`, or `USER` by itself.
  `ci/run-rootfs.sh` applies the image environment and working directory. For PostgreSQL,
  the test runner passes the numeric `postgres` UID and GID with `--user`. Bind `/proc`, `/dev`, and
  `/etc/resolv.conf`. Set `PROOT_TMP_DIR` to a writable directory, because the Kaniko debug image
  has no usable `/tmp`.
- The job runs only on `main`, because `DOCKER_HUB_PASSWORD` is a protected variable. It runs only
  when a file in a subdirectory or `.gitlab-ci.yml` changes. The `*/**/*` changes rule matches every
  subdirectory, for example `aws/`, `docs/`, `.claude/`, and `.github/`. A change to only the
  top-level files does not rebuild the images.
- GitLab gives a protected variable only to a protected branch, so `main` must stay protected. If
  `main` is not protected, the password is empty and Kaniko fails with
  `UNAUTHORIZED: authentication required`.

## Conventions

- Follow the Simplified Technical English rules above for all text. This includes CI comments.
- Keep every script that starts with `#!` executable in git (`git update-index --chmod=+x <file>`).
  CI builds on Linux, where a script without the exec bit breaks `CMD ./script` and `./test.sh`.
- Do not put a secret into the repository. Store Docker Hub credentials in the CI secret store.
  The demo passwords in `docker-compose.yml` and `README.md` are placeholders.
