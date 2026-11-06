# Build and test Java 17 projects with Maven 3.9 and common CI utilities.
FROM maven:3.9-eclipse-temurin-17-alpine

# Clear the default entry point to allow both java and mvn commands.
ENTRYPOINT []
WORKDIR /workspace

RUN apk add --no-cache \
    bash \
    curl \
    fontconfig \
    git \
    jq \
    openssh-client \
    sshpass \
    ttf-dejavu \
    tzdata

RUN java -version && mvn -version && git --version && curl --version && jq --version

CMD ["bash"]
