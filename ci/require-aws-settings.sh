#!/bin/bash
# Stop when the Amazon ECR copy has no role or no Region.
# Usage: AWS_ROLE_ARN=... AWS_REGION=... ci/require-aws-settings.sh
set -euo pipefail

if [[ -z "${AWS_ROLE_ARN:-}" || -z "${AWS_REGION:-}" ]]; then
  echo '::error::Set the repository variables AWS_ROLE_ARN and AWS_REGION. See aws/README.md.'
  exit 1
fi
