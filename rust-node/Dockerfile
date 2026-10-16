FROM node:latest AS node-tools
FROM rust:latest

COPY --from=node-tools /usr/local/bin/node /usr/local/bin/node
COPY --from=node-tools /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && npm install --global --no-audit --no-fund npm@latest \
    && npm cache clean --force

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential ca-certificates cmake git libssl-dev pkg-config \
    && rm -rf /var/lib/apt/lists/* \
    && rustup component add rustfmt clippy

WORKDIR /workspace
CMD ["bash"]
