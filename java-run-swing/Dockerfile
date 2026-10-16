# Run Swing applications without a monitor with Alpine, OpenJDK 25 (LTS), and a virtual X server.
FROM alpine:latest
# Install fonts to prevent the "Fontconfig head is null" error in Swing.
RUN apk add --no-cache openjdk25 xvfb-run font-dejavu tini
WORKDIR /app
# Use tini as PID 1, so that xvfb-run does not hang.
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/sh"]
