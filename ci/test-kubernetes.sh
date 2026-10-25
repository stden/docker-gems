#!/bin/bash
# Deploy the Kubernetes manifests of images to a temporary kind cluster and check them.
# ./ci/test-kubernetes.sh graphify codegraph - test <image>:latest with <image>/kubernetes
# Build or pull the images first. You must have Docker, kind, kubectl, and jq.
# GitHub-hosted Ubuntu runners have kind and kubectl. GitLab runners cannot start
# containers, so GitLab CI does not run this test.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
KEY=docker-gems-kind-test
WORK=$(mktemp -d)
CLUSTER="docker-gems-test-$(printf '%s' "${WORK##*.}" | tr '[:upper:]' '[:lower:]')"
TAG=$CLUSTER
cluster_started=false
export KUBECONFIG="$WORK/kubeconfig"
IMAGES=()
SELECTED=()

cleanup() {
  local status=$?
  local image
  if [[ "$cluster_started" == true && "$status" != 0 && -s "$KUBECONFIG" ]]; then
    echo "Cluster state after the failure:" >&2
    kubectl get pods,jobs,pvc -A -o wide >&2 || true
    kubectl get events -A --sort-by=.lastTimestamp 2>/dev/null | tail -n 40 >&2 || true
    for image in "${SELECTED[@]}"; do
      kubectl -n "$(namespace_of "$image")" logs -l app.kubernetes.io/name \
        --all-containers --prefix --tail=40 >&2 || true
    done
  fi
  if [[ "$cluster_started" == true ]]; then
    kind delete cluster --name "$CLUSTER" >/dev/null 2>&1 || true
  fi
  for image in "${IMAGES[@]}"; do
    docker rmi "$image:$TAG" >/dev/null 2>&1 || true
  done
  rm -rf "$WORK"
  exit "$status"
}
trap cleanup EXIT

# The namespace of an application is the name in its namespace.yaml.
namespace_of() {
  sed -n 's/^  name: *//p' "$ROOT/$1/kubernetes/namespace.yaml" | sed -n 1p
}

create_secrets() {
  local image=$1 namespace
  namespace=$(namespace_of "$image")
  case "$image" in
    graphify) kubectl -n "$namespace" create secret generic graphify-tools --from-literal=MCPO_API_KEY="$KEY" ;;
    codegraph) kubectl -n "$namespace" create secret generic codegraph-tools --from-literal=MCPO_API_KEY="$KEY" ;;
    open-webui) kubectl -n "$namespace" create secret generic open-webui --from-literal=WEBUI_SECRET_KEY="$KEY" ;;
  esac
}

# Use the local image instead of stden/<image>:latest. A tag other than latest makes
# the default pull policy IfNotPresent, so the node uses the loaded image.
deploy() {
  local image=$1
  echo "Deploy $image"
  docker tag "$image:latest" "$image:$TAG"
  IMAGES+=("$image")
  kind load docker-image --name "$CLUSTER" "$image:$TAG"
  # kustomize accepts only relative paths, so the overlay gets a copy of the manifests.
  mkdir -p "$WORK/$image"
  cp -R "$ROOT/$image/kubernetes" "$WORK/$image/base"
  cat > "$WORK/$image/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - base
images:
  - name: stden/$image
    newName: $image
    newTag: $TAG
EOF
  kubectl apply -f "$ROOT/$image/kubernetes/namespace.yaml"
  create_secrets "$image"
  if declare -F "prepare_${image//-/_}" >/dev/null; then
    "prepare_${image//-/_}"
  fi
  # Upstream manifests set imagePullPolicy: Always. With this policy, the node ignores the
  # loaded image. The Argo CD CRDs are too large for a client-side apply.
  kubectl kustomize "$WORK/$image" \
    | sed 's/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/' > "$WORK/$image.yaml"
  preload_images "$WORK/$image.yaml"
  kubectl apply --server-side --force-conflicts -f "$WORK/$image.yaml"
}

