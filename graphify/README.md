# stden/graphify

Build Graphify knowledge graphs of code and documents, then query them from the CLI or MCP.

## Overview

This image contains [Graphify](https://github.com/Graphify-Labs/graphify), the
`graphifyy` package on PyPI. Graphify reads a project directory and writes a knowledge
graph of its code, documents, and papers. AI coding assistants query this graph, so
they do not read every file.

The image contains:

- The `graphify` command and the `graphify-mcp` server.
- [mcpo](https://github.com/open-webui/mcpo), which publishes the MCP tools as an OpenAPI
  HTTP server for Open WebUI and other HTTP clients.
- Support for MCP, watch mode, Leiden clustering, PDF, Office, SQL, and SVG export.
- The Anthropic and OpenAI client libraries for document extraction with a language model.

Code extraction uses tree-sitter in the container. It works without an API key and
without a network connection. For documents, papers, and images, a language model is
necessary. The base image is `python:latest`. The working directory is `/workspace`. The
default command starts Bash.

To run the tool server on Kubernetes or Amazon EKS, use the manifests in
[graphify/kubernetes](https://github.com/stden/docker-gems/tree/main/graphify/kubernetes).
The [AWS guide](https://github.com/stden/docker-gems/blob/main/aws/README.md) gives the steps.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` with the newest Graphify release. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/graphify/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/graphify:latest
```

## Tutorial

Do these steps in your project directory. The commands mount the directory at
`/workspace` and run as your user, so the output files belong to you. Set a short
name for the command first:

```sh
alias graphify='docker run --rm -i --user "$(id -u):$(id -g)" -v "$PWD":/workspace stden/graphify:latest graphify'
```

### Step 1: Exclude files

Graphify skips the files in `.gitignore`. Add a `.graphifyignore` file for other
files that you do not want in the graph, such as generated code:

```sh
printf 'generated/\nvendor/\n*.min.js\n' > .graphifyignore
```

### Step 2: Build the graph

```sh
graphify extract . --code-only
graphify cluster-only . --no-label
```

The commands write the `graphify-out/` directory:

- `graph.json` contains the full graph.
- `GRAPH_REPORT.md` lists the most connected nodes, the communities, and unexpected
  connections. Read this file first.
- `graph.html` shows the graph in a browser.

### Step 3: Query the graph

```sh
graphify query "How does login work?"
graphify explain UserService
graphify path Router Database
```

`query` starts at the nodes that match the question and follows their connections.
`explain` shows one node and its connections. `path` shows the shortest path between two
nodes. For scripts, the exit codes are 0 for an answer, 3 for an ambiguous name, and 4 for
no match.

### Step 4: Update the graph after a change

```sh
graphify update .
graphify cluster-only . --no-label
```

`update` extracts the changed code files again. It does not use a language model.
`cluster-only` updates the communities and the report.

### Step 5: Export the graph

```sh
graphify export svg
graphify export graphml
```

Add `graph.svg` to a document or a wiki page. Open the GraphML file in a graph tool
such as Gephi or yEd.

### Step 6: Connect an AI assistant over MCP

Add this server to the MCP configuration of your assistant. Replace
`/path/to/project` with the absolute path of your project.

```json
{
  "mcpServers": {
    "graphify": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i", "-v", "/path/to/project:/workspace",
        "stden/graphify:latest", "graphify-mcp", "graphify-out/graph.json"
      ]
    }
  }
}
```

The server gives tools such as `query_graph`, `get_node`, `get_neighbors`, and
`shortest_path`.

For an MCP client that uses Streamable HTTP, start `graphify-mcp` with the HTTP transport:

```sh
openssl rand -hex 32 > mcp-api.key
docker run -d --name graphify-mcp -p 127.0.0.1:8080:8080 --user "$(id -u):$(id -g)" \
  -v "$PWD":/workspace stden/graphify:latest \
  graphify-mcp --transport http --host 0.0.0.0 --port 8080 \
  --api-key "$(cat mcp-api.key)" graphify-out/graph.json
```

The MCP endpoint is `http://127.0.0.1:8080/mcp`. Each request must send the key as
`Authorization: Bearer <key>`. Without the key, the server answers HTTP 401.

### Step 7: Serve the tools over HTTP with mcpo

mcpo starts `graphify-mcp` and publishes each tool as a `POST /<tool>` endpoint. The API
description is at `/openapi.json`, and the interactive documentation is at `/docs`.
With `--strict-auth`, every request must send the key as `Authorization: Bearer <key>`.

```sh
openssl rand -hex 32 > mcpo-api.key
docker run -d --name graphify-tools -p 127.0.0.1:8000:8000 --user "$(id -u):$(id -g)" \
  -v "$PWD":/workspace stden/graphify:latest \
  mcpo --port 8000 --api-key "$(cat mcpo-api.key)" --strict-auth -- \
  graphify-mcp graphify-out/graph.json

curl -H "Authorization: Bearer $(cat mcpo-api.key)" -H 'Content-Type: application/json' \
  -d '{"question": "How does login work?"}' http://127.0.0.1:8000/query_graph
```

To connect [Open WebUI](https://hub.docker.com/r/stden/open-webui), put both containers on
one Docker network. Then the Open WebUI server can find the tool server by its name:

```sh
docker network create ai-tools
docker network connect ai-tools open-webui
docker network connect ai-tools graphify-tools
```

In Open WebUI, open **Admin Panel → Settings → Integrations**. In the **Tools** section,
under **External Tool Servers**, select **Add Connection**. Then select the **OpenAPI**
type. Enter the URL `http://graphify-tools:8000`, the path `openapi.json`, and the Bearer
key from `mcpo-api.key`.

For an admin connection, the Open WebUI server calls the tool server. For a connection in
the personal **Settings → Integrations**, your browser calls the tool server, so the
connection must use the URL `http://127.0.0.1:8000` instead.

### Optional: Add documents with a language model

Remove `--code-only` to also read documents, papers, and images. Give the container
the API key of the model provider. Graphify uses the backend of the key that you set.

```sh
docker run --rm -e ANTHROPIC_API_KEY --user "$(id -u):$(id -g)" \
  -v "$PWD":/workspace stden/graphify:latest graphify extract .
```

Use `OPENAI_API_KEY` for OpenAI. The `--backend` option also selects `gemini`,
`deepseek`, `kimi`, or `ollama`.

## Best practices

- **Start with code only.** `--code-only` is free, fast, and offline. Add documents
  later, when you know which documents are necessary for the assistant.
- **Keep private code on your computer.** A language model backend sends file
  contents to its provider. Use `--code-only` for code that must stay on your computer.
- **Keep secrets out of the graph.** Put secret files, data dumps, and build output
  in `.graphifyignore`. Do not mount more than the project directory into the container.
- **Pass API keys from the environment.** Use `-e ANTHROPIC_API_KEY` without a value.
  Do not write a key on the command line, in a Dockerfile, or in the project.
- **Keep the graph current.** Run `graphify update .` after `git pull` and after large
  changes. An old graph gives the assistant incorrect answers.
- **Install git hooks on the host, not from this container.** `graphify hook install`
  writes the path of the container's Python into `.git`. The hooks then fail on your
  computer. In a container workflow, run `graphify update .` yourself or in CI.
- **Read `GRAPH_REPORT.md` before you query.** The most connected nodes show the
  main parts of the system. The unexpected connections often show coupling problems.
- **Use exact names in scripts.** `graphify explain` and `graphify path` do not accept an
  ambiguous name. They exit with code 3 and list the candidates.
- **Protect the HTTP server.** Start mcpo with `--api-key` and `--strict-auth`. Publish
  the port on `127.0.0.1` only. Keep the key file out of git. Any person with the key can
  read the graph. The graph contains names and paths from your code.
- **Skip the HTML view for large graphs.** In CI, or if the graph has more than about 5000
  nodes, add `--no-viz` to `cluster-only`.
- **Use a fixed image in CI.** The `latest` tag changes. If a CI job must give the same
  result every time, pin a digest, such as `stden/graphify@sha256:...`.

## Source and checks

The smoke test runs the tutorial steps on Python, JavaScript, and SQL files without
a language model. It checks the ignore file, the report, the `query`, `explain`, and
`path` commands, `update`, and SVG export. It also checks the installed extras, the MCP
server, and mcpo with its API key.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/graphify/Dockerfile)
- [Smoke test](https://github.com/stden/docker-gems/blob/main/graphify/smoke-test.sh)
- [Kubernetes manifests](https://github.com/stden/docker-gems/tree/main/graphify/kubernetes)
- [Overview source](https://github.com/stden/docker-gems/blob/main/graphify/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
