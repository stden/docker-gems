# Build and query Graphify knowledge graphs of code and documents.
FROM python:latest

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# Code extraction is offline. The extras add the MCP server, watch mode, Leiden
# clustering, PDF, Office, SQL, and SVG support, and the Anthropic and OpenAI
# clients for document extraction. The "all" extra does not install on the
# newest Python, because its video tools have no wheels for it.
RUN pip install --no-cache-dir --root-user-action=ignore \
      "graphifyy[mcp,watch,leiden,pdf,office,svg,sql,anthropic,openai]" \
    && graphify --version

# mcpo publishes the MCP tools as an OpenAPI server, for example for Open WebUI.
# mcpo 0.0.20 fails with mcp 2 and with FastAPI 0.145 or later, so it has its own
# environment with these limits. Graphify keeps mcp 2. See AGENTS.md.
RUN python -m venv /opt/mcpo \
    && /opt/mcpo/bin/pip install --no-cache-dir mcpo "mcp<2" "fastapi<0.145" \
    && ln -s /opt/mcpo/bin/mcpo /usr/local/bin/mcpo \
    && /opt/mcpo/bin/python -c 'import mcpo.main'

WORKDIR /workspace
CMD ["bash"]
