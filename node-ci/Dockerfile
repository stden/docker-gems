# Build and test JavaScript and TypeScript projects in CI with Node.js, npm, pnpm, and Bun.
# The official Node.js image is the base. Node.js and npm come with it.
FROM node:slim

# Install security updates of the base image. Git reads the history of a mounted repository.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates git && \
    rm -rf /var/lib/apt/lists/*

# Install the package managers. The npm cache is not needed in the image.
RUN npm install --global --no-audit --no-fund pnpm bun && \
    npm cache clean --force

# Verify the tools at build time. A missing tool stops the build before publication.
RUN node --version && npm --version && pnpm --version && bun --version

WORKDIR /workspace
CMD ["bash"]
