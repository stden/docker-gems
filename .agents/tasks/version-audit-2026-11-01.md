# Version Audit — docker-gems — 2026-11-01

Audit date: 2026-11-01. Read-only investigation. No code was changed.

## Summary

One pin is outdated: **cargo-binstall 1.26.1 → 1.26.2** (affects `rust-ci/Dockerfile` and
`rust-desktop/Dockerfile`). All other pinned versions and base images are current.
Two items carry standing notes: Android cmdline-tools stays intentionally at 22.0 because
version 23.0 deprecated `sdkmanager`; the `mcpo` constraints (`mcp<2`, `fastapi<0.145`) remain
necessary because no new release has lifted them.

---

## 1. Base images

Base images that use the `latest` tag are not checked here — the build rule
`docker build --pull --no-cache` always pulls the newest image. This section covers only
base images that are pinned to an exact tag by policy.

| Image | File | Pinned tag | Latest stable | Status |
|-------|------|-----------|---------------|--------|
| `quay.io/argoproj/argocd` | `argocd/Dockerfile`, `argocd/kubernetes/kustomization.yaml` | `v3.5.6` | `v3.5.6` (GitHub API, 2026-10-20) | ✅ Current |
| `nvidia/cuda` | `cpp-cuda/Dockerfile` | `13.4.3-devel-ubuntu26.04` | `13.4.3-devel-ubuntu26.04` (Docker Hub, 2026-10-17) | ✅ Current |
| `eclipse-temurin:27-jdk-resolute` | `java-ui-browser/Dockerfile` | JDK 27 | JDK 27 is the current stable non-LTS per AGENTS.md | ✅ Current |
| `eclipse-temurin:25-jdk` | `android/Dockerfile` | JDK 25 | Java 25 is the current LTS per AGENTS.md | ✅ Current |
| `maven:3-amazoncorretto-25` | `java/Dockerfile`, `java-eks/Dockerfile` | Java 25 LTS + Maven 3 | Current LTS | ✅ Current |

