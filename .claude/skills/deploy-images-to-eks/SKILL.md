---
name: deploy-images-to-eks
description: >-
  Use when the user asks to run the images on Kubernetes or Amazon EKS, or to test
  the manifests in kind. Also use when the user asks to create or delete the course
  EKS cluster, or to explain EKS best practices for these images. Also use when the
  user asks to deploy Open WebUI, the Graphify or CodeGraph tool servers, the
  java-eks API, Argo CD, or Crossplane.
---

# Deploy the images to EKS

The full guide is in `aws/README.md`, steps 2 to 8. The guide also has the best practices
and a troubleshooting table. The rules for the manifests are in the "Kubernetes manifests"
section of `AGENTS.md`.

## Rules

- Get the consent of the user before you run `eksctl create cluster`. A cluster costs money
  for each hour that it exists. Tell the user about step 8, which deletes the resources.
- If the user only wants to see that the manifests work, use the kind test. It runs without AWS.
- Delete the applications before the cluster. Otherwise, load balancers and EBS volumes stay
  and cost money.
- Never put a secret in a manifest. Never commit the `overlays/` directory.

## Test without AWS

The images must exist locally as `<directory>:latest`:

```sh
bash ci/test-kubernetes.sh graphify codegraph java-eks open-webui
```

## Create the cluster

```sh
eksctl create cluster -f aws/eks-cluster.yaml
kubectl apply -f aws/storageclass.yaml -f aws/ingressclass.yaml
```

## Deploy an application

| Application | Namespace | Secret and key | Check |
| --- | --- | --- | --- |
| `open-webui` | `open-webui` | `open-webui`, `WEBUI_SECRET_KEY` | `rollout status deployment/open-webui` |
| `graphify` | `graphify` | `graphify-tools`, `MCPO_API_KEY` | `rollout status deployment/graphify-tools` |
| `codegraph` | `codegraph` | `codegraph-tools`, `MCPO_API_KEY` | `rollout status deployment/codegraph-tools`, and the Job logs |
| `java-eks` | `eks-demo` | None | `rollout status deployment/eks-demo` |
| `argocd` | `argocd` | None. Apply with `--server-side --force-conflicts`. | `rollout status deployment/argocd-server` |
| `crossplane` | `crossplane-system` | None. Install the Helm chart first (`crossplane/README.md`). | `wait provider.pkg.crossplane.io --all --for=condition=Healthy` |

```sh
kubectl apply -f <app>/kubernetes/namespace.yaml
kubectl -n <namespace> create secret generic <secret> --from-literal=<key>="$(openssl rand -hex 32)"
kubectl apply -k <app>/kubernetes
kubectl -n <namespace> rollout status deployment/<name> --timeout=15m
```

If a pod does not start, run `kubectl -n <namespace> get events --sort-by=.lastTimestamp`
and `kubectl -n <namespace> describe pod <pod>`. Then use the troubleshooting table.

## Delete the resources

If Argo CD runs, delete the ApplicationSet first:
`kubectl delete -f argocd/applications/docker-gems.yaml`. Otherwise Argo CD creates the
applications again. If Crossplane runs, delete its managed resources first, as in step 7 of
`crossplane/README.md`. Otherwise the AWS resources stay.

```sh
for app in java-eks codegraph graphify open-webui; do kubectl delete -k "$app/kubernetes"; done
kubectl delete -k argocd/kubernetes   # if you installed Argo CD
kubectl get pv,ingress -A
eksctl delete cluster -f aws/eks-cluster.yaml --disable-nodegroup-eviction --wait
```

Ask the user before you delete the Open WebUI volume. It holds all chats and accounts.
