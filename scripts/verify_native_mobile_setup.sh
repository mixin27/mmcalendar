#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCOPE="all"

usage() {
  cat <<'EOF'
Usage: ./scripts/verify_native_mobile_setup.sh [--scope <scope>]

Scopes:
  all              Verify Android app icons + Android home widgets + iOS app icons
  android          Verify Android app icons + Android home widgets
  android-icons    Verify Android app icon setup only
  android-widgets  Verify Android home widget setup only
  ios-icons        Verify iOS app icon setup only
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

require_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "ERROR: Missing file: $file"
    exit 1
  fi
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local hint="$3"
  if ! grep -qE "$pattern" "$file"; then
    echo "ERROR: Check failed: $hint"
    echo "  File: $file"
    exit 1
  fi
}

verify_android_icons() {
  local main_manifest="$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/AndroidManifest.xml"
  local debug_manifest="$ROOT_DIR/apps/myanmar_calendar/android/app/src/debug/AndroidManifest.xml"
  local profile_manifest="$ROOT_DIR/apps/myanmar_calendar/android/app/src/profile/AndroidManifest.xml"
  local release_manifest="$ROOT_DIR/apps/myanmar_calendar/android/app/src/release/AndroidManifest.xml"
  local main_activity="$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/MainActivity.kt"

  require_file "$main_manifest"
  require_file "$debug_manifest"
  require_file "$profile_manifest"
  require_file "$release_manifest"
  require_file "$main_activity"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_moon.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_forest.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_minimal_flat.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_premium_dark.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_traditional_myanmar.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/values/ic_launcher_background.xml"

  require_pattern "$main_manifest" 'android:name="\.MainActivity"' "MainActivity declaration in main manifest"
  require_pattern "$main_manifest" 'android.intent.action.MAIN' "MAIN action present in main manifest (Flutter tooling parser)"
  require_pattern "$main_manifest" 'android.intent.category.LAUNCHER' "LAUNCHER category present in main manifest (Flutter tooling parser)"
  require_pattern "$main_manifest" 'android:name="\.MainActivityDefault"' "Default alias exists"
  require_pattern "$main_manifest" 'android:name="\.MainActivityMoon"' "Moon alias exists"
  require_pattern "$main_manifest" 'android:name="\.MainActivityForest"' "Forest alias exists"
  require_pattern "$main_manifest" 'android:name="\.MainActivityMinimalFlat"' "Minimal Flat alias exists"
  require_pattern "$main_manifest" 'android:name="\.MainActivityPremiumDark"' "Premium Dark alias exists"
  require_pattern "$main_manifest" 'android:name="\.MainActivityTraditionalMyanmar"' "Traditional Myanmar alias exists"

  require_pattern "$debug_manifest" 'tools:node="remove"' "Debug manifest removes MainActivity launcher filter at merge-time"
  require_pattern "$profile_manifest" 'tools:node="remove"' "Profile manifest removes MainActivity launcher filter at merge-time"
  require_pattern "$release_manifest" 'tools:node="remove"' "Release manifest removes MainActivity launcher filter at merge-time"

  require_pattern "$main_activity" 'APP_ICON_CHANNEL = "dev\.mixin27\.mmcalendar/app_icon"' "MainActivity app icon channel exists"
  require_pattern "$main_activity" 'launcherAliases = mapOf\(' "MainActivity has launcher alias map"
  require_pattern "$main_activity" '"default" to "dev\.mixin27\.mmcalendar\.MainActivityDefault"' "Default alias mapping exists"
  require_pattern "$main_activity" 'setLauncherIcon\(' "MainActivity includes icon switch method"
  require_pattern "$main_activity" 'getCurrentIconId\(' "MainActivity includes current icon method"

  echo "OK: Android app icon setup looks valid."
}

verify_android_widgets() {
  local main_manifest="$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/AndroidManifest.xml"
  local compact_provider="$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/CompactDateWidgetProvider.kt"
  local full_provider="$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/FullCalendarWidgetProvider.kt"
  local moon_provider="$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/MoonPhaseWidgetProvider.kt"
  local month_provider="$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/MyanmarMonthWidgetProvider.kt"
  local boot_receiver="$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/WidgetBootReceiver.kt"
  local date_receiver="$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/WidgetDateChangeReceiver.kt"
  local timeline_resolver="$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/WidgetTimelineResolver.kt"
  local update_broadcaster="$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/kotlin/dev/mixin27/mmcalendar/WidgetUpdateBroadcaster.kt"
  local update_service="$ROOT_DIR/packages/features/home_widgets/lib/src/data/services/widget_update_service.dart"

  require_file "$main_manifest"
  require_file "$compact_provider"
  require_file "$full_provider"
  require_file "$moon_provider"
  require_file "$month_provider"
  require_file "$boot_receiver"
  require_file "$date_receiver"
  require_file "$timeline_resolver"
  require_file "$update_broadcaster"
  require_file "$update_service"

  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/layout/widget_layout_compact.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/layout/widget_layout_full_calendar.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/layout/widget_layout_moon_phase.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/layout/widget_layout_myanmar_month.xml"

  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/xml/compact_widget_info.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/xml/full_calendar_widget_info.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/xml/moon_phase_widget_info.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/xml/myanmar_month_widget_info.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/xml-v31/compact_widget_info.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/xml-v31/full_calendar_widget_info.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/xml-v31/moon_phase_widget_info.xml"
  require_file "$ROOT_DIR/apps/myanmar_calendar/android/app/src/main/res/xml-v31/myanmar_month_widget_info.xml"

  require_pattern "$main_manifest" 'android:name="\.CompactDateWidgetProvider"' "Compact widget receiver is registered"
  require_pattern "$main_manifest" 'android:name="\.FullCalendarWidgetProvider"' "Full calendar widget receiver is registered"
  require_pattern "$main_manifest" 'android:name="\.MoonPhaseWidgetProvider"' "Moon phase widget receiver is registered"
  require_pattern "$main_manifest" 'android:name="\.MyanmarMonthWidgetProvider"' "Myanmar month widget receiver is registered"
  require_pattern "$main_manifest" 'android:name="\.WidgetBootReceiver"' "Widget boot receiver is registered"
  require_pattern "$main_manifest" 'android:name="\.WidgetDateChangeReceiver"' "Widget date-change receiver is registered"

  require_pattern "$compact_provider" 'class CompactDateWidgetProvider : HomeWidgetProvider\(\)' "Compact widget provider extends HomeWidgetProvider"
  require_pattern "$full_provider" 'class FullCalendarWidgetProvider : HomeWidgetProvider\(\)' "Full calendar widget provider extends HomeWidgetProvider"
  require_pattern "$moon_provider" 'class MoonPhaseWidgetProvider : HomeWidgetProvider\(\)' "Moon phase widget provider extends HomeWidgetProvider"
  require_pattern "$month_provider" 'class MyanmarMonthWidgetProvider : HomeWidgetProvider\(\)' "Myanmar month widget provider extends HomeWidgetProvider"

  require_pattern "$update_service" "androidName: 'CompactDateWidgetProvider'" "Dart update service targets compact provider"
  require_pattern "$update_service" "androidName: 'FullCalendarWidgetProvider'" "Dart update service targets full calendar provider"
  require_pattern "$update_service" "androidName: 'MoonPhaseWidgetProvider'" "Dart update service targets moon phase provider"
  require_pattern "$update_service" "androidName: 'MyanmarMonthWidgetProvider'" "Dart update service targets month provider"

  echo "OK: Android home widget setup looks valid."
}

