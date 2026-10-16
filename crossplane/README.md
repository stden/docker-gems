# stden/crossplane

Install and use Crossplane on Kubernetes and EKS: the crossplane CLI, kubectl, helm, and AWS CLI.

## Overview

[Crossplane](https://www.crossplane.io/) manages cloud resources, such as an Amazon ECR
repository, as Kubernetes objects. Crossplane itself runs in the cluster from its Helm
chart. This image is the toolbox to install and use it:

- The `crossplane` CLI, newest stable release: build, validate, and push packages, and
  trace resources in a cluster.
- `kubectl` and `helm`, newest stable releases. The build checks each download with its SHA-256.
- The AWS CLI version 2. An EKS kubeconfig runs `aws eks get-token`, so the image can
  connect to an EKS cluster.
- `jq`, `tar`, and `gzip`.

The base image is `amazon/aws-cli:latest`. The working directory is `/workspace`. The
default command starts Bash.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` with the newest stable tools. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/crossplane/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/crossplane:latest
```

## Tutorial

The files in this tutorial are in
[crossplane/kubernetes](https://github.com/stden/docker-gems/tree/main/crossplane/kubernetes)
of the docker-gems repository. Run the commands from its root. For steps 2 to 5 and step 7,
an EKS cluster is necessary, for example the cluster of the
[AWS guide](https://github.com/stden/docker-gems/blob/main/aws/README.md). Step 6 works
without a cluster.

### Step 1: Start the toolbox

```sh
docker run --rm -it -v "$PWD":/workspace -v "$HOME/.kube":/root/.kube \
  -v "$HOME/.aws":/root/.aws -e AWS_REGION -e AWS_PROFILE stden/crossplane:latest
```

The container uses your kubeconfig and your AWS credentials. Run the next steps in it.

### Step 2: Install Crossplane

The values file adds the settings that are necessary for the `restricted` Pod Security
Standard. The chart does not set them by default.

```sh
kubectl apply -f crossplane/kubernetes/namespace.yaml
helm install crossplane crossplane --repo https://charts.crossplane.io/stable \
  --namespace crossplane-system -f crossplane/kubernetes/helm-values.yaml --wait
kubectl -n crossplane-system get pods
```

### Step 3: Give the AWS provider an IAM role

The ECR provider runs with the service account `provider-aws`. EKS Pod Identity gives that
service account the permissions of an IAM role. No access key goes into the cluster.

```sh
account=$(aws sts get-caller-identity --query Account --output text)
cat > pod-identity-trust.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "pods.eks.amazonaws.com"},
    "Action": ["sts:AssumeRole", "sts:TagSession"]
  }]
}
EOF
aws iam create-role --role-name docker-gems-crossplane-ecr \
  --assume-role-policy-document file://pod-identity-trust.json
aws iam attach-role-policy --role-name docker-gems-crossplane-ecr \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess
aws eks create-pod-identity-association --cluster-name docker-gems \
  --namespace crossplane-system --service-account provider-aws \
  --role-arn "arn:aws:iam::$account:role/docker-gems-crossplane-ecr"
```

`AmazonEC2ContainerRegistryFullAccess` keeps the course simple. For production, write a
policy with only the actions and the repositories that the provider uses.

### Step 4: Install the AWS provider

```sh
kubectl apply -k crossplane/kubernetes
kubectl wait provider.pkg.crossplane.io --all --for=condition=Healthy --timeout=10m
kubectl apply -f crossplane/kubernetes/provider-config.yaml
```

[providers.yaml](https://github.com/stden/docker-gems/blob/main/crossplane/kubernetes/providers.yaml)
installs the ECR provider and the AWS family provider at the same pinned version. The
`ClusterProviderConfig` named `default` tells the provider to use EKS Pod Identity. A
managed resource that names no provider configuration uses it. If you create the Pod
Identity association after the provider starts, restart the provider pod.

### Step 5: Create an ECR repository with Crossplane

```sh
kubectl apply -f crossplane/kubernetes/repository.yaml
kubectl get repository.ecr.aws.m.upbound.io -n default
crossplane resource trace repository.ecr.aws.m.upbound.io/course-images -n default
aws ecr describe-repositories --repository-names course-images
```

`READY` and `SYNCED` become `True` when the repository exists in AWS. Crossplane keeps it in
the declared state. If somebody changes the scan setting in the console, Crossplane sets
the declared value again. Delete the object to delete the repository. `forceDelete: true`
also deletes the images in it.

### Step 6: Build and validate a package

A Configuration package gives developers a small API, for example an `ImageRepository`
with only the necessary fields. A Composition in the package makes the AWS resources.
Validate the files before you apply them. For your own package in the directories
`package` and `examples`, build it:

```sh
crossplane resource validate --error-on-missing-schemas \
  crossplane/kubernetes/providers.yaml \
  crossplane/kubernetes/provider-config.yaml,crossplane/kubernetes/repository.yaml
crossplane xpkg build --package-root=package --examples-root=examples \
  --package-file=course-registry.xpkg
```

The validation downloads the schemas of Crossplane and of the providers. If a field is
wrong or a required field is missing, the validation fails before anything reaches the
cluster. The [smoke test](https://github.com/stden/docker-gems/blob/main/crossplane/smoke-test.sh)
has a complete package with an XRD, a Composition, and an example.

### Step 7: Remove Crossplane

Delete the managed resources first. A provider that you delete leaves its AWS resources
in place.

```sh
kubectl delete -f crossplane/kubernetes/repository.yaml
kubectl delete -f crossplane/kubernetes/provider-config.yaml
kubectl delete -k crossplane/kubernetes
helm uninstall crossplane --namespace crossplane-system
```

## Best practices

- **Install only the necessary providers.** Each AWS service has its own provider, for
  example `provider-aws-ecr`. Use the same version for the family provider and for each
  service provider. Pin that version.
- **Use EKS Pod Identity.** Do not put an AWS access key in a Kubernetes secret. Give each
  provider its own IAM role with the least privileges.
- **Validate in CI.** Run `crossplane resource validate` and `crossplane xpkg build` on each
  change, before Argo CD or `kubectl` applies the files.
- **Give developers an API, not raw cloud resources.** An XRD and a Composition hide the
  provider details and enforce the company settings, such as scan on push.
- **Delete in the right order.** Delete the managed resources, then the providers, then
  Crossplane. Otherwise the cloud resources stay and cost money.
- **Use GitOps.** Keep the Crossplane objects in git. Let Argo CD apply them
  ([stden/argocd](https://hub.docker.com/r/stden/argocd)).

## Source and checks

The smoke test builds a Configuration package, converts an XRD to a CRD, and validates an
example and a wrong example. It also checks Helm, kubectl, and the AWS CLI. A kind test
installs Crossplane with Helm from this image and installs the providers. It applies the
provider configuration and the repository, and traces the repository with the CLI. It
also validates the files against the provider schemas. The kind test has no AWS
credentials, so the provider cannot create the repository there.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/crossplane/Dockerfile)
- [Smoke test](https://github.com/stden/docker-gems/blob/main/crossplane/smoke-test.sh)
- [Kubernetes manifests](https://github.com/stden/docker-gems/tree/main/crossplane/kubernetes)
- [Overview source](https://github.com/stden/docker-gems/blob/main/crossplane/README.md)
- [Crossplane documentation](https://docs.crossplane.io/)
