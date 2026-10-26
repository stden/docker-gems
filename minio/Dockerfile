# Run an S3-compatible MinIO object store with the MinIO client.
FROM minio/mc:latest AS mc-binary

FROM minio/minio:latest

# Copy the MinIO client from the mc image.
COPY --from=mc-binary /usr/bin/mc /usr/local/bin/mc

RUN minio --version && mc --version

# Object API on 9000, web console on 9001.
EXPOSE 9000 9001
