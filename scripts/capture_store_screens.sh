#!/usr/bin/env bash
# Captures the store and README screenshots on dedicated devices with demo
# data (apps/myanmar_calendar/integration_test/store_screens_test.dart).
#
# It creates its own simulators and emulators, named "Store …", so it never
# touches a device with real data. Raw PNGs land in
# apps/myanmar_calendar/build/store_raw/<device>/.
#
# Usage: scripts/capture_store_screens.sh [iphone|ipad|android_phone|android_tablet]...
#        (no arguments: all four)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/apps/myanmar_calendar"
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="$SDK/platform-tools/adb"
AVDMANAGER="$SDK/cmdline-tools/latest/bin/avdmanager"
EMULATOR="$SDK/emulator/emulator"
IOS_RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-26-2"
ANDROID_IMAGE="system-images;android-35;google_apis_playstore;arm64-v8a"

devices=("$@")
[ ${#devices[@]} -eq 0 ] && devices=(iphone ipad android_phone android_tablet)

# The simulator named $1 (created from device type $2 if missing).
ios_device() {
  local name="$1" type="$2" udid
  udid=$(xcrun simctl list devices -j | python3 -c "
import json, sys
for runtime, devs in json.load(sys.stdin)['devices'].items():
    for d in devs:
        if d['name'] == '$name' and d['isAvailable']:
            print(d['udid']); sys.exit()")
  if [ -z "$udid" ]; then
    udid=$(xcrun simctl create "$name" "$type" "$IOS_RUNTIME")
  fi
  echo "$udid"
}

# Runs the test on $2 and, for each STORE_SHOT line, saves a real device
# screenshot to build/store_raw/$1/<name>.png with $3 (an
# "xcrun simctl io <udid> screenshot" prefix, or "android:<serial>").
run_capture() {
  local device="$1" id="$2" shooter="$3" out="$APP/build/store_raw/$1"
  mkdir -p "$out"
  (cd "$APP" && flutter test integration_test/store_screens_test.dart \
    -d "$id" --no-pub 2>&1) | while IFS= read -r line; do
    echo "$line"
    case "$line" in
      *STORE_SHOT\ *)
        local name="${line##*STORE_SHOT }"
        name="${name%%[[:space:]]*}"
        sleep 1.5
        if [[ "$shooter" == android:* ]]; then
          "$ADB" -s "${shooter#android:}" exec-out screencap -p >"$out/$name.png"
        else
          $shooter "$out/$name.png" >/dev/null
        fi
        echo "  saved $out/$name.png" ;;
    esac
  done
}

capture_ios() {
  local device="$1" name="$2" type="$3" udid
  udid=$(ios_device "$name" "$type")
  # A clean device each run, so the demo data is never doubled.
  xcrun simctl shutdown "$udid" 2>/dev/null || true
  xcrun simctl erase "$udid"
  xcrun simctl boot "$udid"
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl status_bar "$udid" override --time 9:41 \
    --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 \
    --batteryState charged --batteryLevel 100
  run_capture "$device" "$udid" "xcrun simctl io $udid screenshot"
}

# The emulator AVD $1 (created from hardware profile $2 if missing).
capture_android() {
  local device="$1" avd="$2" profile="$3" serial
  if ! "$EMULATOR" -list-avds | grep -qx "$avd"; then
    echo no | "$AVDMANAGER" create avd -n "$avd" -k "$ANDROID_IMAGE" -d "$profile"
  fi
  # -wipe-data: a clean device each run, so the demo data is never doubled.
  "$EMULATOR" -avd "$avd" -wipe-data -no-snapshot -no-boot-anim >/dev/null 2>&1 &
  "$ADB" wait-for-device
  serial=$("$ADB" devices | awk '/emulator-/{print $1; exit}')
  until [ "$("$ADB" -s "$serial" shell getprop sys.boot_completed | tr -d '\r')" = 1 ]; do
    sleep 2
  done
  # System UI demo mode: 9:41, full battery and signal, no notifications.
  "$ADB" -s "$serial" shell settings put global sysui_demo_allowed 1
  for command in "clock -e hhmm 0941" "battery -e level 100 -e plugged false" \
    "network -e wifi show -e level 4 -e mobile show -e datatype none -e level 4" \
    "notifications -e visible false"; do
    # shellcheck disable=SC2086
    "$ADB" -s "$serial" shell am broadcast -a com.android.systemui.demo \
      -e command ${command%% *} ${command#* } >/dev/null
  done
  "$ADB" -s "$serial" shell am broadcast -a com.android.systemui.demo -e command enter >/dev/null
  run_capture "$device" "$serial" "android:$serial"
  "$ADB" -s "$serial" emu kill >/dev/null 2>&1 || true
}

for device in "${devices[@]}"; do
  case "$device" in
    iphone) capture_ios iphone "Store iPhone 17 Pro Max" \
      com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max ;;
    ipad) capture_ios ipad "Store iPad Pro 13-inch" \
      com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M4-8GB ;;
    android_phone) capture_android android_phone Store_Phone pixel_9_pro ;;
    android_tablet) capture_android android_tablet Store_Tablet pixel_tablet ;;
    *) echo "Unknown device: $device" >&2; exit 1 ;;
  esac
done
echo "Screenshots: $APP/build/store_raw/"
