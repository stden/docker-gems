---
name: crossplane-packages
description: >-
  Use when the user asks to build, push, version, or install a Crossplane
  Configuration package (crossplane.yaml with XRDs and Compositions). Also use
  when the user asks to push a package to Amazon ECR or another OCI registry.
  Also use when the user asks to install a package in a cluster with the
  crossplane CLI.
---

# Build, push, and install Crossplane packages

A Configuration package is an OCI image with XRDs, Compositions, and examples. Its
`crossplane.yaml` declares the dependencies: providers and functions with version
constraints. The smoke test `crossplane/smoke-test.sh` has a complete package.

## Build

```sh
docker run --rm -v "$PWD":/workspace stden/crossplane:latest \
  crossplane xpkg build --package-root=package --examples-root=examples \
  --package-file=course-registry.xpkg
```

Before you build the package, validate the files with the `crossplane-compositions` skill.

## Push

The tag must be a full OCI reference with the registry, the repository, and the tag. Use a
new version tag for each change. Never move a version tag.

For Amazon ECR, create the repository first. ECR does not create it on push. Log in with
Docker on your computer. The toolbox reads that login from the mounted Docker
configuration:

```sh
registry="$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com"
aws ecr create-repository --repository-name docker-gems/course-registry
aws ecr get-login-password | docker login --username AWS --password-stdin "$registry"
docker run --rm -v "$PWD":/workspace -v "$HOME/.docker":/root/.docker:ro \
  stden/crossplane:latest crossplane xpkg push \
  --package-files=course-registry.xpkg "$registry/docker-gems/course-registry:v0.1.0"
```

## Install

```sh
crossplane xpkg install configuration "$registry/docker-gems/course-registry:v0.1.0" \
  course-registry --wait=5m
kubectl get configurations.pkg.crossplane.io
crossplane resource trace configuration/course-registry --show-package-dependencies=all
```

The EKS nodes can pull from ECR in the same account. Crossplane installs the dependencies
of the package, for example `function-patch-and-transform`. A dependency gets a name
from its package path, for example `crossplane-contrib-function-patch-and-transform`. Use
that name in the `functionRef` of the Compositions in a package.

## Rules

- Commit `crossplane.yaml`, the XRDs, the Compositions, and the examples. Do not commit the
  `.xpkg` file.
- Build and validate the package in CI on every change. Push only from the main branch.
