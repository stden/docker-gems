FROM python:latest

ARG TYPST_VERSION=0.15.1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Install the security updates of the base image first. The official image can be
# days behind the security repository of the distribution.
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl fontconfig fonts-dejavu fonts-liberation poppler-utils \
      libxinerama1 libdbus-1-3 libcups2t64 libx11-xcb1 \
 && rm -rf /var/lib/apt/lists/*

# Verify the stable Typst archive with the digest in its official release metadata.
# https://api.github.com/repos/typst/typst/releases/tags/v0.15.1
RUN case "$(dpkg --print-architecture)" in \
      amd64) arch=x86_64; digest=a6d077d0a95eed5a2eba715b2dae06be954f624ccbf85758a03f389ded33118c ;; \
      arm64) arch=aarch64; digest=5aa8d74a3d906e60ea12a66ac2f37f8eef1b14cbad7182a745e393a10c23dcee ;; \
      *) echo 'Unsupported Typst architecture.' >&2; exit 1 ;; \
    esac \
 && curl -fsSL "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${arch}-unknown-linux-musl.tar.xz" \
      -o /tmp/typst.tar.xz \
 && echo "$digest  /tmp/typst.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/typst.tar.xz -C /usr/local/bin --strip-components=1 \
      "typst-${arch}-unknown-linux-musl/typst" \
 && rm /tmp/typst.tar.xz

# Use the vendor's current stable suite for Writer and headless conversion.
RUN test "$(dpkg --print-architecture)" = amd64 \
 && version=$(curl -fsSL https://download.documentfoundation.org/libreoffice/stable/ \
      | sed -n 's/.*href="\([0-9][0-9.]*\)\/".*/\1/p' | sort -V | tail -n 1) \
 && test -n "$version" \
 && archive="LibreOffice_${version}_Linux_x86-64_deb.tar.gz" \
 && url="https://download.documentfoundation.org/libreoffice/stable/$version/deb/x86_64/$archive" \
 && mkdir /tmp/libreoffice \
 && cd /tmp/libreoffice \
 && curl -fsSL "$url" -o "$archive" \
 && curl -fsSL "$url.sha256" -o checksum \
 && sha256sum --check checksum \
 && tar -xzf "$archive" \
 && apt-get update \
 && apt-get install -y --no-install-recommends /tmp/libreoffice/LibreOffice_*/DEBS/*.deb \
 && ln -s "/opt/libreoffice${version%.*}/program/soffice" /usr/local/bin/libreoffice \
 && ln -s /usr/local/bin/libreoffice /usr/local/bin/soffice \
 && rm -rf /tmp/libreoffice /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["bash"]
