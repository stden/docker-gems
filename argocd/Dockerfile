# Run Argo CD on Kubernetes and EKS, and use the argocd, helm, and kustomize commands.
# One image contains all Argo CD components and the argocd CLI.
# The latest tag of the upstream image is a nightly build, so use the newest stable
# release. Change this version together with argocd/kubernetes/kustomization.yaml.
FROM quay.io/argoproj/argocd:v3.6.1

# Install security updates for the Ubuntu packages. The image runs as uid 999, which cannot use apt.
USER root
RUN apt-get update \
 && apt-get upgrade -y \
 && rm -rf /var/lib/apt/lists/*
USER 999
