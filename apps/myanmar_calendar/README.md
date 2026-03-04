# Myanmar Calendar App (`apps/myanmar_calendar`)

Main Flutter application package for the Myanmar Calendar workspace.

## Overview

This app provides:

- Myanmar + Western calendar views (month/year/week/day)
- Astrology and holiday details
- Date converter tools
- Events with recurring support
- Calendar generation/export flow (preview/beta)
- Settings, theme/language controls, and remote-config driven behaviors

Core calendar runtime is powered by `myanmar_calendar_dart`.

## Workspace Context

This package depends on workspace feature/shared/integration packages under:

- `packages/features/*`
- `packages/shared/*`
- `packages/integrations/*`

Use the root README for full project-level documentation:
- `../../README.md`

## Prerequisites

- Flutter 3.x
- Dart 3.11+
- Android Studio / VS Code with Flutter tooling
- Xcode for iOS builds (macOS)

## Run

From repository root:

```bash
flutter pub get
cd apps/myanmar_calendar
flutter pub get
flutter run
```

Run on Chrome:

```bash
cd apps/myanmar_calendar
flutter run -d chrome
```

## Build

```bash
cd apps/myanmar_calendar

# Android
flutter build apk --release
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release

# Web
flutter build web --release
```

## Remote Config Keys

Holiday overrides:

- `holidays_config_v2` (JSON string)

App update (optional):

- `app_update_enabled`
- `app_update_latest_build_number`
- `app_update_latest_version`
- `app_update_min_supported_build_number`
- `app_update_force_title`
- `app_update_force_message`
- `app_update_optional_title`
- `app_update_optional_message`
- `app_update_release_notes`
- `app_update_android_url`
- `app_update_ios_url`
- `app_update_web_url`

## Notes

- Calendar Generation is currently **preview/beta** and still being refined.
- On first launch, consent flow is shown before onboarding/feature promo carousel.
- Dynamic app icon switching is supported on Android and iOS (real device).
- iOS Simulator may not reliably switch alternate icons (`NSPOSIXErrorDomain code=35`); prefer physical iPhone or cloud real-device testing.
- If Android/iOS platform folders are regenerated, restore native integrations with:
  - `../../scripts/restore_native_mobile_setup.sh --scope all`
  - `../../scripts/verify_native_mobile_setup.sh --scope all`
  - See: `../../docs/architecture/native_mobile_setup.md`
- App changelog is maintained at workspace root: `../../CHANGELOG.md`.
