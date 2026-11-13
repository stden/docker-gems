---
name: copy-images-to-ecr
description: >-
  Use when the user asks to copy, push, mirror, or prepare the course images for
  Amazon ECR. Also use when the user asks to configure the GitHub Actions workflow
  that copies them, or to check which image digest is in ECR. The skill runs
  aws/copy-to-ecr.sh, which keeps the digest of the tested image. For the cluster
  and the deployments, use deploy-images-to-eks.
---

# Copy images to Amazon ECR

The full explanation is in `aws/README.md`, step 1. This skill is the procedure.

## 1. Before you start

- Confirm the AWS account and the Region with the user. ECR storage costs about USD 0.10
  for each GB for each month. The `open-webui` image is about 1.6 GB.
- Check the identity: `aws sts get-caller-identity`. If it fails, ask the user to sign in
  in their own terminal, for example with `aws configure sso`. Never ask for an access key
  in the chat. Never write an access key to a file.

## 2. Copy

```sh
export AWS_REGION=<region>
aws/copy-to-ecr.sh open-webui graphify codegraph java-eks
```

For each image, the script creates the repository `docker-gems/<image>` if necessary, sets
the lifecycle policy, and copies the image. It prints `Copied: <uri>@<digest>`. It stops
with an error if the digest in ECR is not the digest on Docker Hub.

## 3. Check

```sh
aws ecr describe-images --repository-name docker-gems/<image> \
  --query 'imageDetails[].{tags: imageTags, digest: imageDigest}'
aws ecr describe-image-scan-findings --repository-name docker-gems/<image> \
  --image-id imageTag=latest --query 'imageScanFindings.findingSeverityCounts'
```

Report the digests and the counts of findings for each severity.

## 4. GitHub Actions

The one-time IAM and OIDC setup is in `aws/README.md`, "Optional: copy the images with
GitHub Actions". After the setup, start the workflow. Then show its run:

```sh
gh workflow run aws-ecr.yml -f images="open-webui graphify codegraph java-eks"
gh run list --workflow aws-ecr.yml --limit 1
```

## Rules

- Run `aws ecr put-registry-scanning-configuration` only with the consent of the user. It
  replaces the scanning rules of the whole registry.
- Do not delete a repository unless the user asks for it.
- After you change `aws/copy-to-ecr.sh`, run `bash ci/test-copy-to-ecr.sh`. It runs without
  an AWS account.
