#!/usr/bin/env bash
# capture_rn_ios.sh <UDID> <outDir> [settleSeconds] [bundleId]
# Drives the React Native example (react-native/example) events screen on a BOOTED
# iOS simulator and captures one screenshot per canonical event. Produces
# rn-events-<event>.png in <outDir> — segregate.sh maps these to ios/<event>/rn.png.
#
# WHY A DEEP LINK (not taps like the Android script): simctl can screenshot but
# cannot tap/type, and the RN example has no XCUITest harness. So the APP drives
# itself: the example registers an in-app automation mode (SDK-6264) that fires one
# event when it receives the deep link
#     ndautomation://event?name=<eventName>
# This script opens that URL once per event (full pacing control, no timer drift),
# waits `settle` for the unit to render, then captures via `xcrun simctl io screenshot`.
#
# Preconditions: the RN example app is BUILT, INSTALLED and LAUNCHED on the Events
# screen; Metro is running (debug build); the automation mode (SDK-6264) is present.
set -euo pipefail

UDID="${1:?usage: capture_rn_ios.sh <UDID> <outDir> [settle] [bundleId]}"
OUT_DIR="${2:?usage: capture_rn_ios.sh <UDID> <outDir> [settle] [bundleId]}"
SETTLE="${3:-12}"
BUNDLE="${4:-com.clevertap.nativedisplay.sample}"
mkdir -p "$OUT_DIR"

EVENTS=(header1 header2 header3 header4 header5 \
        footer1 footer2 footer3 footer4 footer5 \
        nps topi kk mm ii iip ss cptest hi viewed html2 home)

# Make sure the app is foregrounded before we start (deep links wake it, but a cold
# relaunch guarantees we're on a known screen). A failure here is non-fatal.
xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
sleep 3

fire_and_capture() {
  local ev="$1"
  # Fire exactly one event via the automation deep link; the app logs it on-screen
  # and renders the resulting unit on the canvas.
  xcrun simctl openurl "$UDID" "ndautomation://event?name=$ev" >/dev/null 2>&1
  sleep "$SETTLE"
  xcrun simctl io "$UDID" screenshot "$OUT_DIR/rn-events-$ev.png" >/dev/null 2>&1
  local sz; sz=$(wc -c < "$OUT_DIR/rn-events-$ev.png" | tr -d ' ')
  echo "  [$ev] captured (${sz} bytes)"
}

echo "== RN iOS drive: bundle=$BUNDLE settle=${SETTLE}s udid=$UDID =="
for ev in "${EVENTS[@]}"; do fire_and_capture "$ev"; done

echo "== Done. RN iOS screenshots in: $OUT_DIR"
ls -1 "$OUT_DIR"/rn-events-*.png 2>/dev/null | wc -l | xargs echo "  rn-events PNGs:"
