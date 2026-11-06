# Stage 1: a named build stage that holds the Node.js binary and modules.
# The python:latest base image below does not ship Node.js.
FROM node:latest AS node-tools

# Base image: python:latest. Node.js tools come from the stage above.
FROM python:latest

# PYTHONDONTWRITEBYTECODE and PYTHONUNBUFFERED give cleaner container output.
# PLAYWRIGHT_BROWSERS_PATH keeps the Chromium download in one known location.
# CHROME_BIN and CHROME_PATH tell the axe CLI and Lighthouse where to find Chrome.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    CHROME_BIN=/usr/bin/google-chrome \
    CHROME_PATH=/usr/bin/google-chrome

# COPY --from extracts only the Node.js binary and modules from the build stage.
# This avoids a full Node.js installation in the Python image.
COPY --from=node-tools /usr/local/bin/node /usr/local/bin/node
COPY --from=node-tools /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Symlink the npm and npx CLI scripts so they resolve as top-level commands.
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Install Playwright before the security upgrade.
# Playwright calls apt-get internally to add browser dependencies.
# The security upgrade in the next step covers those packages too.
RUN uv pip install --system --no-cache pytest behave playwright pytest-playwright \
 && python -m playwright install --with-deps chromium \
 && chmod -R a+rX /ms-playwright \
 && rm -rf /var/lib/apt/lists/*

# Install security updates after Playwright because Playwright adds packages with apt-get.
# An earlier upgrade does not cover the packages that Playwright adds.
RUN test "$(dpkg --print-architecture)" = amd64 \
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && curl -fsSL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
      -o /tmp/chrome.deb \
 && apt-get install -y --no-install-recommends /tmp/chrome.deb \
 && rm -f /tmp/chrome.deb \
 && rm -rf /var/lib/apt/lists/*

# Match axe's ChromeDriver to the installed stable Google Chrome.
RUN npm install --global --no-audit --no-fund npm@latest \
 && DETECT_CHROMEDRIVER_VERSION=true npm install --global --no-audit --no-fund \
      --allow-scripts=chromedriver lighthouse @axe-core/cli \
 && npm cache clean --force

# Verify the tools at build time. A missing tool stops the build before publication.
RUN python --version && node --version && pytest --version && playwright --version

WORKDIR /workspace
CMD ["bash"]
