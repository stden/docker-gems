#!/usr/bin/env bash
# Build a minimal Android app in Kotlin and Java with the newest stable Android Gradle Plugin.
# Run its JVM unit test and lint. Then check the APK. The build downloads AGP and the
# dependencies from Google Maven and Maven Central. No Gradle or Kotlin daemon stays alive,
# because PRoot in GitLab CI waits for every child process.
set -euo pipefail

AGP_VERSION=9.4.1
KOTLIN_VERSION=2.4.21
PACKAGE=org.example.smoke

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
# Keep the Gradle cache and the debug keystore in the temporary directory.
export GRADLE_USER_HOME="$work/gradle-home" ANDROID_USER_HOME="$work/android-home"

java -version
gradle --version
sdkmanager --version
aapt2 version
apksigner --version
adb version

# Print the java and aapt2 processes that are still alive.
build_processes() {
    local proc
    for proc in /proc/[0-9]*; do
        case "$(cat "$proc/comm" 2>/dev/null)" in
            java | aapt2) printf '%s %s\n' "${proc#/proc/}" "$(tr '\0' ' ' < "$proc/cmdline")" ;;
        esac
    done
}

sdk_packages() {
    find "$ANDROID_HOME" -mindepth 2 -maxdepth 2 -type d | sort
}

sdk_before=$(sdk_packages)

cat > settings.gradle.kts <<'KTS'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "smoke"
KTS

cat > build.gradle.kts <<KTS
// AGP 9 compiles Kotlin itself. A newer Kotlin Gradle plugin on the classpath
// replaces the version that AGP brings.
buildscript {
    repositories { mavenCentral() }
    dependencies { classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$KOTLIN_VERSION") }
}

plugins {
    id("com.android.application") version "$AGP_VERSION"
}

android {
    namespace = "$PACKAGE"
    // The newest stable SDK platform: android-37.2.
    compileSdk = 37
    compileSdkMinor = 2
    defaultConfig {
        applicationId = "$PACKAGE"
        minSdk = 24
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"
    }
    // Java 17 bytecode. AGP then compiles the Java source with a JDK image of the SDK platform.
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    testImplementation("junit:junit:4.13.2")
}
KTS

cat > gradle.properties <<'PROPERTIES'
org.gradle.daemon=false
org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8
kotlin.compiler.execution.strategy=in-process
PROPERTIES

source_dir=src/main/kotlin/${PACKAGE//.//}
java_dir=src/main/java/${PACKAGE//.//}
test_dir=src/test/kotlin/${PACKAGE//.//}
mkdir -p "$source_dir" "$java_dir" "$test_dir"

cat > src/main/AndroidManifest.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="Smoke test">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
XML

cat > "$source_dir/MainActivity.kt" <<KOTLIN
package $PACKAGE

import android.app.Activity
import android.os.Bundle
import android.widget.TextView

object Greeting {
    fun text(name: String): String = Names.hello(name)
}

class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(TextView(this).apply { text = Greeting.text("Android") })
    }
}
KOTLIN

cat > "$java_dir/Names.java" <<JAVA
package $PACKAGE;

public final class Names {
    private Names() {
    }

    public static String hello(String name) {
        return "Hello, " + name + "!";
    }
}
JAVA

cat > "$test_dir/GreetingTest.kt" <<KOTLIN
package $PACKAGE

import org.junit.Assert.assertEquals
import org.junit.Test

class GreetingTest {
    @Test
    fun greetsByName() {
        assertEquals("Hello, Android!", Greeting.text("Android"))
    }
}
KOTLIN

gradle --no-daemon --console=plain buildEnvironment assembleDebug testDebugUnitTest lintDebug \
    | tee gradle.log
# The build classpath uses the requested plugin versions, not the versions that AGP brings.
grep -Fx "+--- org.jetbrains.kotlin:kotlin-gradle-plugin:$KOTLIN_VERSION" gradle.log
grep -Fx "+--- com.android.application:com.android.application.gradle.plugin:$AGP_VERSION" gradle.log

apk=build/outputs/apk/debug/smoke-debug.apk
test -s "$apk"
aapt2 dump badging "$apk" > badging.txt
grep -F "package: name='$PACKAGE'" badging.txt
grep -F "launchable-activity: name='$PACKAGE.MainActivity'" badging.txt
apksigner verify --print-certs "$apk" | grep -F 'CN=Android Debug'
grep -F 'tests="1"' build/test-results/testDebugUnitTest/TEST-"$PACKAGE".GreetingTest.xml
grep -F 'failures="0"' build/test-results/testDebugUnitTest/TEST-"$PACKAGE".GreetingTest.xml
test -s build/reports/lint-results-debug.html
# javac compiled the Java source. The unit test calls it through the Kotlin code.
[[ -n "$(find build/intermediates -name Names.class)" ]]

if [[ "$(sdk_packages)" != "$sdk_before" ]]; then
    echo "The build installed SDK packages that the image does not have:" >&2
    diff <(echo "$sdk_before") <(sdk_packages) >&2 || true
    exit 1
fi

# A daemon that stays alive stops the GitLab job. Give the build processes time to exit.
for _attempt in {1..50}; do
    [[ -z "$(build_processes)" ]] && break
    sleep 0.2
done
if [[ -n "$(build_processes)" ]]; then
    echo "Build processes are still alive:" >&2
    build_processes >&2
    exit 1
fi

echo "Android build, unit test, lint, APK, and daemon checks passed."