verify_ios_icons() {
  local app_delegate="$ROOT_DIR/apps/myanmar_calendar/ios/Runner/AppDelegate.swift"
  local info_plist="$ROOT_DIR/apps/myanmar_calendar/ios/Runner/Info.plist"

  require_file "$app_delegate"
  require_file "$info_plist"
  require_file "$ROOT_DIR/apps/myanmar_calendar/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
  require_file "$ROOT_DIR/apps/myanmar_calendar/ios/Runner/Assets.xcassets/AppIconMoon.appiconset/Contents.json"
  require_file "$ROOT_DIR/apps/myanmar_calendar/ios/Runner/Assets.xcassets/AppIconForest.appiconset/Contents.json"
  require_file "$ROOT_DIR/apps/myanmar_calendar/ios/Runner/Assets.xcassets/AppIconMinimalFlat.appiconset/Contents.json"
  require_file "$ROOT_DIR/apps/myanmar_calendar/ios/Runner/Assets.xcassets/AppIconPremiumDark.appiconset/Contents.json"
  require_file "$ROOT_DIR/apps/myanmar_calendar/ios/Runner/Assets.xcassets/AppIconTraditionalMyanmar.appiconset/Contents.json"

  require_pattern "$app_delegate" 'appIconChannelName = "dev\.mixin27\.mmcalendar/app_icon"' "iOS app icon channel is configured"
  require_pattern "$app_delegate" 'case "moon":' "iOS moon icon mapping exists"
  require_pattern "$app_delegate" 'case "forest":' "iOS forest icon mapping exists"
  require_pattern "$app_delegate" 'case "minimal_flat":' "iOS minimal flat icon mapping exists"
  require_pattern "$app_delegate" 'case "premium_dark":' "iOS premium dark icon mapping exists"
  require_pattern "$app_delegate" 'case "traditional_myanmar":' "iOS traditional Myanmar icon mapping exists"
  require_pattern "$app_delegate" 'setAlternateIconName' "iOS setAlternateIconName usage exists"

  require_pattern "$info_plist" '<key>CFBundleAlternateIcons</key>' "Info.plist contains alternate icon declaration"
  require_pattern "$info_plist" '<key>AppIconMoon</key>' "Info.plist contains AppIconMoon"
  require_pattern "$info_plist" '<key>AppIconForest</key>' "Info.plist contains AppIconForest"
  require_pattern "$info_plist" '<key>AppIconMinimalFlat</key>' "Info.plist contains AppIconMinimalFlat"
  require_pattern "$info_plist" '<key>AppIconPremiumDark</key>' "Info.plist contains AppIconPremiumDark"
  require_pattern "$info_plist" '<key>AppIconTraditionalMyanmar</key>' "Info.plist contains AppIconTraditionalMyanmar"

  echo "OK: iOS app icon setup looks valid."
}

case "$SCOPE" in
  all)
    verify_android_icons
    verify_android_widgets
    verify_ios_icons
    ;;
  android)
    verify_android_icons
    verify_android_widgets
    ;;
  android-icons)
    verify_android_icons
    ;;
  android-widgets)
    verify_android_widgets
    ;;
  ios-icons)
    verify_ios_icons
    ;;
  *)
    echo "Unknown scope: $SCOPE"
    usage
    exit 1
    ;;
esac

echo
echo "OK: Native mobile setup verification passed (scope: $SCOPE)."
echo
echo "Recommended build checks:"
if [[ "$SCOPE" == "all" || "$SCOPE" == "android" || "$SCOPE" == "android-icons" || "$SCOPE" == "android-widgets" ]]; then
  echo "- cd apps/myanmar_calendar/android && ./gradlew app:processDebugMainManifest app:processReleaseMainManifest app:compileDebugKotlin app:processDebugResources"
fi
if [[ "$SCOPE" == "all" || "$SCOPE" == "ios-icons" ]]; then
  echo "- cd apps/myanmar_calendar/ios && pod install"
fi
