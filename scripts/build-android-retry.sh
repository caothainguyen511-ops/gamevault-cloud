#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT/engine/opennow-stable/android"
APK="$ANDROID_DIR/app/build/outputs/apk/debug/app-debug.apk"

if [[ ! -x "$ANDROID_DIR/gradlew" ]]; then
  echo "::error::Android Gradle wrapper is missing or not executable: $ANDROID_DIR/gradlew"
  exit 1
fi

cd "$ANDROID_DIR"
chmod +x ./gradlew
last_status=1
for attempt in 1 2 3; do
  echo "::group::GameVault Android build attempt $attempt/3"
  if ./gradlew --no-daemon --stacktrace assembleDebug; then
    echo "::endgroup::"
    last_status=0
    break
  else
    last_status=$?
    echo "::endgroup::"
    echo "::warning::Build attempt $attempt failed (exit $last_status). Retrying without deleting user data or project sources."
    if [[ "$attempt" -lt 3 ]]; then
      sleep_seconds=$((attempt * 10))
      sleep "$sleep_seconds"
    fi
  fi
done

if [[ "$last_status" -ne 0 ]]; then
  echo "::error::GameVault Android build failed after three attempts."
  exit "$last_status"
fi

if [[ ! -s "$APK" ]]; then
  echo "::error::Gradle reported success but the expected APK is missing or empty: $APK"
  exit 2
fi

echo "APK verified: $APK ($(stat -c%s "$APK") bytes)"