# ECR Public limits the anonymous pulls of each address ("Data limit exceeded"). Its
# docker/library repositories are copies of the Docker official images on Docker Hub.
docker_hub_copy() {
  case "$1" in
    public.ecr.aws/docker/library/*) echo "docker.io/library/${1#public.ecr.aws/docker/library/}" ;;
  esac
}

# Pull an image, and retry with a delay. If the registry refuses the pull and Docker Hub
# has a copy, pull the copy. Then give the copy the name from the manifest.
pull_image() {
  local ref=$1 copy attempt
  copy=$(docker_hub_copy "$ref")
  for attempt in 1 2 3 4 5; do
    docker pull -q "$ref" && return 0
    if [[ -n "$copy" ]] && docker pull -q "$copy" && docker tag "$copy" "$ref"; then
      return 0
    fi
    [[ "$attempt" == 5 ]] || sleep $((attempt * 15))
  done
  echo "Cannot pull $ref." >&2
  return 1
}

# Pull the other images of the manifests on the host, and load them into the node.
# Public registries limit anonymous pulls (HTTP 429), and the runners share addresses.
# The node then does not pull these images.
preload_images() {
  local ref
  for ref in $(sed -n 's/^ *image: *//p' "$1" | tr -d '"' | sort -u); do
    [[ "$ref" == *:"$TAG" ]] && continue
    pull_image "$ref" || return 1
    # kind load imports all platforms, but the containerd image store of Docker keeps
    # only the amd64 layers of a multi-platform image. Import the node platform only.
    docker save "$ref" | docker exec -i "$CLUSTER-control-plane" \
      ctr --namespace=k8s.io images import --digests --snapshotter=overlayfs -
  done
}

# Run a command of the tested image on the host network, so that it reaches the cluster.
# The repository is in /workspace.
run_image() {
  local image=$1
  shift
  docker run --rm --network host -v "$KUBECONFIG:/kubeconfig:ro" -e KUBECONFIG=/kubeconfig \
    -v "$ROOT:/workspace:ro" -w /workspace "$image:$TAG" "$@"
}

# Crossplane comes from its Helm chart. Use helm from the tested image.
prepare_crossplane() {
  run_image crossplane helm install crossplane crossplane --repo https://charts.crossplane.io/stable \
    --namespace crossplane-system -f crossplane/kubernetes/helm-values.yaml --wait --timeout 10m
}

wait_for_job() {
  local namespace=$1 job=$2 condition
  local _
  for _ in $(seq 1 120); do
    condition=$(kubectl -n "$namespace" get job "$job" \
      -o jsonpath='{range .status.conditions[?(@.status=="True")]}{.type} {end}')
    if [[ "$condition" == *Complete* ]]; then
      return 0
    fi
    if [[ "$condition" == *Failed* ]]; then
      kubectl -n "$namespace" logs "job/$job" >&2 || true
      return 1
    fi
    sleep 5
  done
  echo "The job $namespace/$job did not finish in 10 minutes." >&2
  return 1
}

# Run curl in a container of the namespace. The request uses the Service DNS name,
# as a request from another pod does.
curl_in() {
  local namespace=$1 target=$2
  shift 2
  kubectl -n "$namespace" exec "$target" -- curl "$@"
}

check_graphify() {
  local url=http://graphify-tools.graphify.svc.cluster.local:8000 answer code
  kubectl -n graphify rollout status deployment/graphify-tools --timeout=600s
  code=$(curl_in graphify deployment/graphify-tools -s -o /dev/null -w '%{http_code}' "$url/openapi.json")
  [[ "$code" == 401 ]]
  answer=$(curl_in graphify deployment/graphify-tools -fsS -X POST -H "Authorization: Bearer $KEY" \
    -H 'Content-Type: application/json' -d '{"question": "publish image"}' "$url/query_graph")
  printf '%s\n' "${answer:0:300}"
  [[ "$answer" == *NODE* ]]
}

check_codegraph() {
  local url=http://codegraph-tools.codegraph.svc.cluster.local:8000 answer
  wait_for_job codegraph codegraph-affected-tests
  kubectl -n codegraph logs job/codegraph-affected-tests | grep -F 'Tests affected by the last commit:'
  kubectl -n codegraph rollout status deployment/codegraph-tools --timeout=600s
  answer=$(curl_in codegraph deployment/codegraph-tools -fsS -X POST -H "Authorization: Bearer $KEY" \
    -H 'Content-Type: application/json' -d '{"query": "publish image"}' "$url/codegraph_explore")
  printf '%s\n' "${answer:0:300}"
  [[ "$answer" == *Exploration* ]]
}

