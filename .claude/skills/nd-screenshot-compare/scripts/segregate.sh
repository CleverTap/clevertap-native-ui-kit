#!/usr/bin/env bash
# segregate.sh — map per-framework capture dirs into the review layout:
#   <out>/<os>/<event>/<framework>.png
#
# Usage:
#   segregate.sh \
#     --flutter-android <dir>   # flutter-events-<event>.png captured on an ANDROID device
#     --native-android  <dir>   # composeEventsScreen_fireAllEvents_<event>.png
#     --flutter-ios     <dir>   # flutter-events-<event>.png captured on an iOS sim
#     --native-ios      <dir>   # swiftui-events-<event>.png
#     --rn-android      <dir>   # TODO
#     --rn-ios          <dir>   # TODO
#     [--out <dir>]             # default: ~/Desktop/nd-screenshots-review
set -euo pipefail

OUT="$HOME/Desktop/nd-screenshots-review"
FLUTTER_ANDROID="" NATIVE_ANDROID="" FLUTTER_IOS="" NATIVE_IOS="" RN_ANDROID="" RN_IOS=""

# The 22 canonical events — order & casing matter.
EVENTS=(header1 header2 header3 header4 header5 \
        footer1 footer2 footer3 footer4 footer5 \
        nps topi kk mm ii iip ss cptest hi viewed html2 home)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --flutter-android) FLUTTER_ANDROID="$2"; shift 2 ;;
    --native-android)  NATIVE_ANDROID="$2";  shift 2 ;;
    --flutter-ios)     FLUTTER_IOS="$2";     shift 2 ;;
    --native-ios)      NATIVE_IOS="$2";      shift 2 ;;
    --rn-android)      RN_ANDROID="$2";      shift 2 ;;
    --rn-ios)          RN_IOS="$2";          shift 2 ;;
    --out)             OUT="$2";             shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# copy_set <srcDir> <os> <framework> <prefix> <suffix>
# For each canonical event, copy <srcDir>/<prefix><event><suffix>.png to
# <OUT>/<os>/<event>/<framework>.png (skips missing sources with a warning).
copy_set() {
  local src="$1" os="$2" fw="$3" prefix="$4" suffix="$5"
  [[ -z "$src" ]] && return 0
  if [[ ! -d "$src" ]]; then
    echo "  [WARN] $fw/$os source dir not found: $src" >&2
    return 0
  fi
  local copied=0 missing=0 ev file dest
  for ev in "${EVENTS[@]}"; do
    file="$src/${prefix}${ev}${suffix}.png"
    if [[ -f "$file" ]]; then
      dest="$OUT/$os/$ev"
      mkdir -p "$dest"
      cp "$file" "$dest/$fw.png"
      copied=$((copied + 1))
    else
      missing=$((missing + 1))
    fi
  done
  echo "  $fw/$os: copied $copied, missing $missing (from $src)"
}

echo "== Building review bundle at: $OUT"
mkdir -p "$OUT"

copy_set "$FLUTTER_ANDROID" android flutter "flutter-events-" ""
copy_set "$NATIVE_ANDROID"  android native  "composeEventsScreen_fireAllEvents_" ""
copy_set "$FLUTTER_IOS"     ios     flutter "flutter-events-" ""
copy_set "$NATIVE_IOS"      ios     native  "swiftui-events-" ""
# RN — TODO; patterns unknown until the RN sample lands.
copy_set "$RN_ANDROID"      android rn      "rn-events-" ""
copy_set "$RN_IOS"          ios     rn      "rn-events-" ""

# README at the review root.
cat > "$OUT/README.txt" <<'README'
ND Cross-Platform Screenshot Review
===================================

Layout:
  <os>/<event>/<framework>.png

  os        : android | ios
  event     : the fired CleverTap event (22 canonical events, see list below)
  framework : flutter | native | rn

Each event folder holds every framework's rendering of that event for that OS, so you
can diff them side-by-side. There is no per-platform top folder beyond <os>.

22 canonical events (order & casing matter):
  header1 header2 header3 header4 header5
  footer1 footer2 footer3 footer4 footer5
  nps topi kk mm ii iip ss cptest hi viewed html2 home

Source -> destination mapping:
  flutter-events-<event>.png (Android capture)  -> android/<event>/flutter.png
  composeEventsScreen_fireAllEvents_<event>.png -> android/<event>/native.png
  flutter-events-<event>.png (iOS capture)      -> ios/<event>/flutter.png
  swiftui-events-<event>.png                    -> ios/<event>/native.png
  rn (Android/iOS)                              -> android|ios/<event>/rn.png  [TODO]

TODO — React Native (rn.png):
  The RN sample is not in this branch yet. When it lands, add an RN capture step
  (framework=rn) mirroring the Flutter approach and re-run segregation with
  --rn-android / --rn-ios so rn.png appears alongside flutter.png and native.png.

Caveats:
  - Per-event campaign content can legitimately differ across platforms (dashboard
    A/B tests, pivots, platform-targeted variants). That is NOT a renderer bug — verify
    in the dashboard before filing a parity issue.
  - Screenshots are the warm-cache (2nd) pass; first passes may show cold images.
README

echo "== Wrote $OUT/README.txt"
echo "== Done."
