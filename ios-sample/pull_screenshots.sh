#!/bin/bash
# pull_screenshots.sh
# Extracts named screenshots from the latest NativeDisplaySample .xcresult bundle.
#
# Usage:
#   ./pull_screenshots.sh                      # uses latest xcresult automatically
#   ./pull_screenshots.sh <path/to/run.xcresult>  # uses specified xcresult

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
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUT_DIR=~/Desktop/NativeDisplayScreenShots-${TIMESTAMP}
mkdir -p "$OUT_DIR"

echo "📦  Source : $XCRESULT"
echo "📂  Output : $OUT_DIR"
echo ""

# ── Python extractor ─────────────────────────────────────────────────────────
python3 - "$XCRESULT" "$OUT_DIR" <<'PYTHON'
import json, subprocess, sys
from pathlib import Path

xcresult = sys.argv[1]
out_dir  = Path(sys.argv[2])

def xcresult_json(ref_id=None):
    cmd = ["xcrun", "xcresulttool", "get", "--legacy", "--path", xcresult, "--format", "json"]
    if ref_id:
        cmd += ["--id", ref_id]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(f"xcresulttool error: {r.stderr.strip()}")
    return json.loads(r.stdout)

def collect_attachments(node, found=None):
    """Recursively walk the JSON tree and collect all ActionTestAttachment entries."""
    if found is None:
        found = []
    if isinstance(node, dict):
        if node.get("_type", {}).get("_name") == "ActionTestAttachment":
            name = node.get("filename", {}).get("_value", "")
            pid  = node.get("payloadRef", {}).get("id", {}).get("_value", "")
            uti  = node.get("uniformTypeIdentifier", {}).get("_value", "image/png")
            if name and pid:
                found.append({"name": name, "id": pid, "uti": uti})
        for v in node.values():
            collect_attachments(v, found)
    elif isinstance(node, list):
        for item in node:
            collect_attachments(item, found)
    return found

# ── Walk actions → testsRef → full attachment tree ───────────────────────────
print("🔍  Parsing xcresult structure...")
root = xcresult_json()

attachments = []
for action in root.get("actions", {}).get("_values", []):
    ref_id = (action
              .get("actionResult", {})
              .get("testsRef", {})
              .get("id", {})
              .get("_value"))
    if ref_id:
        print(f"    Fetching test summary (ref: {ref_id[:8]}...)")
        test_data = xcresult_json(ref_id)
        attachments.extend(collect_attachments(test_data))

if not attachments:
    print("⚠️   No attachments found in this xcresult.")
    print("     Make sure the test ran with attachment.lifetime = .keepAlways")
    sys.exit(0)

print(f"📸  Found {len(attachments)} screenshot(s). Exporting...\n")

ok = 0
for i, att in enumerate(attachments, 1):
    ext = "png" if "png" in att["uti"] else "jpeg" if "jpeg" in att["uti"] else "bin"
    out_file = out_dir / f"{att['name']}.{ext}"
    cmd = ["xcrun", "xcresulttool", "get", "--legacy",
           "--path", xcresult, "--id", att["id"]]
    r = subprocess.run(cmd, capture_output=True)
    if r.returncode == 0 and r.stdout:
        out_file.write_bytes(r.stdout)
        print(f"  [{i:>3}/{len(attachments)}] ✓  {out_file.name}")
        ok += 1
    else:
        print(f"  [{i:>3}/{len(attachments)}] ✗  {att['name']}  ({r.stderr.decode().strip()[:80]})")

print(f"\n✅  {ok}/{len(attachments)} screenshot(s) saved.")

# Print failure report if present
for att in attachments:
    if att["name"] == "FAILED_CONFIGS":
        r = subprocess.run(
            ["xcrun", "xcresulttool", "get", "--legacy", "--path", xcresult, "--id", att["id"]],
            capture_output=True
        )
        if r.returncode == 0:
            report_file = out_dir / "FAILED_CONFIGS.txt"
            report_file.write_bytes(r.stdout)
            print(f"\n{'─'*60}")
            print(r.stdout.decode(errors="replace"))
            print(f"{'─'*60}")
PYTHON

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "📂  Opening: $OUT_DIR"
open "$OUT_DIR"
