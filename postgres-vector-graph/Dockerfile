# Apache AGE 1.8.0 supports PostgreSQL 18.
FROM postgres:18 AS extensions

# https://github.com/pgvector/pgvector/blob/v0.8.7/CHANGELOG.md
ARG PGVECTOR_VERSION=0.8.7
# https://downloads.apache.org/age/PG18/1.8.0/
ARG AGE_VERSION=1.8.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bison \
        build-essential \
        ca-certificates \
        curl \
        flex \
        git \
        postgresql-server-dev-${PG_MAJOR} \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "v${PGVECTOR_VERSION}" \
        https://github.com/pgvector/pgvector.git /tmp/pgvector \
    && make -C /tmp/pgvector -j2 OPTFLAGS="" \
    && make -C /tmp/pgvector install DESTDIR=/opt/extensions \
    && rm -rf /tmp/pgvector

# Use the published Apache release, not a release-candidate Git tag.
RUN set -eux; \
    cd /tmp; \
    archive="apache-age-${AGE_VERSION}-src.tar.gz"; \
    release_url="https://downloads.apache.org/age/PG${PG_MAJOR}/${AGE_VERSION}"; \
    curl -fSLO "${release_url}/${archive}"; \
    curl -fSLO "${release_url}/${archive}.sha512"; \
    sha512sum -c "${archive}.sha512"; \
    mkdir age; \
    tar -xzf "$archive" -C age --strip-components=1; \
    make -C age -j2; \
    make -C age install DESTDIR=/opt/extensions; \
    rm -rf /tmp/age "/tmp/${archive}" "/tmp/${archive}.sha512"

FROM postgres:18

COPY --from=extensions /opt/extensions/ /

# Keep the official entrypoint, data volume, user switch, and command.
