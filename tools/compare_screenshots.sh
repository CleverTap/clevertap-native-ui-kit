#!/usr/bin/env bash
# compare_screenshots.sh — Shell wrapper for compare_screenshots.py
#
# Auto-detects:
#   - Latest Android Roborazzi output directory
#   - Latest iOS screenshot folder on the Desktop matching NativeDisplayScreenShots-*
#
# Then invokes compare_screenshots.py with those paths.
#
# Usage:
#   ./tools/compare_screenshots.sh [extra args passed to compare_screenshots.py]
#
# Examples:
#   ./tools/compare_screenshots.sh
#   ./tools/compare_screenshots.sh --threshold 3.0
#   ./tools/compare_screenshots.sh --output /tmp/my_report

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve script + repo root
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PYTHON_SCRIPT="${SCRIPT_DIR}/compare_screenshots.py"

# ---------------------------------------------------------------------------
# Auto-detect Android screenshots
# ---------------------------------------------------------------------------

ANDROID_ROBORAZZI_DIR="${REPO_ROOT}/android-sample/app/configs"

if [[ -d "${ANDROID_ROBORAZZI_DIR}" ]]; then
    ANDROID_DIR="${ANDROID_ROBORAZZI_DIR}"
    echo "Android screenshots : ${ANDROID_DIR}"
else
    echo ""
    echo "ERROR: Android screenshot directory not found:"
    echo "  ${ANDROID_ROBORAZZI_DIR}"
    echo ""
    echo "To generate Android screenshots, run:"
    echo "  cd ${REPO_ROOT}/android-sample"
    echo "  ./gradlew :app:testDebugUnitTest --tests NativeDisplayScreenshotTest"
    echo ""
    ANDROID_DIR=""
fi

# ---------------------------------------------------------------------------
# Auto-detect latest iOS screenshot folder on Desktop
# ---------------------------------------------------------------------------

DESKTOP="${HOME}/Desktop"
IOS_DIR=""

if [[ -d "${DESKTOP}" ]]; then
    # Find most recently modified folder matching NativeDisplayScreenShots-*
    # Use -t (sort by modification time) and take the first match
    LATEST_IOS="$(find "${DESKTOP}" -maxdepth 1 -type d -name "NativeDisplayScreenShots-*" \
        -print0 2>/dev/null | xargs -0 ls -dt 2>/dev/null | head -1)"

    if [[ -n "${LATEST_IOS}" && -d "${LATEST_IOS}" ]]; then
        IOS_DIR="${LATEST_IOS}"
        echo "iOS screenshots     : ${IOS_DIR}"
    fi
fi

if [[ -z "${IOS_DIR}" ]]; then
    echo ""
    echo "ERROR: No iOS screenshot folder found on Desktop matching NativeDisplayScreenShots-*"
    echo ""
    echo "To generate iOS screenshots, run:"
    echo "  cd ${REPO_ROOT}/ios-sample"
    echo "  bash pull_screenshots.sh"
    echo ""
    echo "This will create a folder like ~/Desktop/NativeDisplayScreenShots-YYYYMMDD-HHMMSS/"
    echo ""
fi

# ---------------------------------------------------------------------------
# Bail if either path is missing
# ---------------------------------------------------------------------------

if [[ -z "${ANDROID_DIR}" || -z "${IOS_DIR}" ]]; then
    echo "Cannot run comparison — one or both screenshot directories are missing."
    echo ""
    echo "You can also run the comparison manually:"
    echo "  python3 ${PYTHON_SCRIPT} \\"
    echo "      --android <android-screenshots-dir> \\"
    echo "      --ios <ios-screenshots-dir>"
    exit 1
fi

# ---------------------------------------------------------------------------
# Run comparison
# ---------------------------------------------------------------------------

echo ""
echo "Running comparison..."
echo ""

python3 "${PYTHON_SCRIPT}" \
    --android "${ANDROID_DIR}" \
    --ios "${IOS_DIR}" \
    "$@"
