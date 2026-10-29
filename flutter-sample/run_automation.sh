#!/usr/bin/env bash
#
# Drives the Flutter events + slots screenshot automation suite against a device
# or emulator, pulling all PNGs to ~/Desktop/nd-automation-output/flutter/ so
# they sit next to the Android and iOS captures for cross-platform comparison.
#
# This is the Flutter counterpart of:
#   android-sample: ./gradlew :app:automationScreenshots
#   ios-sample:     ./run_automation_with_video.sh + pull_screenshots.sh
#
# Usage:
#   ./run_automation.sh [deviceId]
#
# deviceId is optional; if omitted, flutter picks the only attached device.
# Find ids with `flutter devices` (e.g. emulator-5554, or an iOS sim UDID).
#
# The suite fires REAL CleverTap events against the live account the sample is
# configured with, and screenshots the server-returned campaigns — so the device
# needs network and the dashboard campaigns must be provisioned.

set -euo pipefail

DEVICE="${1:-}"
OUT="${ND_SCREENSHOT_DIR:-$HOME/Desktop/nd-automation-output/flutter}"
export ND_SCREENSHOT_DIR="$OUT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

mkdir -p "$OUT"
echo "Screenshots -> $OUT"

DEV_ARGS=()
if [ -n "$DEVICE" ]; then
  DEV_ARGS=(-d "$DEVICE")
fi

for target in events_screenshots_test slots_screenshots_test; do
  echo "=== Running integration_test/${target}.dart ==="
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target="integration_test/${target}.dart" \
    --dart-define=ND_AUTOMATION=true \
    "${DEV_ARGS[@]}"
done

echo "Done. Screenshots in $OUT"
ls -1 "$OUT" 2>/dev/null || true
