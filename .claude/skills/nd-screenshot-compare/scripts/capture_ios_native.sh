#!/usr/bin/env bash
# capture_ios_native.sh <UDID> <outDir>
# Runs ios-sample's SwiftUI events screenshot UI test and extracts PNGs into <outDir>.
# Produces swiftui-events-<event>.png. Runs TWICE for a warm image cache.
#
# ios-sample uses Swift Package Manager (no CocoaPods/Podfile). The UIKit variant is
# currently flaky, so only the SwiftUI test is run.
set -euo pipefail

UDID="${1:?usage: capture_ios_native.sh <UDID> <outDir>}"
OUT_DIR="${2:?usage: capture_ios_native.sh <UDID> <outDir>}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
SAMPLE="$REPO_ROOT/ios-sample"
mkdir -p "$OUT_DIR"

ONLY_TESTING="NativeDisplaySampleUITests/EventsScreenshotsTests/test_swiftUIEventsScreen_fireAllEvents"

run_once() {
  local xcresult="$1"
  rm -rf "$xcresult"
  echo "== xcodebuild test (sim=$UDID) -> $xcresult"
  ( cd "$SAMPLE" && \
    xcodebuild test -scheme NativeDisplaySample \
      -destination "platform=iOS Simulator,id=$UDID" \
      -only-testing "$ONLY_TESTING" \
      -resultBundlePath "$xcresult" )
  echo "== Extracting screenshots -> $OUT_DIR"
  ( cd "$SAMPLE" && ./pull_screenshots.sh "$xcresult" "$OUT_DIR" )
}

echo "== Pass 1/2 (cold cache) =="
run_once /tmp/ios_ev_pass1.xcresult
echo "== Pass 2/2 (warm cache — this is the keeper) =="
run_once /tmp/ios_ev.xcresult

echo "== Done. Screenshots in: $OUT_DIR"
ls -1 "$OUT_DIR"/swiftui-events-*.png 2>/dev/null | wc -l | xargs echo "  swiftui-events PNGs:"
