# Capture and inspect email with Mailpit in a development environment.
FROM axllent/mailpit:latest

ENV MP_DISABLE_VERSION_CHECK=true

RUN /mailpit version --no-release-check

# SMTP on 1025, REST API and web UI on 8025.
EXPOSE 1025 8025
