# Native Mobile Setup Recovery

This app intentionally keeps some platform-native setup for features that cannot be fully done in pure Dart:

- Android dynamic app icon switching (activity-alias launcher setup)
- Android home widgets (AppWidget providers, receivers, native layouts/resources)
- iOS alternate app icons (`UIApplication.setAlternateIconName`)
- The Apple Watch app and its complications (see below)

To reduce maintenance risk when recreating platform folders, use the scripts below.

## Scripts

- Verify setup:
  - `./scripts/verify_native_mobile_setup.sh --scope all`
- Restore setup from current git `HEAD`:
  - `./scripts/restore_native_mobile_setup.sh --scope all`

Supported scopes:

- `all`
- `android`
- `android-icons`
- `android-widgets`
- `ios-icons`
- `ios-watch`

Backward-compatible wrappers:

- `./scripts/verify_android_icon_setup.sh`
- `./scripts/restore_android_icon_setup.sh`

## Recreate Platform Safely

If you recreate Android/iOS platform files (for example, using `flutter create`), run:

```bash
./scripts/restore_native_mobile_setup.sh --scope all
./scripts/verify_native_mobile_setup.sh --scope all
```

Then run build checks:

```bash
cd apps/myanmar_calendar/android
./gradlew app:processDebugMainManifest app:processReleaseMainManifest app:compileDebugKotlin app:processDebugResources

cd ../ios
pod install
```

## Apple Watch

The watch app shows the same data as the iPhone widgets: the 180-day `widget_data_v2` payload that `WidgetPayloadBuilder` writes. Nothing on the watch computes calendar dates.

| Part | Where | Bundle id |
|---|---|---|
| Watch app (SwiftUI, watchOS 10) | `ios/MyanmarCalendarWatch/` | `dev.mixin27.mmcalendar.watchkitapp` |
| Complications (WidgetKit) | `ios/MyanmarCalendarWatchWidgets/` | `dev.mixin27.mmcalendar.watchkitapp.widgets` |
| Swift shared with the iPhone widgets | `ios/WidgetShared/` | — |
| iPhone side of WatchConnectivity | `ios/Runner/WatchSync.swift` | — |

How the data gets there:
1. Flutter saves the payload to the app group and calls `dev.mixin27.mmcalendar/watch` › `sync` (`WidgetUpdateService.syncWatch`).
2. `WatchSync` sends it to the watch as a file. It also sends it when the session starts, when the watch app is installed, and when the watch asks.
3. The watch app saves it to its own app group under the same key, so `PayloadStore.load()` works unchanged, and reloads the complications.
4. If the watch's data is missing or a week old, it asks the iPhone, which wakes the iPhone app in the background.

The targets were added with `ruby scripts/ios/add_watch_targets.rb` (the `xcodeproj` gem). The folders are Xcode synchronized folders, so new Swift files in them join their target without editing the project.

Building:
- Every iOS build now needs the watchOS platform in Xcode (Xcode › Settings › Components, or `xcodebuild -downloadPlatform watchOS`).
- Release builds need two more provisioning profiles, "MyanmarCalendar Watch Production Profile" and "MyanmarCalendar Watch Widgets Production Profile", for the bundle ids above with the `group.dev.mixin27.mmcalendar` App Group.

## One-Time Android Launcher Cleanup

If older debug installs left stale launcher entries while testing icon switching:

```bash
adb uninstall dev.mixin27.mmcalendar
```

Then run the app again.

## Notes

- Android launcher aliases are required for runtime icon switching.
- Flutter tooling still requires `MAIN + LAUNCHER` on `<activity>` in `src/main/AndroidManifest.xml`, and build-variant manifests remove it at merge-time.
- iOS icon switching can fail on simulator due LaunchServices token/resource issues; validate on real device when possible.
