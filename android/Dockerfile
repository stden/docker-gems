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
# The command-line tools 22.0 contain Bouncy Castle 1.79 with known vulnerabilities.
# Replace it with the newest release for the lint, apkanalyzer, and resourceshrinker
# launchers. The checksums are from Maven Central (<artifact>-<version>.jar.sha256).
ARG BC_OLD_VERSION=1.79
ARG BC_VERSION=1.86
ARG BCPROV_SHA256=2af190b300cbb0b35e248ccf5f4a06b6072030aeb3da7a98ec73abe5b4cb371f
ARG BCPKIX_SHA256=8d8b41a4b149bdae8d331f059a578870954d1e3ff29f8269a9eb3ee19a7e4ef7
ARG BCUTIL_SHA256=1c268e15f785aafb1e4670d8d6e5f856f69475e96c162dadcd1ff9b350e9139f

ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    GRADLE_HOME=/opt/gradle
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/${BUILD_TOOLS_VERSION}:${GRADLE_HOME}/bin:${PATH}"

# Install the security updates of the base image and the download tools. The official
# image can be days behind the security repository of Ubuntu.
RUN test "$(dpkg --print-architecture)" = amd64 \
 && apt-get update \
 && apt-get upgrade -y \
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

# Replace the Bouncy Castle jars of the command-line tools. The lint, apkanalyzer, and
# resourceshrinker launchers read their class path from the manifest of
# lib/<launcher>-classpath.jar, which names the path of each jar.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN set -eux; \
    lib="${ANDROID_HOME}/cmdline-tools/latest/lib"; \
    for artifact in bcprov bcpkix bcutil; do \
      curl -fsSLo "/tmp/${artifact}.jar" \
        "https://repo1.maven.org/maven2/org/bouncycastle/${artifact}-jdk18on/${BC_VERSION}/${artifact}-jdk18on-${BC_VERSION}.jar"; \
    done; \
    printf '%s  /tmp/bcprov.jar\n%s  /tmp/bcpkix.jar\n%s  /tmp/bcutil.jar\n' \
      "${BCPROV_SHA256}" "${BCPKIX_SHA256}" "${BCUTIL_SHA256}" | sha256sum --check; \
    for artifact in bcprov bcpkix bcutil; do \
      rm -r "${lib}/external/org/bouncycastle/${artifact}-jdk18on/${BC_OLD_VERSION}"; \
      mkdir "${lib}/external/org/bouncycastle/${artifact}-jdk18on/${BC_VERSION}"; \
      mv "/tmp/${artifact}.jar" \
        "${lib}/external/org/bouncycastle/${artifact}-jdk18on/${BC_VERSION}/${artifact}-jdk18on-${BC_VERSION}.jar"; \
    done; \
    for launcher in apkanalyzer lint resourceshrinker; do \
      unzip -p "${lib}/${launcher}-classpath.jar" META-INF/MANIFEST.MF \
        | sed "s#\(bc[a-z]*-jdk18on\)/${BC_OLD_VERSION}/\(bc[a-z]*-jdk18on\)-${BC_OLD_VERSION}\.jar#\1/${BC_VERSION}/\2-${BC_VERSION}.jar#g" \
        > /tmp/MANIFEST.MF; \
      test "$(grep -c "jdk18on-${BC_VERSION}.jar" /tmp/MANIFEST.MF)" = 3; \
      jar --update --file "${lib}/${launcher}-classpath.jar" --manifest /tmp/MANIFEST.MF; \
    done; \
    rm /tmp/MANIFEST.MF

RUN java -version \
 && GRADLE_USER_HOME=/tmp/gradle-version gradle --version \
 && rm -rf /tmp/gradle-version \
 && sdkmanager --version \
 && sdkmanager --list_installed \
 && lint --version \
 && aapt2 version \
 && apksigner --version \
 && adb version \
 && rm -rf /root/.android /root/.java

WORKDIR /workspace
CMD ["bash"]
