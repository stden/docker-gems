# Install and use Crossplane on Kubernetes and EKS: the crossplane CLI, kubectl, helm,
# and the AWS CLI. An EKS kubeconfig calls the AWS CLI to get a token.
FROM debian:stable-slim AS download

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

# Download the newest stable release of each tool and check its SHA-256.
RUN set -eux; \
    mkdir /out; \
    cd /tmp; \
    base=https://cli.crossplane.io/stable/current/bin/linux_amd64; \
    curl -fsSLO "$base/crossplane"; \
    curl -fsSLO "$base/crossplane.sha256"; \
    echo "$(cut -d ' ' -f 1 crossplane.sha256)  crossplane" | sha256sum --check; \
    kubectl=$(curl -fsSL https://dl.k8s.io/release/stable.txt); \
    curl -fsSLO "https://dl.k8s.io/release/$kubectl/bin/linux/amd64/kubectl"; \
    curl -fsSLO "https://dl.k8s.io/release/$kubectl/bin/linux/amd64/kubectl.sha256"; \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check; \
    helm=$(curl -fsSL https://get.helm.sh/helm-latest-version); \
    curl -fsSLO "https://get.helm.sh/helm-$helm-linux-amd64.tar.gz"; \
    curl -fsSLO "https://get.helm.sh/helm-$helm-linux-amd64.tar.gz.sha256sum"; \
    sha256sum --check "helm-$helm-linux-amd64.tar.gz.sha256sum"; \
    tar -xzf "helm-$helm-linux-amd64.tar.gz" linux-amd64/helm; \
    install -m 0755 crossplane kubectl linux-amd64/helm /out/

FROM amazon/aws-cli:latest

# The base image has no tar and gzip. A package is a tar file.
RUN dnf install -y tar gzip \
 && dnf clean all \
 && rm -rf /var/cache/dnf

COPY --from=download /out/ /usr/local/bin/
RUN crossplane version --client \
 && kubectl version --client \
 && helm version \
 && aws --version

WORKDIR /workspace
# The base image starts the AWS CLI. Start a shell, as the other tool images do.
ENTRYPOINT []
CMD ["bash"]
