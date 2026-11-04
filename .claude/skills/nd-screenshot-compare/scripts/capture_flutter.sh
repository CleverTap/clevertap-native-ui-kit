#!/usr/bin/env bash
# capture_flutter.sh <deviceId> <outDir>
# Drives flutter-sample's events screenshot suite. Runs TWICE for a warm image cache.
# Produces flutter-events-<event>.png in <outDir>.
set -euo pipefail

DEVICE_ID="${1:?usage: capture_flutter.sh <deviceId> <outDir>}"
OUT_DIR="${2:?usage: capture_flutter.sh <deviceId> <outDir>}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
mkdir -p "$OUT_DIR"

run_once() {
  echo "== flutter drive (device=$DEVICE_ID) -> $OUT_DIR"
  ( cd "$REPO_ROOT/flutter-sample" && \
    ND_SCREENSHOT_DIR="$OUT_DIR" flutter drive \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/events_screenshots_test.dart \
      --dart-define=ND_AUTOMATION=true \
      -d "$DEVICE_ID" )
}

echo "== Pass 1/2 (cold cache) =="
run_once
echo "== Pass 2/2 (warm cache — this is the keeper) =="
run_once

echo "== Done. Screenshots in: $OUT_DIR"
ls -1 "$OUT_DIR"/flutter-events-*.png 2>/dev/null | wc -l | xargs echo "  flutter-events PNGs:"