check_argocd() {
  local version _ synced
  version=$(sed -n 's|.*/argo-cd/\(v[0-9.]*\)/manifests/install.yaml|\1|p' \
    "$ROOT/argocd/kubernetes/kustomization.yaml")
  kubectl -n argocd rollout status deployment/argocd-server --timeout=600s
  kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=600s
  kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=600s
  # The image and the installed manifest must have the same version.
  kubectl -n argocd exec deployment/argocd-server -- argocd version --client --short | grep -F "$version"
  kubectl apply -f "$ROOT/argocd/applications/project.yaml"
  kubectl apply --dry-run=server -f "$ROOT/argocd/applications/docker-gems.yaml"
  if is_selected java-eks; then
    echo "Skip the GitOps check, because this run deploys java-eks itself."
    return
  fi
  echo "GitOps check: Argo CD deploys java-eks/kubernetes from GitHub"
  kubectl -n argocd exec deployment/argocd-server -- argocd admin app generate-spec java-eks \
    --repo https://github.com/stden/docker-gems.git --path java-eks/kubernetes --revision main \
    --dest-server https://kubernetes.default.svc --dest-namespace eks-demo --project docker-gems \
    --sync-policy automated --sync-option ServerSideApply=true \
    | kubectl -n argocd apply -f -
  for _ in $(seq 1 120); do
    synced=$(kubectl -n argocd get application java-eks -o jsonpath='{.status.sync.status}')
    [[ "$synced" == Synced ]] && break
    sleep 5
  done
  [[ "$synced" == Synced ]]
  # Argo CD got the manifests from git, rendered them, and applied them. Do not wait for
  # the pods. They pull stden/java-eks from Docker Hub without a login. All jobs on a
  # runner address share the limit for anonymous pulls.
  kubectl -n eks-demo get deployment/eks-demo service/eks-demo ingress/eks-demo-ingress
}

check_crossplane() {
  local files=$ROOT/crossplane/kubernetes
  kubectl wait provider.pkg.crossplane.io --all --for=condition=Healthy --timeout=600s
  kubectl apply -f "$files/provider-config.yaml" -f "$files/repository.yaml"
  # Without AWS credentials the provider cannot create the repository, but the API
  # server accepts the objects, and the CLI of the image can trace them.
  run_image crossplane crossplane resource trace repository.ecr.aws.m.upbound.io/course-images -n default
  run_image crossplane crossplane resource validate --cache-dir /tmp/cache --error-on-missing-schemas \
    crossplane/kubernetes/providers.yaml \
    crossplane/kubernetes/provider-config.yaml,crossplane/kubernetes/repository.yaml
}

check_java_eks() {
  kubectl -n eks-demo rollout status deployment/eks-demo --timeout=600s
}

check_open_webui() {
  local local_url=http://localhost:8080 token
  kubectl -n open-webui rollout status deployment/open-webui --timeout=900s
  curl_in open-webui deployment/open-webui -fsS "$local_url/health"
  echo
  token=$(curl_in open-webui deployment/open-webui -fsS -H 'Content-Type: application/json' \
    -d '{"name": "Admin", "email": "admin@example.com", "password": "Kind-test-password-1"}' \
    "$local_url/api/v1/auths/signup" | jq -r '.token')
  [[ -n "$token" && "$token" != null ]]
  # Check that the Open WebUI server can use the tool servers that this run deployed.
  local server
  for server in graphify codegraph; do
    is_selected "$server" || continue
    echo "Check the $server tool server from Open WebUI"
    kubectl -n "$server" rollout status "deployment/$server-tools" --timeout=600s
    curl_in open-webui deployment/open-webui -fsS -H "Authorization: Bearer $token" \
      -H 'Content-Type: application/json' \
      -d "{\"url\": \"http://$server-tools.$server.svc.cluster.local:8000\", \"path\": \"openapi.json\",
           \"type\": \"openapi\", \"auth_type\": \"bearer\", \"key\": \"$KEY\", \"config\": {}}" \
      "$local_url/api/v1/configs/tool_servers/verify" | jq -e '.openapi and (.paths | length > 0)' >/dev/null
  done
}

is_selected() {
  local image
  for image in "${SELECTED[@]}"; do
    [[ "$image" == "$1" ]] && return 0
  done
  return 1
}

main() {
  if (($# == 0)); then
    echo "Usage: $0 IMAGE..." >&2
    exit 2
  fi
  local image
  for image in "$@"; do
    if [[ ! -f "$ROOT/$image/kubernetes/kustomization.yaml" ]]; then
      echo "No Kubernetes manifests: $image/kubernetes/kustomization.yaml" >&2
      exit 2
    fi
    docker image inspect "$image:latest" >/dev/null
  done
  SELECTED=("$@")
  command -v kind >/dev/null
  command -v kubectl >/dev/null
  command -v jq >/dev/null

  local clusters
  clusters=$(kind get clusters)
  if grep -Fxq "$CLUSTER" <<< "$clusters"; then
    echo "Cluster already exists: $CLUSTER" >&2
    exit 1
  fi
  # If cluster creation fails, remove partial nodes under this unique cluster name.
  cluster_started=true
  kind create cluster --name "$CLUSTER" --kubeconfig "$KUBECONFIG" --wait 180s
  for image in "$@"; do
    deploy "$image"
  done
  for image in "$@"; do
    echo "===== Kubernetes check: $image ====="
    "check_${image//-/_}"
    echo "OK $image"
  done
  echo "All Kubernetes checks passed."
}

main "$@"
