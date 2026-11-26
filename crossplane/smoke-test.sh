#!/usr/bin/env bash
# Run the offline steps of the tutorial in crossplane/README.md. No cluster is necessary.
# Validation downloads the Crossplane schemas from xpkg.crossplane.io once.
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

crossplane version --client
kubectl version --client
helm version
aws --version

# Step 1: write a Configuration package: an API for image repositories, its Composition,
# and an example.
mkdir -p package examples
cat > package/crossplane.yaml <<'YAML'
apiVersion: meta.pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: course-registry
spec:
  crossplane:
    version: ">=v2.0.0"
  dependsOn:
    - function: xpkg.crossplane.io/crossplane-contrib/function-patch-and-transform
      version: ">=v0.8.0"
YAML
cat > package/definition.yaml <<'YAML'
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
metadata:
  name: imagerepositories.course.example.org
spec:
  group: course.example.org
  names:
    kind: ImageRepository
    plural: imagerepositories
  scope: Namespaced
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                region:
                  type: string
                  enum: [us-east-1, eu-central-1]
                scanOnPush:
                  type: boolean
              required: [region]
YAML
cat > package/composition.yaml <<'YAML'
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: imagerepositories-aws
spec:
  compositeTypeRef:
    apiVersion: course.example.org/v1alpha1
    kind: ImageRepository
  mode: Pipeline
  pipeline:
    - step: patch-and-transform
      functionRef:
        name: crossplane-contrib-function-patch-and-transform
      input:
        apiVersion: pt.fn.crossplane.io/v1beta1
        kind: Resources
        resources:
          - name: repository
            base:
              apiVersion: ecr.aws.m.upbound.io/v1beta1
              kind: Repository
              spec:
                forProvider:
                  imageTagMutability: IMMUTABLE
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: spec.region
                toFieldPath: spec.forProvider.region
              - type: FromCompositeFieldPath
                fromFieldPath: spec.scanOnPush
                toFieldPath: spec.forProvider.imageScanningConfiguration.scanOnPush
YAML
cat > examples/repository.yaml <<'YAML'
apiVersion: course.example.org/v1alpha1
kind: ImageRepository
metadata:
  name: graphify
  namespace: default
spec:
  region: us-east-1
  scanOnPush: true
YAML

# Step 2: build the package. A package is an OCI image that you can push to a registry.
crossplane xpkg build --package-root=package --examples-root=examples \
    --package-file=course-registry.xpkg
tar -tf course-registry.xpkg | grep -Fx manifest.json

# Step 3: convert the XRD to the CRD that Crossplane creates in the cluster.
crossplane xrd convert package/definition.yaml > crd.yaml
grep -Fx 'kind: CustomResourceDefinition' crd.yaml

# Step 4: validate the example against the XRD. A wrong Region must fail.
crossplane resource validate --cache-dir "$work/cache" --error-on-missing-schemas \
    package/definition.yaml examples/repository.yaml
sed 's/us-east-1/mars-1/' examples/repository.yaml > wrong-region.yaml
if crossplane resource validate --cache-dir "$work/cache" package/definition.yaml wrong-region.yaml; then
    echo 'FAIL: the validation accepted an unknown Region.' >&2
    exit 1
fi

# Step 5: check the other tools offline.
helm create chart > /dev/null
helm template demo ./chart --set replicaCount=2 | grep -F 'replicas: 2'
kubectl create deployment demo --image=stden/graphify:latest --dry-run=client -o yaml \
    | grep -F 'image: stden/graphify:latest'
jq -n '{Version: "2012-10-17"}' | jq -e '.Version == "2012-10-17"'
echo "Package build, XRD conversion, validation, Helm, kubectl, and AWS CLI checks passed."
