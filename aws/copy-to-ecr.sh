#!/bin/bash
# Copy tested images from Docker Hub to Amazon ECR and keep their digests.
# Usage: aws/copy-to-ecr.sh IMAGE...   for example: aws/copy-to-ecr.sh open-webui graphify
# You must have AWS CLI 2.27.57 or later with credentials, and Docker with buildx.
# AWS_REGION selects the Region. Without it, the script uses the Region of the AWS CLI profile.
# ECR_PREFIX sets the repository prefix. The default is docker-gems.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(dirname "$HERE")
SOURCE=docker.io/stden
PREFIX=${ECR_PREFIX:-docker-gems}
TAG=latest

if (($# == 0)); then
  echo "Usage: $0 IMAGE..." >&2
  exit 2
fi
for image in "$@"; do
  if [[ ! "$image" =~ ^[a-z0-9][a-z0-9-]*$ || ! -f "$ROOT/$image/Dockerfile" ]]; then
    echo "Unknown image: $image" >&2
    exit 2
  fi
done
region=${AWS_REGION:-$(aws configure get region || true)}
if [[ -z "$region" ]]; then
  echo "Set AWS_REGION, or set a Region in the AWS CLI profile." >&2
  exit 2
fi

# Print the URI of the repository. If the repository does not exist, create it.
# All tags except latest are immutable, so a version tag always means the same image.
repository_uri() {
  local repository=$1
  aws ecr describe-repositories --region "$region" --repository-names "$repository" \
    --query 'repositories[0].repositoryUri' --output text 2>/dev/null && return
  echo "Create the repository $repository" >&2
  aws ecr create-repository --region "$region" --repository-name "$repository" \
    --image-tag-mutability IMMUTABLE_WITH_EXCLUSION \
    --image-tag-mutability-exclusion-filters filterType=WILDCARD,filter=latest \
    --encryption-configuration encryptionType=AES256 \
    --query 'repository.repositoryUri' --output text
}

logged_in=
for image in "$@"; do
  repository="$PREFIX/$image"
  uri=$(repository_uri "$repository")
  registry=${uri%%/*}
  if [[ "$logged_in" != "$registry" ]]; then
    aws ecr get-login-password --region "$region" \
      | docker login --username AWS --password-stdin "$registry"
    logged_in=$registry
  fi
  aws ecr put-lifecycle-policy --region "$region" --repository-name "$repository" \
    --lifecycle-policy-text "file://$HERE/ecr-lifecycle-policy.json" >/dev/null

  # Copy the digest that the tag points to now. --prefer-index=false keeps the
  # manifest unchanged, so the image in ECR has the digest of the tested image.
  digest=$(docker buildx imagetools inspect "$SOURCE/$image:$TAG" --format '{{.Manifest.Digest}}')
  echo "Copy $SOURCE/$image@$digest to $uri:$TAG"
  docker buildx imagetools create --prefer-index=false --tag "$uri:$TAG" "$SOURCE/$image@$digest"
  copied=$(docker buildx imagetools inspect "$uri:$TAG" --format '{{.Manifest.Digest}}')
  if [[ "$copied" != "$digest" ]]; then
    echo "The digest in ECR ($copied) is not the source digest ($digest)." >&2
    exit 1
  fi
  echo "Copied: $uri@$digest"
done
