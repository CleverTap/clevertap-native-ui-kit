#!/bin/bash
# pull_screenshots.sh
# Extracts named screenshots from a NativeDisplaySample .xcresult bundle using
# the modern (Xcode 16+) xcresulttool API: `xcresulttool export attachments`.
#
# Usage:
#   ./pull_screenshots.sh                          # uses latest xcresult automatically
#   ./pull_screenshots.sh <path/to/run.xcresult>   # uses specified xcresult
#   ./pull_screenshots.sh <xcresult> <out_dir>     # explicit output directory

set -euo pipefail

# ── Resolve xcresult path ────────────────────────────────────────────────────
if [[ $# -ge 1 ]]; then
    XCRESULT="$1"
else
    XCRESULT=$(ls -dt ~/Library/Developer/Xcode/DerivedData/NativeDisplaySample-*/Logs/Test/*.xcresult 2>/dev/null | head -1)
    if [[ -z "$XCRESULT" ]]; then
        echo "❌  No .xcresult found in DerivedData for NativeDisplaySample."
        echo "    Run the tests first, or pass the path explicitly:"
        echo "    $0 <path/to/run.xcresult>"
        exit 1
    fi
fi

if [[ ! -d "$XCRESULT" ]]; then
    echo "❌  Not found: $XCRESULT"
    exit 1
fi

# ── Output folder ────────────────────────────────────────────────────────────
if [[ $# -ge 2 ]]; then
    OUT_DIR="$2"
else
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    OUT_DIR=~/Desktop/NativeDisplayScreenShots-${TIMESTAMP}
fi
mkdir -p "$OUT_DIR"

echo "📦  Source : $XCRESULT"
echo "📂  Output : $OUT_DIR"
echo ""

# ── Export attachments ───────────────────────────────────────────────────────
echo "🔍  Exporting attachments via xcresulttool..."
xcrun xcresulttool export attachments \
    --path "$XCRESULT" \
    --output-path "$OUT_DIR" \
    2>/dev/null | grep -E "^File:" | head -5 || true

# Count UUID files extracted
UUID_COUNT=$(find "$OUT_DIR" -maxdepth 1 -type f -name '*.png' ! -name 'swiftui-*' ! -name 'uikit-*' | wc -l | tr -d ' ')
if [[ "$UUID_COUNT" -eq 0 ]]; then
    echo "⚠️   No attachments found in this xcresult."
    echo "     Make sure tests use XCTAttachment with .keepAlways lifetime."
    exit 0
fi

# ── Rename UUIDs to human-readable names via manifest.json ───────────────────
python3 - "$OUT_DIR" <<'PY'
import json, sys, os, shutil
d = sys.argv[1]
manifest_path = os.path.join(d, "manifest.json")
if not os.path.exists(manifest_path):
    print(f"⚠️   No manifest.json — leaving UUID filenames as-is.")
    sys.exit(0)
manifest = json.load(open(manifest_path))
renamed = 0
for entry in manifest:
    for att in entry.get("attachments", []):
        src = os.path.join(d, att["exportedFileName"])
        if not os.path.exists(src):
            continue
        name = att.get("suggestedHumanReadableName") or att.get("attachmentName") or ""
        if not name:
            continue
        # Strip XCTest's "_<index>_<uuid>.png" suffix → "uikit-events-header3.png"
        clean = name.split("_0_")[0]
        if not clean.endswith(".png"):
            clean += ".png"
        dst = os.path.join(d, clean)
        i = 2
        base, ext = os.path.splitext(dst)
        while os.path.exists(dst):
            dst = f"{base}-{i}{ext}"
            i += 1
        shutil.move(src, dst)
        renamed += 1
print(f"📸  Renamed {renamed} screenshot(s) to human-readable names.")
PY

NAMED_COUNT=$(find "$OUT_DIR" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')
echo "✅  $NAMED_COUNT screenshot(s) saved to $OUT_DIR"

# ── Done ─────────────────────────────────────────────────────────────────────
if [[ -z "${PULL_SCREENSHOTS_QUIET:-}" ]] && [[ -t 1 ]]; then
    open "$OUT_DIR"
fi
