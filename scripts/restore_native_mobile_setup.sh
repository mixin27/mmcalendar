#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCOPE="all"

usage() {
  cat <<'EOF'
Usage: ./scripts/restore_native_mobile_setup.sh [--scope <scope>]

Scopes:
  all              Restore Android app icons + Android home widgets + iOS app icons
  android          Restore Android app icons + Android home widgets
  android-icons    Restore Android app icon setup only
  android-widgets  Restore Android home widget setup only
  ios-icons        Restore iOS app icon setup only
EOF
}

if [[ $# -gt 0 ]]; then
  if [[ "$1" == "--scope" ]]; then
    SCOPE="${2:-all}"
    shift 2
  else
    usage
    exit 1
  fi
fi

if [[ $# -ne 0 ]]; then
  usage
  exit 1
fi

declare -a TARGETS=()

add_targets() {
  TARGETS+=("$@")
}

add_android_icon_targets() {
  add_targets \
    "apps/myanmar_calendar/android/app/src/main/AndroidManifest.xml" \
    "apps/myanmar_calendar/android/app/src/debug/AndroidManifest.xml" \
    "apps/myanmar_calendar/android/app/src/profile/AndroidManifest.xml" \
    "apps/myanmar_calendar/android/app/src/release/AndroidManifest.xml" \
    "apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/MainActivity.kt" \
    "apps/myanmar_calendar/android/app/src/main/res/values/ic_launcher_background.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/ic_launcher_foreground.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/ic_launcher_foreground_round.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/ic_launcher_moon_foreground.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/ic_launcher_moon_foreground_round.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/ic_launcher_forest_foreground.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/ic_launcher_forest_foreground_round.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/ic_launcher_minimal_flat_foreground.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/ic_launcher_minimal_flat_foreground_round.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/ic_launcher_premium_dark_foreground.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/ic_launcher_premium_dark_foreground_round.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/ic_launcher_traditional_myanmar_foreground.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/ic_launcher_traditional_myanmar_foreground_round.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/mipmap-anydpi-v26" \
    "apps/myanmar_calendar/android/app/src/main/res/mipmap-mdpi" \
    "apps/myanmar_calendar/android/app/src/main/res/mipmap-hdpi" \
    "apps/myanmar_calendar/android/app/src/main/res/mipmap-xhdpi" \
    "apps/myanmar_calendar/android/app/src/main/res/mipmap-xxhdpi" \
    "apps/myanmar_calendar/android/app/src/main/res/mipmap-xxxhdpi"
}

add_android_widget_targets() {
  add_targets \
    "apps/myanmar_calendar/android/app/src/main/AndroidManifest.xml" \
    "apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/CompactDateWidgetProvider.kt" \
    "apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/FullCalendarWidgetProvider.kt" \
    "apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/MoonPhaseWidgetProvider.kt" \
    "apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/MyanmarMonthWidgetProvider.kt" \
    "apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/WidgetBootReceiver.kt" \
    "apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/WidgetDateChangeReceiver.kt" \
    "apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/WidgetTimelineResolver.kt" \
    "apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/WidgetUpdateBroadcaster.kt" \
    "apps/myanmar_calendar/android/app/src/main/res/layout/widget_layout_compact.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/layout/widget_layout_full_calendar.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/layout/widget_layout_moon_phase.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/layout/widget_layout_myanmar_month.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/xml/compact_widget_info.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/xml/full_calendar_widget_info.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/xml/moon_phase_widget_info.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/xml/myanmar_month_widget_info.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/xml-v31/compact_widget_info.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/xml-v31/full_calendar_widget_info.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/xml-v31/moon_phase_widget_info.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/xml-v31/myanmar_month_widget_info.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/compact.png" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/full_calendar.png" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/moon_phase.png" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/myanmar_month.png" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/widget_background_dark.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/widget_background_light.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/widget_background_traditional.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/widget_background_gradient_blue.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/widget_background_gradient_purple.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/widget_background_gradient_teal.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/widget_bg_compact.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/widget_bg_full.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/widget_bg_moon.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/drawable/widget_bg_calendar.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/values/widget_styles.xml" \
    "apps/myanmar_calendar/android/app/src/main/res/values/strings.xml" \
    "packages/features/home_widgets/lib/src/data/services/widget_update_service.dart"
}

add_ios_icon_targets() {
  add_targets \
    "apps/myanmar_calendar/ios/Runner/AppDelegate.swift" \
    "apps/myanmar_calendar/ios/Runner/Info.plist" \
    "apps/myanmar_calendar/ios/Runner/Assets.xcassets/AppIcon.appiconset" \
    "apps/myanmar_calendar/ios/Runner/Assets.xcassets/AppIconMoon.appiconset" \
    "apps/myanmar_calendar/ios/Runner/Assets.xcassets/AppIconForest.appiconset" \
    "apps/myanmar_calendar/ios/Runner/Assets.xcassets/AppIconMinimalFlat.appiconset" \
    "apps/myanmar_calendar/ios/Runner/Assets.xcassets/AppIconPremiumDark.appiconset" \
    "apps/myanmar_calendar/ios/Runner/Assets.xcassets/AppIconTraditionalMyanmar.appiconset"
}

case "$SCOPE" in
  all)
    add_android_icon_targets
    add_android_widget_targets
    add_ios_icon_targets
    ;;
  android)
    add_android_icon_targets
    add_android_widget_targets
    ;;
  android-icons)
    add_android_icon_targets
    ;;
  android-widgets)
    add_android_widget_targets
    ;;
  ios-icons)
    add_ios_icon_targets
    ;;
  *)
    echo "Unknown scope: $SCOPE"
    usage
    exit 1
    ;;
esac

echo "Restoring native mobile setup from git HEAD (scope: $SCOPE)..."
git -C "$ROOT_DIR" restore --source=HEAD -- "${TARGETS[@]}"

echo "Restored ${#TARGETS[@]} targets."
echo
printf ' - %s\n' "${TARGETS[@]}"

echo
echo "Next steps:"
echo "1) ./scripts/verify_native_mobile_setup.sh --scope $SCOPE"
if [[ "$SCOPE" == "all" || "$SCOPE" == "android" || "$SCOPE" == "android-icons" || "$SCOPE" == "android-widgets" ]]; then
  echo "2) cd apps/myanmar_calendar/android && ./gradlew app:processDebugMainManifest app:processReleaseMainManifest app:compileDebugKotlin"
fi
if [[ "$SCOPE" == "all" || "$SCOPE" == "ios-icons" ]]; then
  echo "3) cd apps/myanmar_calendar/ios && pod install"
fi
