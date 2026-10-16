# stden/android

Build and test Android apps in CI with JDK 25, the Android SDK, and Gradle.

## Overview

In CI or on your computer, this image builds Android apps and runs their JVM unit tests and
lint. It contains:

- Eclipse Temurin JDK 25. The current stable Android Gradle Plugin (AGP 9.4) works only
  with JDK 17 or later.
- The Android SDK command-line tools 22.0: `sdkmanager`, `avdmanager`, `apkanalyzer`, `lint`,
  `d8`, `r8`, `retrace`, `profgen`, `resourceshrinker`, `screenshot2`, and the `android`
  command. The build downloads them from the
  [official download page](https://developer.android.com/studio#command-line-tools-only)
  and checks them with the SHA-256 that the page lists.
- The newest stable Platform-tools with `adb`.
- Build-tools 37.0.0, the newest stable release. `aapt2`, `apksigner`, and `zipalign` are
  on the `PATH`. The image also has Build-tools 36.0.0, because AGP 9.4 uses it by default.
- The SDK platforms `android-34`, `android-35`, `android-36`, `android-37.0`, and `android-37.2`.
- Gradle 9.8.2 for projects without a wrapper, checked with its SHA-256.
- git, curl, and unzip.

The image accepts the Android SDK licenses during its build. Read the
[Android SDK terms](https://developer.android.com/studio/terms) before you use the image.
`ANDROID_HOME` and `ANDROID_SDK_ROOT` are `/opt/android-sdk`. The base image is
`eclipse-temurin:25-jdk`. The working directory is `/workspace`. The default command starts
Bash.

The image has no emulator and no system images, to keep it small. It cannot run
instrumented tests (`connectedAndroidTest`). Run them on a device farm, such as
[Firebase Test Lab](https://firebase.google.com/docs/test-lab), or on a runner with KVM.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful build from `main`. | `linux/amd64` |

[View all tags on Docker Hub](https://hub.docker.com/r/stden/android/tags).
The `latest` tag changes when a new build passes its tests.

## Pull the image

```sh
docker pull stden/android:latest
```

## Tutorial

Do these steps in the root directory of an Android project that has a Gradle wrapper
(`gradlew`). The commands mount the project at `/workspace`. A named volume keeps the
Gradle cache, so the next build does not download the dependencies again. The paths in
the examples are for the module `app`.

### Step 1: Create a cache volume

```sh
docker volume create android-gradle
```

### Step 2: Build the debug APK

```sh
docker run --rm -v "$PWD":/workspace -v android-gradle:/root/.gradle \
  stden/android:latest ./gradlew --no-daemon assembleDebug
```

The APK is `app/build/outputs/apk/debug/app-debug.apk`. The container runs as root, so on
Linux the `build` directories belong to root.

### Step 3: Run the unit tests

```sh
docker run --rm -v "$PWD":/workspace -v android-gradle:/root/.gradle \
  stden/android:latest ./gradlew --no-daemon testDebugUnitTest
```

The HTML report is `app/build/reports/tests/testDebugUnitTest/index.html`. CI servers read
the JUnit XML files in `app/build/test-results/testDebugUnitTest/`.

### Step 4: Run lint

```sh
docker run --rm -v "$PWD":/workspace -v android-gradle:/root/.gradle \
  stden/android:latest ./gradlew --no-daemon lintDebug
```

When lint finds an error, the build fails. The report is
`app/build/reports/lint-results-debug.html`. If the build must also fail on warnings, set
`warningsAsErrors = true` in the `lint` block of `app/build.gradle.kts`.

### Step 5: Check the APK

```sh
docker run --rm -v "$PWD":/workspace stden/android:latest bash -c '
  aapt2 dump badging app/build/outputs/apk/debug/app-debug.apk | head -n 3
  apksigner verify --print-certs app/build/outputs/apk/debug/app-debug.apk'
```

The first line shows the package name, the version, and the compile SDK. The build signs a
debug APK with the debug key, `CN=Android Debug`.

### Step 6: Add a wrapper to a project without one

The `gradle` command is Gradle 9.8.2. Create the wrapper once, with the checksum of the
distribution:

```sh
docker run --rm -v "$PWD":/workspace -v android-gradle:/root/.gradle \
  stden/android:latest gradle --no-daemon wrapper --gradle-version 9.8.2 \
  --gradle-distribution-sha256-sum 21bd5da2de49b642904077f38c0efdc7778e92b3ed0889392dca61b97e389607
```

Commit the files that the command writes.

### Step 7: Add SDK packages

If an SDK platform is not in the image, AGP downloads it during the build. A new CI
container downloads it again each time. In a child image, install the packages that your
projects use:

```dockerfile
FROM stden/android:latest
RUN sdkmanager "platforms;android-33" "ndk;28.2.13676358"
```

`sdkmanager` prints a warning that the new Android CLI (`android sdk`) replaces it. It
still works. The `android` command downloads the Android CLI at its first start. The CLI
sends usage data if you do not add `--no-metrics`.

## Use the image in CI

### GitHub Actions

Java in the container uses `/root` as the home directory, but GitHub Actions sets `HOME`
to `/github/home`. Set `GRADLE_USER_HOME`, so that Gradle and the cache step use the same
directory.

```yaml
jobs:
  android:
    runs-on: ubuntu-latest
    container: stden/android:latest
    env:
      GRADLE_USER_HOME: /root/.gradle
    steps:
      - uses: actions/checkout@v7
      - uses: gradle/actions/wrapper-validation@v6
      - uses: actions/cache@v6
        with:
          path: |
            /root/.gradle/caches
            /root/.gradle/wrapper
          key: gradle-${{ hashFiles('gradle/wrapper/gradle-wrapper.properties', '**/*.gradle.kts', 'gradle/libs.versions.toml') }}
          restore-keys: gradle-
      - run: ./gradlew --no-daemon assembleDebug testDebugUnitTest lintDebug
      - uses: actions/upload-artifact@v7
        if: always()
        with:
          name: android-build
          path: |
            app/build/outputs/apk/debug/
            app/build/reports/
```

### GitLab CI

GitLab caches only paths in the project directory, so the Gradle user home is there.

```yaml
android:
  image: stden/android:latest
  variables:
    GRADLE_USER_HOME: $CI_PROJECT_DIR/.gradle-home
  cache:
    key:
      files:
        - gradle/wrapper/gradle-wrapper.properties
        - gradle/libs.versions.toml
    paths:
      - .gradle-home/caches/
      - .gradle-home/wrapper/
  script:
    - ./gradlew --no-daemon assembleDebug testDebugUnitTest lintDebug
  artifacts:
    when: always
    paths:
      - app/build/outputs/apk/debug/
      - app/build/reports/
    reports:
      junit: app/build/test-results/testDebugUnitTest/TEST-*.xml
```

## Best practices

- **Use the Gradle wrapper of the project and pin its checksum.** The wrapper gives each
  developer and each CI job the same Gradle version. Set `distributionSha256Sum` in
  `gradle/wrapper/gradle-wrapper.properties` (Step 6 does this), so that the wrapper does
  not accept a changed download. The checksums are on
  [gradle.org](https://gradle.org/release-checksums/). Check the wrapper JAR in CI with
  `gradle/actions/wrapper-validation`.
- **Cache the dependencies.** Cache `caches/` and `wrapper/` of the Gradle user home
  between jobs. Use the wrapper properties and the version catalog in the cache key.
- **Do not start a daemon in CI.** A CI job runs one build, so a daemon only uses memory.
  Also, a runner that waits for all child processes can wait for the daemon. Use
  `--no-daemon`. Set these properties in `gradle.properties`:

  ```properties
  org.gradle.daemon=false
  org.gradle.jvmargs=-Xmx3g -Dfile.encoding=UTF-8
  kotlin.compiler.execution.strategy=in-process
  ```

  `in-process` runs the Kotlin compiler in the Gradle process, not in a Kotlin daemon. Set
  the heap so that it fits in the memory of the runner.
- **Keep signing keys in the CI secret store, never in the image or in git.** Every user
  of an image can read a keystore in it. Store the release keystore as a base64 secret and
  its passwords as masked secrets.

  In the job, write the keystore to a temporary file. Give its path in `ANDROID_KEYSTORE`.
  Delete the file after the build. Read the values from the environment in
  `app/build.gradle.kts`:

  ```kotlin
  android {
      signingConfigs {
          create("release") {
              storeFile = System.getenv("ANDROID_KEYSTORE")?.let { file(it) }
              storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
              keyAlias = System.getenv("ANDROID_KEY_ALIAS")
              keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
          }
      }
      buildTypes {
          release {
              signingConfig = signingConfigs.getByName("release")
          }
      }
  }
  ```

- **Install SDK packages in an image, not in each job.** A package that AGP downloads
  during the build costs time in every new container (Step 7).
- **Use a fixed image for releases.** The `latest` tag changes. If a release build must be
  repeatable, pin a digest, such as `stden/android@sha256:...`.

## Source and checks

The smoke test writes a small app in Kotlin and Java for the SDK platform `android-37.2`.
It uses the newest stable AGP (9.4.1) and Kotlin Gradle plugin (2.4.21). It runs `assembleDebug`, `testDebugUnitTest`, and `lintDebug` with
`--no-daemon`, and checks the plugin versions on the build classpath. Then it checks the
package name and the launcher activity with `aapt2 dump badging`, the debug signature with
`apksigner`, and the unit test result. It also checks that the build installed no SDK
package and that no Java or aapt2 process is still alive.

- [Dockerfile](https://github.com/stden/docker-gems/blob/main/android/Dockerfile)
- [Smoke test](https://github.com/stden/docker-gems/blob/main/android/smoke-test.sh)
- [Overview source](https://github.com/stden/docker-gems/blob/main/android/README.md)
- [Repository and Docker tutorial](https://github.com/stden/docker-gems)
