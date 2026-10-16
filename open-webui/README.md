# stden/open-webui

Run Open WebUI, a self-hosted chat interface for Ollama and OpenAI-compatible APIs.

## Overview

This image is the official [Open WebUI](https://github.com/open-webui/open-webui)
image `ghcr.io/open-webui/open-webui:latest`. The Dockerfile uses it without changes.
Each build pulls the newest release, runs the smoke test, and publishes the tested image.

Open WebUI gives a web chat for local models in Ollama and for OpenAI-compatible
APIs. It also has user accounts, document search (RAG), and tool servers. The image
includes the default embedding models, so document search works without a download.

The server listens on port `8080`. Its data is in `/app/backend/data`. The upstream
health check calls `/health`.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main` with the newest Open WebUI release. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/open-webui/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/open-webui:latest
```

## Tutorial

### Step 1: Start the server

Create a secret key once. Keep it. Open WebUI signs the login sessions with it.

```sh
openssl rand -hex 32 > webui-secret.key
docker run -d --name open-webui --restart unless-stopped \
  -p 127.0.0.1:3000:8080 \
  -e WEBUI_SECRET_KEY="$(cat webui-secret.key)" \
  -v open-webui:/app/backend/data \
  stden/open-webui:latest
```

Wait until the server is ready. The first start can take a minute.

```sh
until curl -fsS http://127.0.0.1:3000/health; do sleep 2; done
```

### Step 2: Create the administrator account

Open <http://127.0.0.1:3000>. Then sign up. The first account becomes the
administrator. Do this immediately after the first start.

### Step 3: Connect a model

To use Ollama on the same computer, start the container with these options:

```sh
--add-host=host.docker.internal:host-gateway \
-e OLLAMA_BASE_URL=http://host.docker.internal:11434
```

To use an OpenAI-compatible API, add `-e OPENAI_API_KEY`. For a provider other than
OpenAI, set `OPENAI_API_BASE_URL`. You can also add connections later in the admin
settings.

### Step 4: Update to a new release

The data stays in the `open-webui` volume. Use the same secret key.

```sh
docker pull stden/open-webui:latest
docker rm -f open-webui
# Run the command from step 1 again.
```

### Step 5: Make a backup of the data

```sh
docker run --rm -v open-webui:/data:ro -v "$PWD":/backup alpine \
  tar czf /backup/open-webui-backup.tgz -C /data .
```

## Best practices

- **Set `WEBUI_SECRET_KEY`.** Without it, the container makes a key outside the data
  volume. A new container then gets a new key, and all users must sign in again.
- **Use a named volume for `/app/backend/data`.** Docker copies the bundled embedding
  models into a new named volume. A bind mount hides them, and the server must then
  download the models.
- **Create the administrator first.** The first account to sign up gets full access.
  After that, disable new sign-ups in the admin settings, or approve each new user.
- **Do not expose the port directly.** Bind the port to `127.0.0.1`, as in the tutorial.
  For access from other computers, use a reverse proxy with HTTPS.
- **Pass API keys from the environment.** Use `-e OPENAI_API_KEY` without a value.
  Do not write a key in a Dockerfile, a script in git, or a shell history.
- **Make a backup before you update.** A new release can migrate the database. Keep
  the backup until the new release works.
- **Use a fixed image in production.** The `latest` tag changes. Pin a digest, such
  as `stden/open-webui@sha256:...`. Update the digest when you are ready.

## Run on Kubernetes

The repository has manifests in
[open-webui/kubernetes](https://github.com/stden/docker-gems/tree/main/open-webui/kubernetes).
They create the `open-webui` namespace with the restricted Pod Security level. They also create
a 10 GiB volume, a Deployment with one replica, and a Service on port 80. The pod keeps the data
at `/data` (`DATA_DIR=/data`), because Kubernetes does not copy the embedding models into a
volume at `/app/backend/data`. The manifest sets `ENABLE_OLLAMA_API=false`. Add a model
connection in the admin settings.

Create the secret key first. Then apply the manifests and wait for the pod:

```sh
kubectl apply -f open-webui/kubernetes/namespace.yaml
kubectl -n open-webui create secret generic open-webui \
  --from-literal=WEBUI_SECRET_KEY="$(openssl rand -hex 32)"
kubectl apply -k open-webui/kubernetes
kubectl -n open-webui rollout status deployment/open-webui --timeout=15m
kubectl -n open-webui port-forward service/open-webui 3000:80
```

The [AWS guide](https://github.com/stden/docker-gems/blob/main/aws/README.md) has the steps
for Amazon EKS.

## Source and checks

The smoke test starts the server with a temporary data directory and without a
model backend. It checks `/health`, the configuration, the web page, and the first
sign-up as administrator. It also checks an authenticated session, the models API,
and that a request without a token fails.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/open-webui/Dockerfile)
- [Smoke test](https://github.com/stden/docker-gems/blob/main/open-webui/smoke-test.sh)
- [Overview source](https://github.com/stden/docker-gems/blob/main/open-webui/README.md)
- [Upstream documentation](https://docs.openwebui.com)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
