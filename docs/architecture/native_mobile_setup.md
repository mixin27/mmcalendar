# Native Mobile Setup Recovery

This app intentionally keeps some platform-native setup for features that cannot be fully done in pure Dart:

- Android dynamic app icon switching (activity-alias launcher setup)
- Android home widgets (AppWidget providers, receivers, native layouts/resources)
- iOS alternate app icons (`UIApplication.setAlternateIconName`)

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
