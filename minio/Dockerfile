# Run an S3-compatible MinIO object store with the MinIO client.
FROM golang:latest AS build

ENV CGO_ENABLED=0 \
    GOTOOLCHAIN=local \
    GOMAXPROCS=8 \
    GOBIN=/out

RUN go version \
    && minio_version="$(go list -m -f '{{.Version}}' github.com/minio/minio@latest)" \
    && mc_version="$(go list -m -f '{{.Version}}' github.com/minio/mc@latest)" \
    && go install -p=8 -trimpath -ldflags="-s -w" "github.com/minio/minio@${minio_version}" \
    && go install -p=8 -trimpath -ldflags="-s -w" "github.com/minio/mc@${mc_version}" \
    && go version -m /out/minio /out/mc \
    && cp "/go/pkg/mod/github.com/minio/minio@${minio_version}/LICENSE" /out/LICENSE.minio \
    && cp "/go/pkg/mod/github.com/minio/mc@${mc_version}/LICENSE" /out/LICENSE.mc

FROM alpine:latest

RUN apk add --no-cache ca-certificates

COPY --from=build /out/minio /out/mc /usr/local/bin/
COPY --from=build /out/LICENSE.minio /out/LICENSE.mc /licenses/

ENV MINIO_UPDATE=off

RUN minio --version && mc --version

# Object API on 9000, web console on 9001.
EXPOSE 9000 9001

VOLUME ["/data"]

ENTRYPOINT ["minio"]
CMD ["server", "/data", "--console-address", ":9001"]
