# Run browser UI tests for Java projects with JDK 27, Gradle, and Google Chrome.
FROM eclipse-temurin:27-jdk-resolute

# Pin the Gradle version to verify the archive with SHA-256.
ARG GRADLE_VERSION=9.8.2
ARG GRADLE_SHA256=21bd5da2de49b642904077f38c0efdc7778e92b3ed0889392dca61b97e389607

ENV GRADLE_HOME=/opt/gradle
ENV GRADLE_USER_HOME=/home/tester/.gradle
ENV PATH="${GRADLE_HOME}/bin:${PATH}"

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       gnupg \
       unzip \
    && curl --fail --location --show-error \
       "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
       --output /tmp/gradle.zip \
    && echo "${GRADLE_SHA256}  /tmp/gradle.zip" | sha256sum --check - \
    && unzip -q /tmp/gradle.zip -d /opt \
    && mv "/opt/gradle-${GRADLE_VERSION}" "${GRADLE_HOME}" \
    && rm /tmp/gradle.zip \
    && rm -rf /var/lib/apt/lists/*

# Install stable Google Chrome from the signed Google repository.
RUN curl --fail --silent --show-error \
       --output /tmp/linux_signing_key.pub \
       https://dl.google.com/linux/linux_signing_key.pub \
    && gpg --dearmor \
       < /tmp/linux_signing_key.pub \
       > /usr/share/keyrings/google-chrome.gpg \
    && rm /tmp/linux_signing_key.pub \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
       > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install git, Python 3, and libatomic1 for the UI test tools.
RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 python3-venv libatomic1 \
    && rm -rf /var/lib/apt/lists/*

# Run tests as a non-root user. Mount the project at /workspace.
RUN useradd \
      --create-home \
      --shell /bin/bash \
      tester \
    && mkdir -p /workspace "${GRADLE_USER_HOME}" \
    && chown -R tester:tester /workspace /home/tester

USER tester
WORKDIR /workspace

RUN java --version \
    && gradle --version \
    && google-chrome --version \
    && git --version \
    && python3 --version \
    && python3 -c 'import venv, ctypes; ctypes.CDLL("libatomic.so.1")'

CMD ["bash"]
