# stden/postgres-vector-graph

Store relational data, vectors, and graphs in PostgreSQL 18 with pgvector and Apache AGE.

## Contents

- PostgreSQL 18 with the official image entrypoint
- pgvector 0.8.7 for vector search
- Apache AGE 1.8.0 for graph queries with Cypher
- PostgreSQL extensions such as `pg_trgm`, `btree_gin`, and `uuid-ossp`

Create each extension in the database where you use it. PostgreSQL starts with its normal
`postgres` command. The image keeps the official PostgreSQL initialization behavior.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful `main` build | `linux/amd64` |

[View tags and image digests](https://hub.docker.com/r/stden/postgres-vector-graph/tags).

## Pull and run

`change-me` is a placeholder password. Replace it before you use the database.
PostgreSQL 18 stores data under `/var/lib/postgresql`. Mount the volume at that path.

```sh
docker pull stden/postgres-vector-graph:latest
docker run -d --name docker-gems-graph \
  -p 127.0.0.1:5432:5432 \
  -e POSTGRES_PASSWORD=change-me \
  -v docker-gems-graph-data:/var/lib/postgresql \
  stden/postgres-vector-graph:latest
```

Wait for the server to accept TCP connections. During the initialization, a temporary server
accepts only socket connections. Run this check in Bash:

```bash
(
  for attempt in {1..60}; do
    if docker exec docker-gems-graph pg_isready -h 127.0.0.1 -U postgres; then
      exit 0
    fi
    sleep 2
  done
  docker logs docker-gems-graph
  echo "PostgreSQL did not become ready." >&2
  exit 1
)
```

Continue only when the readiness check succeeds. Enable the extensions and run the sample queries:

```sh
docker exec -i docker-gems-graph psql -U postgres -d postgres \
  --no-psqlrc --set ON_ERROR_STOP=1 <<'SQL'
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS age;
SELECT '[1,2,3]'::vector <-> '[1,2,4]'::vector AS distance;
LOAD 'age';
SET search_path = ag_catalog, public;
SELECT create_graph('demo');
SELECT * FROM cypher('demo', $$ CREATE (:Item {name: 'Docker'}) $$) AS (result agtype);
SELECT * FROM cypher('demo', $$ MATCH (n:Item) RETURN n.name $$) AS (name agtype);
SQL
```

Run `create_graph('demo')` only once in each database. For later Cypher sessions, run
`LOAD 'age'`. Then set the search path again. Use `docker stop docker-gems-graph` to stop the
container. The named volume keeps the data.

## Checks and source

CI starts a temporary cluster as the `postgres` user. It checks that the extensions load.
It also checks the vector distance and the Cypher results. The test never connects to an
existing database.

[Dockerfile](https://github.com/stden/docker-gems/blob/main/postgres-vector-graph/Dockerfile) ·
[Smoke test](https://github.com/stden/docker-gems/blob/main/postgres-vector-graph/smoke-test.sh) ·
[Docker tutorial](https://github.com/stden/docker-gems/blob/main/README.md) ·
[Build results](https://github.com/stden/docker-gems/actions)