Source: [Docker Hub nvidia/cuda tags](https://hub.docker.com/v2/repositories/nvidia/cuda/tags?page_size=10&ordering=last_updated&name=devel-ubuntu26.04),
[Argo CD GitHub releases](https://github.com/argoproj/argo-cd/releases/latest).

---

## 2. Java ecosystem

| Item | File | Current version | Latest stable | Status |
|------|------|----------------|---------------|--------|
| Spring Boot parent | `java-eks/pom.xml` | `4.1.2` | `4.1.2` (Maven Central; 4.2.0-RC1 is a release candidate, not stable) | ✅ Current |
| springdoc-openapi | `java-eks/pom.xml` | `3.2.0` | `3.2.0` (Maven Central) | ✅ Current |
| JaCoCo Maven plugin | `java-eks/pom.xml` | `0.8.16` | `0.8.16` (Maven Central) | ✅ Current |
| Java version | `java-eks/pom.xml` | `25` | 25 is the current LTS | ✅ Current |
| Maven wrapper | `java-eks/.mvn/wrapper/maven-wrapper.properties` | `3.10.0` | `3.10.0` (maven.apache.org confirmed as latest stable) | ✅ Current |
| Gradle binary | `java-ui-browser/Dockerfile`, `android/Dockerfile` | `9.8.2` | `9.8.2` (gradle.org/releases, 2026-10-19) | ✅ Current |
| Gradle SHA-256 (bin) | Both Dockerfiles | `21bd5da2de49b642...` | `21bd5da2de49b642...` (gradle.org/release-checksums) | ✅ Verified |

Source: [Maven Central — spring-boot-starter-parent](https://repo1.maven.org/maven2/org/springframework/boot/spring-boot-starter-parent/maven-metadata.xml),
[Maven Central — jacoco-maven-plugin](https://repo1.maven.org/maven2/org/jacoco/jacoco-maven-plugin/maven-metadata.xml),
[Maven Central — springdoc-openapi-starter-webmvc-ui](https://repo1.maven.org/maven2/org/springdoc/springdoc-openapi-starter-webmvc-ui/maven-metadata.xml),
[gradle.org checksums](https://gradle.org/release-checksums/).

---

## 3. CI / build tools

| Item | File | Current version | Latest stable | Status |
|------|------|----------------|---------------|--------|
| proot | `ci/install-tools.sh` | `5.5.0` | `5.5.0` (GitHub API, tag v5.5.0) | ✅ Current |
| jq | `ci/install-tools.sh` | `1.8.2` | `1.8.2` (GitHub API, tag jq-1.8.2) | ✅ Current |
| crane (go-containerregistry) | `ci/install-tools.sh` | `0.22.1` | `0.22.1` (GitHub API, tag v0.22.1, 2026-09-04) | ✅ Current |
| Kaniko (osscontainertools) | `.gitlab-ci.yml` | `v1.29.0-debug` | `v1.29.0` (GitHub API, 2026-10-25) | ✅ Current |
| **cargo-binstall** | `rust-ci/Dockerfile`, `rust-desktop/Dockerfile` | **`1.26.1`** | **`1.26.2`** (GitHub API, 2026-10-31) | ❌ Update needed |
| Typst | `document-tools/Dockerfile` | `0.15.1` | `0.15.1` (GitHub API, v0.15.1, 2026-07-17) | ✅ Current |

### cargo-binstall update details

`rust-ci/Dockerfile` and `rust-desktop/Dockerfile` both pin `BINSTALL_VERSION=1.26.1`. The latest
release is `v1.26.2` (published 2026-10-31).

New checksums from the GitHub release assets:

```
x86_64:  9e0e064f189a9abb9f8df5fb93c3c810ef5cc19e7212d998c7a64c9e4d3527d5
aarch64: a235250cd684af9bf1e3a1e4c216b1d36e6c553553d5d789744f27689d81c2d6
```

Files that must change together per AGENTS.md policy:
- `rust-ci/Dockerfile`
- `rust-desktop/Dockerfile`

Source: [GitHub API — cargo-binstall releases](https://api.github.com/repos/cargo-bins/cargo-binstall/releases/latest).

---

## 4. App-specific pins

| Item | File | Current version | Latest stable | Status |
|------|------|----------------|---------------|--------|
| Argo CD | `argocd/Dockerfile`, `argocd/kubernetes/kustomization.yaml` | `v3.5.6` | `v3.5.6` | ✅ Current |
| pgvector | `postgres-vector-graph/Dockerfile` | `0.8.7` | `0.8.7` (GitHub tags, v0.8.7 is the newest tag) | ✅ Current |
| Apache AGE | `postgres-vector-graph/Dockerfile` | `1.8.0` (PG18) | `1.8.0` for PG18 (only version in downloads.apache.org/age/PG18/) | ✅ Current |
| mcpo | `graphify/Dockerfile`, `codegraph/Dockerfile` | `0.0.20` | `0.0.20` (PyPI, last upload 2026-02-27) — see note | ✅ Current (constrained) |
| Crossplane provider-family-aws | `crossplane/kubernetes/providers.yaml` | `v2.9.0` | `v2.9.0` (GitHub API, 2026-10-08) | ✅ Current |
| Crossplane provider-aws-ecr | `crossplane/kubernetes/providers.yaml` | `v2.9.0` | `v2.9.0` (same release) | ✅ Current |
| Bouncy Castle (Android) | `android/Dockerfile` | `1.86` | `1.86` (Maven Central) | ✅ Current |
| Android cmdline-tools | `android/Dockerfile` | `22.0` (build `15859902`) | 23.0 exists but is excluded — see note | ✅ Current (intentional) |
| PHPUnit signing key | `php/Dockerfile` | `D8406D0D82947747293778314AA394086372C20A` | Same key still in use; no rotation announced | ✅ Current |
| TorchAudio (open-webui) | `open-webui/Dockerfile` | Dynamic (runtime detection) | Policy implemented correctly in Dockerfile | ✅ Current |

Source: [Apache AGE downloads](https://downloads.apache.org/age/PG18/),
[pgvector tags](https://api.github.com/repos/pgvector/pgvector/tags),
[crossplane-contrib/provider-upjet-aws releases](https://api.github.com/repos/crossplane-contrib/provider-upjet-aws/releases/latest),
[Bouncy Castle Maven Central](https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk18on/maven-metadata.xml),
[mcpo PyPI](https://pypi.org/pypi/mcpo/json).

---

## Notes

### Android cmdline-tools 23.0 — intentionally excluded

The `android/Dockerfile` uses cmdline-tools build `15859902` (version 22.0). Version 23.0 is
available but deprecated `sdkmanager` in favour of the new Android CLI, which downloads
itself at first launch and breaks offline builds. Multiple upstream projects (flutter, nixpkgs)
confirmed this in mid-2026. The AGENTS.md already documents this decision.
No action needed.

### mcpo 0.0.20 — constraints still required

mcpo 0.0.20 is the latest stable release on PyPI as of this audit. The compatibility issue
with `mcp>=2` and `fastapi>=0.145` has not been fixed in any released version. Both
`graphify/Dockerfile` and `codegraph/Dockerfile` must keep the constraints:

```
mcpo "mcp<2" "fastapi<0.145"
```

When a new mcpo release removes these constraints, update both Dockerfiles together per
AGENTS.md.

### Spring Boot 4.2.0-RC1 — not stable

Maven Central shows `4.2.0-RC1` as the newest artifact in the `release` field, but this is a
release candidate. The spring.io upgrade page confirms: "This version is still in development
and is not considered stable yet. For the latest stable version, please use Spring Boot 4.1."
The repo uses `4.1.2`, which is the latest stable patch. No update needed.

### Open WebUI TorchAudio — dynamic, policy-compliant

`open-webui/Dockerfile` detects the installed Torch version at build time and applies:
- `torchaudio~=2.11.0` for Torch ≥ 2.11
- `torchaudio=={torch_version}` for Torch < 2.11

This matches the AGENTS.md policy exactly. No static pin is needed here.

---

## Conclusion and recommendation

**One update is due:**

Update `cargo-binstall` from `1.26.1` to `1.26.2` in both `rust-ci/Dockerfile` and
`rust-desktop/Dockerfile`. Change `BINSTALL_VERSION` and both SHA-256 values. The two files
must change together.

All other pinned items are at the latest stable release. The two standing policy exceptions
(Android cmdline-tools 22.0 and mcpo 0.0.20 constraints) are correctly documented in
`AGENTS.md` and require no action until upstream resolves the blocking issues.
