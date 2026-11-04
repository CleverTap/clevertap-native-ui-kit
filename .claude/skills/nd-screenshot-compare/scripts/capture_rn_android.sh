#!/usr/bin/env bash
# capture_rn_android.sh <serial> <outDir> [settleSeconds] [package] [activity]
# Drives the React Native example (react-native/example) events screen on an Android
# device/emulator via adb and captures one screenshot per canonical event.
# Produces rn-events-<event>.png in <outDir> — segregate.sh maps these to
# android/<event>/rn.png.
#
# SAFETY: this script NEVER sends BACK (the RN app uses in-app navigation, so BACK at
# the root drops to the launcher and subsequent blind taps would hit random apps).
# Instead it submits via the IME ENTER action (the event input has returnKeyType="send"
# + onSubmitEditing, and blurOnSubmit closes the keyboard). Before every event it
# verifies the RN app is still the foreground activity and recovers if not.
#
# Preconditions: the RN example app is BUILT, INSTALLED and LAUNCHED on the Events
# screen; Metro is running (debug build).
set -euo pipefail

SERIAL="${1:?usage: capture_rn_android.sh <serial> <outDir> [settle] [package] [activity]}"
OUT_DIR="${2:?usage: capture_rn_android.sh <serial> <outDir> [settle] [package] [activity]}"
SETTLE="${3:-12}"
PKG="${4:-com.ndexample}"
ACT="${5:-.MainActivity}"
ADB="adb -s $SERIAL"
mkdir -p "$OUT_DIR"

EVENTS=(header1 header2 header3 header4 header5 \
        footer1 footer2 footer3 footer4 footer5 \
        nps topi kk mm ii iip ss cptest hi viewed html2 home)

INPUT_XY=""

foreground_ok() { $ADB shell dumpsys activity activities 2>/dev/null | grep -qE "topResumedActivity.*$PKG/"; }

wait_for_events_screen() {
  local i=0
  until { $ADB shell uiautomator dump /sdcard/ndui.xml >/dev/null 2>&1 && \
          $ADB shell cat /sdcard/ndui.xml 2>/dev/null | grep -q "android.widget.EditText"; } \
        || [ $i -ge 20 ]; do sleep 2; i=$((i+1)); done
}

recover() {
  echo "  [recover] RN app not foreground — relaunching $PKG"
  $ADB shell input keyevent KEYCODE_HOME >/dev/null 2>&1 || true
  $ADB shell am force-stop "$PKG" >/dev/null 2>&1 || true
  $ADB shell am start -n "$PKG/$ACT" >/dev/null 2>&1 || true
  sleep 6
  wait_for_events_screen
  INPUT_XY=""   # force a re-dump of coordinates
}

# Center "cx cy" of the first node matching the python predicate over attrib dict `a`.
find_center() {
  local pred="$1"
  $ADB shell uiautomator dump /sdcard/ndui.xml >/dev/null 2>&1 || true
  $ADB pull /sdcard/ndui.xml /tmp/ndui.xml >/dev/null 2>&1
  python3 - "$pred" <<'PY'
import sys, re, xml.etree.ElementTree as ET
pred = sys.argv[1]
try:
    root = ET.parse('/tmp/ndui.xml').getroot()
except Exception:
    sys.exit(0)
for node in root.iter('node'):
    a = node.attrib
    try:
        if eval(pred):
            m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', a.get('bounds',''))
            if m:
                x1,y1,x2,y2 = map(int, m.groups())
                print((x1+x2)//2, (y1+y2)//2); break
    except Exception:
        pass
PY
}

ensure_input_xy() {
  if [[ -z "$INPUT_XY" ]]; then
    INPUT_XY="$(find_center "a.get('class')=='android.widget.EditText'")"
    echo "  input center: ${INPUT_XY:-<not found>}"
  fi
}

fire_and_capture() {
  local ev="$1"
  if ! foreground_ok; then recover; fi
  ensure_input_xy
  if [[ -z "$INPUT_XY" ]]; then echo "  [$ev] SKIP — no input field"; return; fi
  $ADB shell input tap $INPUT_XY >/dev/null 2>&1; sleep 0.5
  $ADB shell input text "$ev" >/dev/null 2>&1; sleep 0.5
  # Submit via IME action (returnKeyType=send -> onSubmitEditing); blurOnSubmit closes
  # the keyboard. No BACK, ever.
  $ADB shell input keyevent 66 >/dev/null 2>&1
  sleep "$SETTLE"
  if ! foreground_ok; then
    echo "  [$ev] left the app after submit — recovering, screenshot may be blank"
    recover
  fi
  $ADB exec-out screencap -p > "$OUT_DIR/rn-events-$ev.png"
  local sz; sz=$(wc -c < "$OUT_DIR/rn-events-$ev.png" | tr -d ' ')
  echo "  [$ev] captured (${sz} bytes)"
}

echo "== RN Android drive: pkg=$PKG settle=${SETTLE}s =="
if ! foreground_ok; then recover; fi
ensure_input_xy
if [[ -z "$INPUT_XY" ]]; then
  echo "  [ERROR] Could not find the event input. Is the Events screen showing?" >&2
  exit 1
fi

for ev in "${EVENTS[@]}"; do fire_and_capture "$ev"; done

echo "== Done. RN Android screenshots in: $OUT_DIR"
ls -1 "$OUT_DIR"/rn-events-*.png 2>/dev/null | wc -l | xargs echo "  rn-events PNGs:"
