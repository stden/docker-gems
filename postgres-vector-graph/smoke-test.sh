#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
    echo "Run this test as the postgres user." >&2
    exit 1
fi

work_dir=$(mktemp -d)
data_dir="$work_dir/data"
socket_dir="$work_dir/socket"
cleanup() {
    local status=$?
    if [ "$status" -ne 0 ] && [ -f "$work_dir/postgres.log" ]; then
        cat "$work_dir/postgres.log" >&2
    fi
    if [ -f "$data_dir/postmaster.pid" ]; then
        if ! pg_ctl -D "$data_dir" -m immediate -t 60 -w stop; then
            echo "Failed to stop the temporary database at $data_dir." >&2
            exit 1
        fi
    fi
    rm -rf "$work_dir"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir "$socket_dir"

# Use a private cluster and socket. Never use the container's PGDATA.
unset PGHOSTADDR PGSERVICE PGSERVICEFILE PGOPTIONS
initdb -D "$data_dir" -U postgres --auth=trust --no-locale --encoding=UTF8
pg_ctl -D "$data_dir" -l "$work_dir/postgres.log" \
    -o "-c listen_addresses='' -c unix_socket_directories='$socket_dir'" -t 60 -w start
psql --host "$socket_dir" --port 5432 --username postgres --dbname postgres \
    --no-psqlrc --set ON_ERROR_STOP=1 <<'SQL'
CREATE EXTENSION vector;
CREATE EXTENSION age;
CREATE EXTENSION pg_trgm;
CREATE EXTENSION btree_gin;
CREATE EXTENSION "uuid-ossp";
SELECT extname, extversion FROM pg_extension ORDER BY extname;
SELECT 1 / CASE WHEN '[1,2,3]'::vector <-> '[1,2,4]'::vector = 1
    THEN 1 ELSE 0 END AS vector_distance_check;
LOAD 'age';
SET search_path = ag_catalog, public;
SELECT create_graph('smoke');
SELECT * FROM cypher('smoke', $$ CREATE (:Probe {value: 42}) $$) AS (result agtype);
SELECT 1 / CASE WHEN (
    SELECT result::text FROM cypher('smoke', $$ MATCH (n:Probe) RETURN n.value $$)
        AS (result agtype)
) = '42' THEN 1 ELSE 0 END AS cypher_result_check;
SQL
pg_ctl -D "$data_dir" -m fast -t 60 -w stop
echo "PostgreSQL vector and graph checks passed."
