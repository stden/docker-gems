# stden/codegraph

Index code into a CodeGraph SQLite graph and query symbols, callers, and impact from the CLI or MCP.

## Overview

This image contains [CodeGraph](https://github.com/colbymchenry/codegraph), the
`@colbymchenry/codegraph` package on npm. CodeGraph parses source code into a local
SQLite graph of symbols, calls, and imports. AI coding assistants use this graph over
MCP to find code with fewer tool calls and tokens.

- You can index code without an API key and without an external service.
- The index is in the `.codegraph/` directory of your project.
- The npm package installs a platform bundle with its own Node.js runtime.
  Node.js and npm from the base image are also available.
- The CodeGraph MCP server uses stdio only. [mcpo](https://github.com/open-webui/mcpo)
  publishes its tools as an OpenAPI HTTP server for Open WebUI and other HTTP clients.
- Anonymous usage statistics and the update check are off. Set
  `CODEGRAPH_TELEMETRY=1` to enable the statistics.

The base image is `node:latest`. The working directory is `/workspace`. The default
command starts Bash.

To run the tool server and the affected-tests Job on Kubernetes or Amazon EKS, use the
manifests in [codegraph/kubernetes](https://github.com/stden/docker-gems/tree/main/codegraph/kubernetes).
The [AWS guide](https://github.com/stden/docker-gems/blob/main/aws/README.md) gives the steps.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` with the newest CodeGraph release. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/codegraph/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/codegraph:latest
```

## Tutorial

Do these steps in your project directory. The commands mount the directory at
`/workspace` and run as your user, so the index files belong to you. Set a short
name for the command first:

```sh
alias codegraph='docker run --rm -i --user "$(id -u):$(id -g)" -v "$PWD":/workspace stden/codegraph:latest codegraph'
```

### Step 1: Index the project

```sh
codegraph init .
codegraph status .
```

`init` creates `.codegraph/` and builds the index. The directory has its own
`.gitignore`, so git does not see the database. `status` shows the number of files,
symbols, and edges for each language.

### Step 2: Query symbols and callers

```sh
codegraph query UserService
codegraph callers login
codegraph callees login
codegraph explore "login session"
```

`query` finds symbols by name. `callers` and `callees` follow the calls in each
direction. `explore` returns the source code and the call paths of the symbols that
match the query. Add `--json` to `query`, `callers`, `callees`, `impact`, or `affected` for
machine-readable output.

### Step 3: Check the impact of a change

```sh
codegraph impact login
codegraph affected src/auth.ts
```

`impact` lists the code that depends on a symbol. `affected` lists the test files
that depend on the changed files. This command runs `git` on your computer and sends
the changed file names to the container:

```sh
git diff --name-only HEAD | codegraph affected --stdin
```

### Step 4: Update the index after a change

```sh
codegraph sync .
```

`sync` reads only the changed files. Use `codegraph index . --force` to build the
index again from the start.

### Step 5: Connect an AI assistant over MCP

Add this server to the MCP configuration of your assistant. Replace `/path/to/project`
with the absolute path of your project.

```json
{
  "mcpServers": {
    "codegraph": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i", "-v", "/path/to/project:/workspace",
        "stden/codegraph:latest", "codegraph", "serve", "--mcp", "--path", "/workspace"
      ]
    }
  }
}
```

The server watches the project and updates the index when a file changes. If your
Docker host does not send file events to the container, add `--no-watch`. Then run
`codegraph sync .` after changes.

### Step 6: Serve the tools over HTTP with mcpo

mcpo starts the CodeGraph MCP server and publishes each tool as a `POST /<tool>`
endpoint. The API description is at `/openapi.json`, and the interactive documentation
is at `/docs`. With `--strict-auth`, every request must send the key as
`Authorization: Bearer <key>`. `CODEGRAPH_NO_DAEMON=1` keeps the MCP server in the
process tree of mcpo, so both stop at the same time.

```sh
openssl rand -hex 32 > mcpo-api.key
docker run -d --name codegraph-tools -p 127.0.0.1:8001:8000 --user "$(id -u):$(id -g)" \
  -e CODEGRAPH_NO_DAEMON=1 -v "$PWD":/workspace stden/codegraph:latest \
  mcpo --port 8000 --api-key "$(cat mcpo-api.key)" --strict-auth -- \
  codegraph serve --mcp --path /workspace --no-watch

curl -H "Authorization: Bearer $(cat mcpo-api.key)" -H 'Content-Type: application/json' \
  -d '{"query": "login session"}' http://127.0.0.1:8001/codegraph_explore
```

By default, the server has one tool: `codegraph_explore`. To add tools, set a list of
tools, for example `-e CODEGRAPH_MCP_TOOLS=explore,search,node,callers,callees,impact`. In
this mode, a project with fewer than 500 files gets only `explore`, `search`, and `node`.

To connect [Open WebUI](https://hub.docker.com/r/stden/open-webui), put both containers on
one Docker network. Run `docker network create ai-tools`. Then run
`docker network connect ai-tools open-webui` and
`docker network connect ai-tools codegraph-tools`.

In Open WebUI, open **Admin Panel → Settings → Integrations**. In the **Tools** section,
under **External Tool Servers**, select **Add Connection**. Then select the **OpenAPI**
type. Enter the URL `http://codegraph-tools:8000`, the path `openapi.json`, and the Bearer
key.

The Open WebUI server calls the tool server for this connection, so the container name
works. For a connection in the personal **Settings → Integrations**, your browser calls the
tool server, so the connection must use the URL `http://127.0.0.1:8001` instead.

### Step 7: Remove CodeGraph from the project

```sh
codegraph uninit --force .
```

This command deletes `.codegraph/`. Your source files do not change.

## Best practices

- **Index once, then sync.** `init` builds the full index. `sync` is fast because it
  reads only the changed files. Use `index . --force` after a large refactor or a
  branch switch with many changes.
- **Do not commit `.codegraph/`.** The database is local to each computer. Every
  developer and every CI job builds its own index.
- **Use `affected` to make CI faster.** Run the affected tests on each change first.
  Also run the full test suite on `main`, because `affected` sees only static
  dependencies. It does not see dynamic imports, reflection, or configuration files.
- **Check the impact before a refactor.** Run `codegraph impact <symbol>` before you
  rename or delete a symbol. Then review each caller in the list.
- **Run one writer for each project.** CodeGraph locks the index while it writes. If
  a stopped container leaves a stale lock, run `codegraph unlock .`.
- **Use `--json` in scripts.** The text output can change between releases.
- **Protect the HTTP server.** Start mcpo with `--api-key` and `--strict-auth`. Publish
  the port on `127.0.0.1` only. Keep the key file out of git. The tools return your source
  code to any person with the key.
- **Use a fixed image in CI.** The `latest` tag changes. If a CI job must give the same
  result every time, pin a digest, such as `stden/codegraph@sha256:...`.

## Source and checks

The smoke test runs the tutorial steps on TypeScript and Python files. It checks
`init`, `status`, `query`, `callers`, `callees`, `impact`, `affected`, `sync`, and
`uninit`. It also checks a `codegraph_explore` call to the MCP server, and the same tools
through mcpo with its API key.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/codegraph/Dockerfile)
- [Smoke test](https://github.com/stden/docker-gems/blob/main/codegraph/smoke-test.sh)
- [Kubernetes manifests](https://github.com/stden/docker-gems/tree/main/codegraph/kubernetes)
- [Overview source](https://github.com/stden/docker-gems/blob/main/codegraph/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
