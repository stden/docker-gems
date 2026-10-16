# Build and test Android apps in CI: JDK 25, the Android SDK command-line tools,
# platform-tools, build-tools, SDK platforms, and Gradle. The image has no emulator
# and no system images.
FROM eclipse-temurin:25-jdk

# The command-line tools from the official download page, with the SHA-256 that it lists:
# https://developer.android.com/studio#command-line-tools-only
ARG CMDLINE_TOOLS_BUILD=15859902
ARG CMDLINE_TOOLS_SHA256=4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583
# The newest stable Build-Tools, and the default Build-Tools of the newest stable
# Android Gradle Plugin. Without the default version, AGP downloads it in each build.
ARG BUILD_TOOLS_VERSION=37.0.0
ARG AGP_BUILD_TOOLS_VERSION=36.0.0
# Gradle for projects without a wrapper. The checksum is from services.gradle.org.
ARG GRADLE_VERSION=9.8.2
ARG GRADLE_SHA256=21bd5da2de49b642904077f38c0efdc7778e92b3ed0889392dca61b97e389607

ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    GRADLE_HOME=/opt/gradle
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/${BUILD_TOOLS_VERSION}:${GRADLE_HOME}/bin:${PATH}"

RUN test "$(dpkg --print-architecture)" = amd64 \
 && apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git unzip \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    cd /tmp; \
    curl -fsSLo gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"; \
    echo "${GRADLE_SHA256}  gradle.zip" | sha256sum --check; \
    unzip -q gradle.zip -d /opt; \
    mv "/opt/gradle-${GRADLE_VERSION}" "${GRADLE_HOME}"; \
    rm gradle.zip

# Do not install the package "cmdline-tools;latest" over this archive. In version 23.0,
# sdkmanager calls the new Android CLI, which downloads itself when it first starts.
# sdkmanager checks each SDK package against the checksum in the Google repository.
RUN set -eux; \
    cd /tmp; \
    curl -fsSLo cmdline-tools.zip \
      "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_BUILD}_latest.zip"; \
    echo "${CMDLINE_TOOLS_SHA256}  cmdline-tools.zip" | sha256sum --check; \
    mkdir -p "${ANDROID_HOME}/cmdline-tools"; \
    unzip -q cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools"; \
    mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest"; \
    rm cmdline-tools.zip; \
    yes | sdkmanager --licenses > /dev/null; \
    sdkmanager --install platform-tools \
      "build-tools;${BUILD_TOOLS_VERSION}" "build-tools;${AGP_BUILD_TOOLS_VERSION}" \
      "platforms;android-34" "platforms;android-35" "platforms;android-36" \
      "platforms;android-37.0" "platforms;android-37.2"; \
    rm -rf "${ANDROID_HOME}/.temp" /root/.android /root/.java

RUN java -version \
 && GRADLE_USER_HOME=/tmp/gradle-version gradle --version \
 && rm -rf /tmp/gradle-version \
 && sdkmanager --version \
 && sdkmanager --list_installed \
 && aapt2 version \
 && apksigner --version \
 && adb version \
 && rm -rf /root/.android /root/.java

WORKDIR /workspace
CMD ["bash"]
