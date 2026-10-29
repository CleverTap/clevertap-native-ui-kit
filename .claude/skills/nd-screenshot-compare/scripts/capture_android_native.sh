#!/usr/bin/env bash
# capture_android_native.sh <outDir>
# Runs android-sample's Compose events screenshot instrumentation test and copies the
# resulting PNGs into <outDir>. Produces composeEventsScreen_fireAllEvents_<event>.png.
#
# Requires espresso 3.7.0 + androidx.test 1.3.0 (pinned in libs.versions.toml) — older
# espresso crashes on API 36/37 with NoSuchMethodException: InputManager.getInstance.
# Recommend disabling emulator animations and letting it warm up first.
set -euo pipefail

OUT_DIR="${1:?usage: capture_android_native.sh <outDir>}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
SAMPLE="$REPO_ROOT/android-sample"
mkdir -p "$OUT_DIR"

TEST_CLASS="com.clevertap.android.nativeui.sample.automation.EventsScreenshotsTest#composeEventsScreen_fireAllEvents"

echo "== Running Compose events screenshot test =="
( cd "$SAMPLE" && \
  ./gradlew :app:automationScreenshots \
    -Pandroid.testInstrumentationRunnerArguments.class="$TEST_CLASS" )

ARTIFACT_ROOT="$SAMPLE/app/build/outputs/connected_android_test_additional_output/debugAndroidTest/connected"
echo "== Collecting PNGs from: $ARTIFACT_ROOT"
if [[ ! -d "$ARTIFACT_ROOT" ]]; then
  echo "  No artifact dir found. Did the test run on a connected device/emulator?" >&2
  exit 1
fi

# Artifacts live under connected/<AVD>/composeEventsScreen_fireAllEvents_<event>.png
count=0
while IFS= read -r -d '' f; do
  cp "$f" "$OUT_DIR/"
  count=$((count + 1))
done < <(find "$ARTIFACT_ROOT" -type f -name 'composeEventsScreen_fireAllEvents_*.png' -print0)

echo "== Copied $count native Android screenshot(s) into: $OUT_DIR"
