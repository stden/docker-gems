---
name: crossplane-aws-providers
description: >-
  Use when the user asks to install or upgrade a Crossplane AWS provider. Also use
  when the user asks to give a provider AWS permissions with EKS Pod Identity.
  Also use when the user asks to add another AWS service (S3, RDS, IAM, ECR), or to create an AWS
  resource as a managed resource. The skill uses the community packages on
  xpkg.crossplane.io and crossplane/kubernetes.
---

# AWS providers with EKS Pod Identity

The manifests are in `crossplane/kubernetes`: `providers.yaml`, `provider-config.yaml`,
and `repository.yaml`. First, install Crossplane with the `crossplane-install` skill.

## Facts that the tests found

- Use the community packages `xpkg.crossplane.io/crossplane-contrib/provider-family-aws`
  and `.../provider-aws-<service>`, with the same version for all. An Upbound account is
  not necessary for them. Find the newest version with
  `gh api repos/crossplane-contrib/provider-upjet-aws/releases/latest --jq .tag_name`.
- Name the family provider `crossplane-contrib-provider-family-aws`. Crossplane installs
  the family as a dependency with this name. If you use another name, there are two
  copies, and no provider becomes healthy: `node xpkg.crossplane.io/crossplane-contrib/provider-family-aws already exists`.
- Namespaced managed resources use the API groups `<service>.aws.m.upbound.io`. A resource
  without `providerConfigRef` uses the `ClusterProviderConfig` named `default`.
- Each provider pod must have a `DeploymentRuntimeConfig` with the restricted settings.

## Give a provider an IAM role

```sh
account=$(aws sts get-caller-identity --query Account --output text)
aws iam create-role --role-name docker-gems-crossplane-ecr \
  --assume-role-policy-document file://pod-identity-trust.json
aws iam attach-role-policy --role-name docker-gems-crossplane-ecr --policy-arn <policy-arn>
aws eks create-pod-identity-association --cluster-name docker-gems \
  --namespace crossplane-system --service-account provider-aws \
  --role-arn "arn:aws:iam::$account:role/docker-gems-crossplane-ecr"
```

The trust policy allows `pods.eks.amazonaws.com` to run `sts:AssumeRole` and
`sts:TagSession`. Step 3 of `crossplane/README.md` has the file. If possible, use a policy
that has only the necessary actions. If the provider pod started before the association,
restart it.

## Install and check

```sh
kubectl apply -k crossplane/kubernetes
kubectl wait provider.pkg.crossplane.io --all --for=condition=Healthy --timeout=10m
kubectl apply -f crossplane/kubernetes/provider-config.yaml
kubectl apply -f crossplane/kubernetes/repository.yaml
crossplane resource trace repository.ecr.aws.m.upbound.io/course-images -n default
```

## Add another AWS service

1. Add a `Provider` for `provider-aws-<service>` with the same version as the family.
2. Give it its own `DeploymentRuntimeConfig`. Copy `aws-pod-identity`. Then change the name
   and `serviceAccountTemplate.metadata.name`, for example to `provider-aws-s3`. Two
   providers must not share one service account name.
3. Create an IAM role and a Pod Identity association for that service account.
4. Validate the files before you apply them:

```sh
crossplane resource validate --error-on-missing-schemas \
  crossplane/kubernetes/providers.yaml <your-resource>.yaml
```

## Rules

- Never put an AWS access key in a Kubernetes secret.
- Get the consent of the user before you create a managed resource. It creates a real AWS
  resource that costs money. When the work is complete, delete the managed resource.
