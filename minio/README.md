# stden/minio

Run an S3-compatible MinIO object store with the MinIO client.

## Contents

- MinIO object store on port 9000
- MinIO web console on port 9001
- MinIO client (`mc`) for bucket and object operations
- Demo credentials: `minioadmin` / `minioadmin` (MinIO default — change for any real deployment)

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful `main` build | `linux/amd64` |

[View tags and image digests](https://hub.docker.com/r/stden/minio/tags).

## Pull and run

```sh
docker pull stden/minio:latest
docker run -d -p 127.0.0.1:9000:9000 -p 127.0.0.1:9001:9001 \
  --name minio stden/minio:latest
```

Open the web console at `http://127.0.0.1:9001` (minioadmin:minioadmin).

Create a bucket and upload a file:

```sh
docker exec minio mc alias set local http://localhost:9000 minioadmin minioadmin
docker exec minio mc mb local/my-bucket
echo "hello" | docker exec -i minio mc pipe local/my-bucket/hello.txt
docker exec minio mc ls local/my-bucket
```

## Checks and source

CI builds the image and verifies the MinIO and mc versions.
The local test starts MinIO, creates a bucket, uploads a file, and lists it.

The build compiles the official server and client sources with the current Go release.
The runtime uses `alpine:latest` and the current CA bundle.
The image contains no Go compiler or source cache.

Upstream distributes the community server as source code only.
Both upstream repositories are archived. Use this course image for local tests.
Review the security scan before any deployment.

[MinIO source instructions](https://github.com/minio/minio#source-only-distribution) ·
[MinIO client source](https://github.com/minio/mc)

[Dockerfile](https://github.com/stden/docker-gems/blob/main/minio/Dockerfile) ·
[Docker tutorial](https://github.com/stden/docker-gems/blob/main/README.md) ·
[Build results](https://github.com/stden/docker-gems/actions)
