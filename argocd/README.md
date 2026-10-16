# stden/argocd

Run Argo CD on Kubernetes and EKS for GitOps, and use the argocd, helm, and kustomize CLIs.

## Overview

This image is the official [Argo CD](https://argo-cd.readthedocs.io/) image
`quay.io/argoproj/argocd` at the newest stable release, v3.5.6. The build does not change
it. Each build runs the smoke test and publishes the tested image. The upstream `latest`
tag is a nightly build, so this image follows the stable releases instead.

One image contains all parts of Argo CD:

- The components that run in the cluster: the API server and web UI, the repo server,
  the application controller, the ApplicationSet controller, notifications, and Dex.
- The `argocd` command, and `helm`, `kustomize`, and `git`, which the repo server uses to
  render manifests.

The image runs as the user `argocd` (UID 999). Copy it to Amazon ECR with
[aws/copy-to-ecr.sh](https://github.com/stden/docker-gems/blob/main/aws/copy-to-ecr.sh).

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` with the newest stable Argo CD release. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/argocd/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/argocd:latest
```

## Tutorial

The files in this tutorial are in the
[docker-gems repository](https://github.com/stden/docker-gems). Run the commands from
its root. For steps 2 to 6, a Kubernetes cluster is necessary, for example the EKS cluster
of the [AWS guide](https://github.com/stden/docker-gems/blob/main/aws/README.md).

### Step 1: Use the tools without a cluster

Write an Argo CD Application. Then render the manifests as the repo server does:

```sh
docker run --rm stden/argocd:latest argocd admin app generate-spec java-eks \
  --repo https://github.com/stden/docker-gems.git --path java-eks/kubernetes \
  --dest-server https://kubernetes.default.svc --dest-namespace eks-demo \
  --sync-policy automated --self-heal --auto-prune
docker run --rm -v "$PWD":/work -w /work stden/argocd:latest kustomize build java-eks/kubernetes
docker run --rm -v "$PWD":/work -w /work stden/argocd:latest helm template demo ./my-chart
```

If `kustomize build` or `helm template` fails on your computer, Argo CD cannot sync the
application either.

### Step 2: Install Argo CD

[argocd/kubernetes](https://github.com/stden/docker-gems/tree/main/argocd/kubernetes)
installs the upstream manifest of the same version with this image. It also puts the
pods on amd64 nodes. The namespace enforces the `restricted` Pod Security Standard. The
Argo CD CRDs are too large for a client-side apply. Use a server-side apply:

```sh
kubectl apply -k argocd/kubernetes --server-side --force-conflicts
kubectl -n argocd rollout status deployment/argocd-server --timeout=10m
```

### Step 3: Sign in

```sh
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
kubectl -n argocd port-forward service/argocd-server 8080:443
```

Open <https://127.0.0.1:8080>. Accept the self-signed certificate. Sign in as `admin` with
that password. Change the password under **User Info**. Then delete the initial secret:
`kubectl -n argocd delete secret argocd-initial-admin-secret`.

### Step 4: Deploy the course applications with GitOps

[argocd/applications](https://github.com/stden/docker-gems/tree/main/argocd/applications)
has an AppProject and an ApplicationSet. The project allows only this repository and the
four application namespaces. The ApplicationSet makes one Application for each of
`open-webui`, `graphify`, `codegraph`, and `java-eks`. Each Application applies
`<app>/kubernetes` from the `main` branch, and syncs again when git changes or when
somebody changes the cluster by hand.

Create the secrets of the applications first, as in steps 3 and 4 of the AWS guide. Then
run these commands:

```sh
kubectl apply -f argocd/applications/project.yaml -f argocd/applications/docker-gems.yaml
kubectl -n argocd get applications
```

The Open WebUI volume has the annotation `argocd.argoproj.io/sync-options: Prune=false`,
so Argo CD never deletes it during a sync.

### Step 5: Use the image from ECR

Copy the image with `aws/copy-to-ecr.sh argocd`. Then make a kustomize overlay, as in step 7
of the AWS guide. In the overlay, set `newName` of `stden/argocd` to the ECR repository.

### Step 6: Remove Argo CD

Delete the ApplicationSet first, so that Argo CD does not create the applications again.
Then delete the applications with `kubectl delete -k <app>/kubernetes`. Delete Argo CD last:

```sh
kubectl delete -f argocd/applications/docker-gems.yaml -f argocd/applications/project.yaml
kubectl delete -k argocd/kubernetes
```

## Best practices

- **Pin what you deploy.** The course uses the `main` branch. In production, set
  `targetRevision` to a tag or a commit. Also pin the images by digest.
- **Limit each project.** An AppProject sets the allowed repositories, destination
  namespaces, and cluster-scoped kinds. Do not use the `default` project for real work.
- **Keep secrets out of git.** Argo CD applies what is in git. Use an external secret
  store, for example AWS Secrets Manager with the External Secrets Operator.
- **Do not keep the admin account.** Change its password. Delete the initial secret. Use
  single sign-on with RBAC roles. Test a policy change with
  `argocd admin settings rbac can <role> <action> <resource> <object> --policy-file policy.csv`.
- **Do not publish the API server without HTTPS and sign-on.** Use
  `kubectl port-forward`, or an Ingress with a certificate and allowed networks.
- **Protect data.** Mark a volume that holds data with `Prune=false`. Make a backup of it
  before a change.
- **Upgrade one minor version at a time.** Read the upgrade notes of each version. Change
  the version in `argocd/Dockerfile` and `argocd/kubernetes/kustomization.yaml` together.
- **Give Argo CD enough resources.** The upstream manifest sets no resource requests. For
  production, use the high-availability manifest or the Helm chart with requests.

## Source and checks

The smoke test writes an Application, tests an RBAC policy, renders kustomize and Helm
sources, and starts each component with `--help`. A kind test installs Argo CD with this
image. It checks that the image and the manifest have the same version. It also checks
that Argo CD deploys `java-eks/kubernetes` from GitHub.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/argocd/Dockerfile)
- [Smoke test](https://github.com/stden/docker-gems/blob/main/argocd/smoke-test.sh)
- [Kubernetes manifests](https://github.com/stden/docker-gems/tree/main/argocd/kubernetes)
- [Overview source](https://github.com/stden/docker-gems/blob/main/argocd/README.md)
- [Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/)
