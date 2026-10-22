#!/usr/bin/env bash
# check_prereqs.sh — sanity-check devices/simulators and staging credentials.
# Does NOT run any capture. Safe to run anytime.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
ACCOUNT_ID="468-RZW-ZK6Z"

echo "== Repo root: $REPO_ROOT"
echo
echo "== Android devices (adb) =="
if command -v adb >/dev/null 2>&1; then adb devices; else echo "  adb not found on PATH"; fi
echo
echo "== Flutter devices =="
if command -v flutter >/dev/null 2>&1; then flutter devices; else echo "  flutter not found on PATH"; fi
echo
echo "== Booted iOS simulators =="
if command -v xcrun >/dev/null 2>&1; then xcrun simctl list devices booted; else echo "  xcrun not found on PATH"; fi
echo
echo "== Credential check (staging account $ACCOUNT_ID) =="

check_file() {
  local label="$1" file="$2" needle="$3"
  if [[ ! -f "$file" ]]; then
    echo "  [MISSING] $label: $file"
  elif grep -q "$needle" "$file"; then
    echo "  [OK]      $label"
  else
    echo "  [SET ME]  $label does not reference $needle: $file"
  fi
}

check_file "flutter-sample Android manifest" \
  "$REPO_ROOT/flutter-sample/android/app/src/main/AndroidManifest.xml" "$ACCOUNT_ID"
check_file "android-sample Android manifest" \
  "$REPO_ROOT/android-sample/app/src/main/AndroidManifest.xml" "$ACCOUNT_ID"
check_file "flutter-sample iOS Info.plist" \
  "$REPO_ROOT/flutter-sample/ios/Runner/Info.plist" "$ACCOUNT_ID"
check_file "ios-sample Info.plist" \
  "$REPO_ROOT/ios-sample/NativeDisplaySample/Info.plist" "$ACCOUNT_ID"

echo
echo "Reminder: credentials are LOCAL ONLY — do not commit them."
