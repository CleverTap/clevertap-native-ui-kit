#!/bin/bash
# run_automation_with_video.sh
# Runs the new iOS automation UITest suite with simulator video recording.
#
# XCUITest sandbox forbids the test target from launching `xcrun simctl io recordVideo`
# directly (Foundation.Process is unavailable). So we record at the simctl layer instead:
# this wrapper resolves the simulator's UDID, boots it if needed, starts
# `simctl io <UDID> recordVideo` per test class, invokes `xcodebuild test` against
# that same UDID, stops the recorder, and copies the MP4 + screenshots to
# ~/Desktop/nd-automation-output/ios/.
#
# Usage:
#   ./run_automation_with_video.sh                       # default device: iPhone 16
#   ./run_automation_with_video.sh "iPhone 15 Pro"       # explicit sim name
#
# Requirements:
#   - Xcode + iOS Simulator installed
#   - xcrun simctl available on PATH

set -uo pipefail

DEVICE="${1:-iPhone 16}"
SCHEME="NativeDisplaySample"
OUT_DIR="$HOME/Desktop/nd-automation-output/ios"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
RUN_DIR="$OUT_DIR/$TIMESTAMP"
mkdir -p "$RUN_DIR"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "📂  Output directory : $RUN_DIR"
echo "📱  Simulator        : $DEVICE"
echo ""

# Resolve a single UDID up front. Using the device name for boot/destination but
# `booted` for `simctl io recordVideo` can record the wrong sim when multiple
# are booted on a dev machine. Pin everything to one UDID.
DEVICE_STATE=$(xcrun simctl list devices "$DEVICE" | grep -E "$DEVICE \(" | head -1 || true)
if [[ -z "$DEVICE_STATE" ]]; then
    echo "❌  Simulator not found: $DEVICE"
    echo "    Available simulators:"
    xcrun simctl list devices | grep -E "iPhone|iPad" | grep -v unavailable
    exit 1
fi

UDID=$(echo "$DEVICE_STATE" | sed -nE 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/p')
if [[ -z "$UDID" ]]; then
    echo "❌  Could not resolve UDID for simulator: $DEVICE"
    echo "    DEVICE_STATE: $DEVICE_STATE"
    exit 1
fi
echo "🆔  UDID             : $UDID"

if ! echo "$DEVICE_STATE" | grep -q "Booted"; then
    echo "🔌  Booting $DEVICE..."
    xcrun simctl boot "$UDID" 2>/dev/null || true
    sleep 5
fi

# Each test class gets its own video file so we can correlate easily.
TEST_CLASSES=(
    "EventsScreenshotsTests"
    "SlotsScreenshotsTests"
)

OVERALL_RC=0

for TEST_CLASS in "${TEST_CLASSES[@]}"; do
    echo ""
    echo "▶️   Running $TEST_CLASS"
    VIDEO_FILE="$RUN_DIR/${TEST_CLASS}.mp4"

    # Start screen recording in the background. Pin to the resolved UDID so
    # the recorder and `xcodebuild` target the same simulator even when multiple
    # are booted.
    xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$VIDEO_FILE" &
    REC_PID=$!
    sleep 1  # let the recorder spin up before tests start

    xcodebuild test \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$UDID" \
        -only-testing "NativeDisplaySampleUITests/$TEST_CLASS" \
        -resultBundlePath "$RUN_DIR/${TEST_CLASS}.xcresult" \
        2>&1 | tail -60
    RC=${PIPESTATUS[0]}

    # Stop recording; simctl listens for SIGINT to flush the file cleanly.
    if kill -0 "$REC_PID" 2>/dev/null; then
        kill -INT "$REC_PID"
        wait "$REC_PID" 2>/dev/null || true
    fi

    if [[ $RC -ne 0 ]]; then
        echo "⚠️   $TEST_CLASS exited with code $RC (see logs above)"
        OVERALL_RC=$RC
    fi

    # Extract screenshots from this run's xcresult into a sibling folder.
    if [[ -d "$RUN_DIR/${TEST_CLASS}.xcresult" ]]; then
        SHOTS_DIR="$RUN_DIR/${TEST_CLASS}-screenshots"
        mkdir -p "$SHOTS_DIR"
        PULL_SCREENSHOTS_QUIET=1 "$SCRIPT_DIR/pull_screenshots.sh" \
            "$RUN_DIR/${TEST_CLASS}.xcresult" "$SHOTS_DIR" 2>&1 | tail -3 || true
    fi

    # Brief pause between iterations so simctl releases the previous recorder.
    sleep 2
done

echo ""
echo "─────────────────────────────────────────────────────────────"
if [[ $OVERALL_RC -eq 0 ]]; then
    echo "✅  All automation tests passed."
else
    echo "⚠️   Some tests failed (exit code $OVERALL_RC). Check xcresult bundles."
fi
echo "📂  Artifacts: $RUN_DIR"
open "$RUN_DIR"
exit $OVERALL_RC
