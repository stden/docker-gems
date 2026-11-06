---
name: crossplane-install
description: >-
  Use when the user asks to install, upgrade, check, or remove Crossplane on a
  Kubernetes or EKS cluster. Also use when the user asks which Crossplane version
  runs. The skill installs the Helm chart with the settings of the restricted Pod
  Security level, from the stden/crossplane image. For providers, use
  crossplane-aws-providers.
---

# Install, upgrade, and remove Crossplane

Crossplane runs in the cluster from its Helm chart. The `stden/crossplane` image has
`helm`, `kubectl`, the `crossplane` CLI, and the AWS CLI for an EKS kubeconfig. The full
tutorial is in `crossplane/README.md`.

## Rules

- Confirm the cluster with the user first: `kubectl config current-context`.
- Use `crossplane/kubernetes/helm-values.yaml`. Without it, the chart pods do not meet the
  `restricted` level that `crossplane/kubernetes/namespace.yaml` enforces. As a result,
  Kubernetes does not create the pods.
- Do not remove Crossplane while managed resources exist. Their cloud resources stay.

## Start the toolbox

```sh
docker run --rm -it -v "$PWD":/workspace -v "$HOME/.kube":/root/.kube \
  -v "$HOME/.aws":/root/.aws -e AWS_REGION -e AWS_PROFILE stden/crossplane:latest
```

## Install

```sh
kubectl apply -f crossplane/kubernetes/namespace.yaml
helm install crossplane crossplane --repo https://charts.crossplane.io/stable \
  --namespace crossplane-system -f crossplane/kubernetes/helm-values.yaml --wait
kubectl -n crossplane-system get pods
crossplane version
```

`crossplane version` prints the client version and the version that runs in the cluster.

## Upgrade

Read the release notes of the new version first. Upgrade one minor version at a time.
Use the newest patch of each minor version. `helm list` shows the installed chart, for
example `crossplane-2.3.7`. In the command, replace `2.4` with the next minor version.
The range `~2.4.0` selects the newest stable patch of 2.4. Repeat the upgrade until the
cluster has the newest release.

```sh
helm list --namespace crossplane-system
helm upgrade crossplane crossplane --repo https://charts.crossplane.io/stable \
  --version '~2.4.0' --namespace crossplane-system \
  -f crossplane/kubernetes/helm-values.yaml --wait
kubectl get providers.pkg.crossplane.io,functions.pkg.crossplane.io
```

All packages must be `HEALTHY` after the upgrade.

## If a pod does not start

```sh
kubectl -n crossplane-system get events --sort-by=.lastTimestamp | tail -20
```

`violates PodSecurity` means that a setting of the restricted level is missing. Use the
values file for Crossplane, and the `DeploymentRuntimeConfig` objects of
`crossplane/kubernetes/providers.yaml` for providers.

## Remove

Run the commands in this order. Ask the user before you delete managed resources.
`kubectl get managed -A` lists them while the cluster has a provider.

```sh
kubectl get managed -A
kubectl delete -f crossplane/kubernetes/repository.yaml
kubectl delete -f crossplane/kubernetes/provider-config.yaml
kubectl delete -k crossplane/kubernetes
helm uninstall crossplane --namespace crossplane-system
```
