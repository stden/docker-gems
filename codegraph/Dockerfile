# Index code into a CodeGraph SQLite graph and query it.
FROM node:latest

# Do not send anonymous usage statistics from shared and CI containers.
# To enable them, set CODEGRAPH_TELEMETRY=1 when you run the container.
# A new image build gets the new release, so the update check is off.
ENV CODEGRAPH_TELEMETRY=0 CODEGRAPH_NO_UPDATE_CHECK=1

# The npm package installs a platform bundle with its own Node.js runtime.
RUN npm install --global --no-audit --no-fund @colbymchenry/codegraph \
 && npm cache clean --force \
 && codegraph --version

# The CodeGraph MCP server uses stdio only. mcpo publishes its tools as an OpenAPI
# server, for example for Open WebUI. mcpo 0.0.20 fails with mcp 2 and with
# FastAPI 0.145 or later, so its environment has these limits. See AGENTS.md.
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3-venv \
 && rm -rf /var/lib/apt/lists/* \
 && python3 -m venv /opt/mcpo \
 && /opt/mcpo/bin/pip install --no-cache-dir mcpo "mcp<2" "fastapi<0.145" \
 && ln -s /opt/mcpo/bin/mcpo /usr/local/bin/mcpo \
 && /opt/mcpo/bin/python -c 'import mcpo.main'

WORKDIR /workspace
CMD ["bash"]
