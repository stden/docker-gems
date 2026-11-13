#!/usr/bin/env bash
# Run the offline steps of the tutorial in argocd/README.md. No cluster is necessary.
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

argocd version --client
helm version
kustomize version
git --version
# All Argo CD components are one binary with different names.
for component in argocd-server argocd-repo-server argocd-application-controller \
    argocd-applicationset-controller argocd-dex argocd-notifications; do
    "$component" --help > /dev/null
done

# Step 1: write an Application without a cluster.
argocd admin app generate-spec java-eks \
    --repo https://github.com/stden/docker-gems.git --path java-eks/kubernetes --revision main \
    --dest-server https://kubernetes.default.svc --dest-namespace eks-demo --project docker-gems \
    --sync-policy automated --self-heal --auto-prune --sync-option ServerSideApply=true > app.yaml
grep -Fx 'kind: Application' app.yaml
grep -F 'path: java-eks/kubernetes' app.yaml
grep -F 'selfHeal: true' app.yaml
grep -F -- '- ServerSideApply=true' app.yaml

# Step 2: test an RBAC policy. The commands must have a kubeconfig, but they do not use it.
cat > kubeconfig <<'YAML'
apiVersion: v1
kind: Config
clusters: [{name: offline, cluster: {server: "https://127.0.0.1:9"}}]
users: [{name: offline, user: {token: offline}}]
contexts: [{name: offline, context: {cluster: offline, user: offline, namespace: argocd}}]
current-context: offline
YAML
export KUBECONFIG="$work/kubeconfig"
cat > policy.csv <<'CSV'
p, role:deployer, applications, get, docker-gems/*, allow
p, role:deployer, applications, sync, docker-gems/*, allow
g, students, role:deployer
CSV
argocd admin settings rbac validate --policy-file policy.csv
[[ $(argocd admin settings rbac can students sync applications docker-gems/java-eks --policy-file policy.csv) == Yes ]]
answer=$(argocd admin settings rbac can students delete applications docker-gems/java-eks \
    --policy-file policy.csv || true)
[[ "$answer" == No ]]

# Step 3: render manifests as the repo server does, with kustomize and Helm.
mkdir app
cat > app/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: demo
configMapGenerator:
  - name: greeting
    literals:
      - message=hello
YAML
kustomize build app | tee rendered.yaml
grep -Fx 'kind: ConfigMap' rendered.yaml
grep -F 'namespace: demo' rendered.yaml
helm create chart > /dev/null
helm lint chart
helm template demo ./chart --set replicaCount=2 > chart.yaml
grep -F 'replicas: 2' chart.yaml
echo "Application spec, RBAC policy, kustomize, and Helm checks passed."
