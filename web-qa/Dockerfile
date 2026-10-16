FROM node:latest AS node-tools
FROM python:latest

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    CHROME_BIN=/usr/bin/google-chrome \
    CHROME_PATH=/usr/bin/google-chrome

COPY --from=node-tools /usr/local/bin/node /usr/local/bin/node
COPY --from=node-tools /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Install the browser revision that matches the installed Playwright package.
RUN uv pip install --system --no-cache pytest behave playwright pytest-playwright \
 && python -m playwright install --with-deps chromium \
 && chmod -R a+rX /ms-playwright \
 && rm -rf /var/lib/apt/lists/*

RUN test "$(dpkg --print-architecture)" = amd64 \
 && apt-get update \
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

WORKDIR /workspace
CMD ["bash"]
