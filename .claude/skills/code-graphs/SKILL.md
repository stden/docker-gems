---
name: code-graphs
description: >-
  Use to get a map of an unfamiliar codebase, or to find the callers or the
  impact of a function. Also use to find the tests that a change affects. For these tasks, use it
  only if the stden/graphify or stden/codegraph image can answer faster than you
  can read the files. Also use when the user asks how to use Graphify or
  CodeGraph from Docker. The tools run offline for code, and an API key is not
  necessary.
---

# Query a code graph with Graphify or CodeGraph

Both images read the project from `/workspace`. Run them as your user, so that the
output files belong to you. Both tools work offline for code. Write the full command in
each shell call. An agent shell does not keep aliases or functions between calls.

| Question | Use |
| --- | --- |
| What are the main parts of the system and how do they connect? | Graphify: `GRAPH_REPORT.md` |
| How does a concept flow through code and documents? | Graphify: `query`, `path` |
| Who calls this function? What does it call? | CodeGraph: `callers`, `callees` |
| What breaks if I change this symbol? | CodeGraph: `impact` |
| Which tests must run for this change? | CodeGraph: `affected` |

## Graphify

Run the commands from the project root:

```sh
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/workspace stden/graphify:latest \
  bash -c 'graphify extract . --code-only && graphify cluster-only . --no-label'
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/workspace stden/graphify:latest \
  graphify query "How does login work?"
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/workspace stden/graphify:latest \
  graphify path Router Database
```

Read `graphify-out/GRAPH_REPORT.md` first. `graphify explain <name>` shows one node and its
connections. After a code change, run `graphify update .`. Then run
`graphify cluster-only . --no-label`.

Exit code 3 means an ambiguous name. In that case, use the full label from the output.
Exit code 4 means no match.

## CodeGraph

Run the commands from the project root:

```sh
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/workspace stden/codegraph:latest \
  codegraph init .
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/workspace stden/codegraph:latest \
  codegraph callers formatName
git diff --name-only HEAD | docker run --rm -i --user "$(id -u):$(id -g)" \
  -v "$PWD":/workspace stden/codegraph:latest codegraph affected --stdin
```

`codegraph impact <symbol>` lists the code that depends on a symbol. After a code change,
run `codegraph sync .`. If a script reads the output, add `--json`.

## Rules

- Do not commit `graphify-out/` or `.codegraph/` unless the project already does so.
  CodeGraph writes its own `.gitignore` in `.codegraph/`.
- Keep `--code-only` unless the user agrees to send documents to a language model
  provider. Without that option and with an API key set, Graphify sends documents,
  papers, and images to the provider of that key.
- Do not run `graphify hook install` from the container. The hooks store the path of the
  container's Python and fail on the host.
- Before you trust a missing edge, check the source file. A graph can be out of date.
- To give the tools to Open WebUI or another HTTP client, use mcpo from the same image.
  The tutorials show the command, the API key, and the Open WebUI settings.
- The full tutorials are in `graphify/README.md` and `codegraph/README.md`.
