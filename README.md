# 🗓️ Myanmar Calendar App

<div align="center">

![Myanmar Calendar Logo](screenshots/myanmar-calendar-featured-graphic.png)

**A modern Myanmar calendar app with calendar views, astrology, events, conversion tools, and printable calendar generation.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.11%2B-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey.svg)](https://flutter.dev/)

[Features](#-features) • [Screenshots](#-screenshots) • [Quick Start](#-quick-start) • [Remote Config](#-remote-config) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

## 📱 Overview

Myanmar Calendar App combines Myanmar calendar data and Western dates in one app experience:

- Home month calendar with rich date details
- Year, week, and day calendar views
- Date conversion and calendar utilities
- Events with recurring support
- Calendar generation (preview/beta) for image/PDF export
- Remote-configurable holiday overrides

Core calculation runtime is powered by [`myanmar_calendar_dart`](https://pub.dev/packages/myanmar_calendar_dart), with app-level settings for language, timezone behavior, and display options.

---

## ✨ Features

### 🗓️ Core Calendar

- Myanmar and Western date rendering in month grid
- Day details with moon phase, sabbath, holidays, and astrological data
- Multiple calendar views:
  - Month (home)
  - Year view
  - Week view
  - Day view
- Fast runtime config updates (language, timezone source, holiday overrides)

### 🌙 Myanmar Date & Astrology

- Myanmar month/day/year and Sasana year
- Fortnight day and moon phase information
- Astrological indicators including:
  - Sabbath / Sabbath Eve
  - Yatyaza
  - Pyatthada / Afternoon Pyatthada
  - Mahabote / Nakhat / Nagahle related outputs

### 🔄 Converter Tools

- Myanmar ↔ Western date conversion
- Date difference calculator
- Date arithmetic tools
- Moon phase finder

### 📌 Events

- Create, edit, and delete events
- Recurring event support
- Day-based event timeline and quick navigation
- Event categories and priority support

### 🖨️ Calendar Generation (Preview/Beta)

- Generate by selected month or full year
- In-app page preview and export flow
- PDF/image export and save/share actions
- Theme/background customization
- Overlay editor support for:
  - Text
  - Emoji
  - Sticker
  - User image
- Layout tools for portrait/landscape and printable formats

> Calendar Generation is currently **preview/beta** and still under active refinement.

### 🎨 Personalization

- Light/dark theme modes
- Multiple theme presets + custom colors
- App language and calendar language controls
- Display toggles (holidays, astrology, Myanmar/Western date visibility, etc.)
- Timezone behavior:
  - Use device timezone (recommended default)
  - Or fixed Myanmar timezone fallback

### ☁️ Remote Config + Onboarding

- Firebase Remote Config driven holiday overrides
- App update prompts from remote config (optional/required update support)
- First-run consent flow for analytics/crash reporting
- Promo carousel for onboarding and new feature announcements

### 📲 Integrations

- Android home widgets (configurable theme/options)
- Telegram web integration hooks
- Local-first storage using SQLite (drift)

---

## 📸 Screenshots

<div align="center">

| Home Month | Day Details | Year View |
|------------|-------------|-----------|
| ![Home Month](screenshots/placeholders/01_home_month.png) | ![Day Details](screenshots/placeholders/02_home_day_details.png) | ![Year View](screenshots/placeholders/03_views_year.png) |

| Week View | Day View | Converter |
|-----------|----------|-----------|
| ![Week View](screenshots/placeholders/04_views_week.png) | ![Day View](screenshots/placeholders/05_views_day.png) | ![Convert](screenshots/placeholders/06_converter_convert.png) |

| Calculator | Arithmetic | Moon Phase |
|------------|------------|------------|
| ![Calculate](screenshots/placeholders/07_converter_calculate.png) | ![Arithmetic](screenshots/placeholders/08_converter_arithmetic.png) | ![Moon Phase](screenshots/placeholders/09_converter_moon_phase.png) |

| Events List | Event Form | Settings |
|-------------|------------|----------|
| ![Events List](screenshots/placeholders/10_events_list.png) | ![Event Form](screenshots/placeholders/11_events_form.png) | ![Settings](screenshots/placeholders/12_settings_overview.png) |

| Generation Preview | Generation Editor | Export Result |
|--------------------|-------------------|---------------|
| ![Generation Preview](screenshots/placeholders/13_generation_preview.png) | ![Generation Editor](screenshots/placeholders/14_generation_editor.png) | ![Export Result](screenshots/placeholders/15_generation_export_result.png) |

| Widget Settings |
|-----------------|
| ![Widget Settings](screenshots/placeholders/16_widget_settings_android.png) |

</div>

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.x
- Dart SDK 3.11+
- Android Studio or VS Code with Flutter tooling
- iOS builds require Xcode (macOS)

### Run Locally

```bash
# Clone
git clone https://github.com/mixin27/mmcalendar.git
cd mmcalendar

# Install workspace dependencies
flutter pub get

# Run mobile app package
cd apps/myanmar_calendar
flutter pub get
flutter run
```

### Run on Chrome (Web)

```bash
cd apps/myanmar_calendar
flutter run -d chrome
```

### Production Builds

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

---

## ☁️ Remote Config

### Holidays Config (required for holiday override feature)

- **Key**: `holidays_config_v2`
- **Type**: JSON string

Sample payload:

```json
{
  "customHolidayRules": [
    {
      "id": "team_founding_day",
      "name": "Team Founding Day",
      "type": "other",
      "localizedNames": {
        "my": "အသင်းတည်ထောင်နေ့",
        "en": "Team Founding Day"
      },
      "rule": {
        "kind": "westernDate",
        "month": 9,
        "day": 1
      },
      "cacheKey": "team_founding_day",
      "cacheVersion": 1
    },
    {
      "id": "thingyan_special",
      "name": "Thingyan Special",
      "type": "other",
      "rule": {
        "kind": "myanmarDate",
        "month": 1,
        "day": 1
      }
    }
  ],
  "disabledHolidays": ["halloween"],
  "disabledHolidaysByYear": {
    "2027": ["valentinesDay"]
  },
  "disabledHolidaysByDate": {
    "2026-10-31": ["halloween"]
  }
}
```

Reference:
- Holiday IDs: [holiday_id.dart](https://github.com/mixin27/myanmar_calendar_dart/blob/main/lib/src/models/holiday_id.dart)

### App Update Config (optional)

If you enable remote-config update checks, these keys are used:

- `app_update_enabled` (`bool`)
- `app_update_latest_build_number` (`int`)
- `app_update_latest_version` (`string`)
- `app_update_min_supported_build_number` (`int`)
- `app_update_force_title` (`string`)
- `app_update_force_message` (`string`)
- `app_update_optional_title` (`string`)
- `app_update_optional_message` (`string`)
- `app_update_release_notes` (`string`)
- `app_update_android_url` (`string`)
- `app_update_ios_url` (`string`)
- `app_update_web_url` (`string`)

---

## 🏗️ Architecture

This repository is a Flutter workspace with feature packages and shared layers.

```text
mmcalendar/
├── apps/
│   └── myanmar_calendar/          # Main app
├── packages/
│   ├── shared/
│   │   ├── core/                  # Contracts, ports, constants, runtime utils
│   │   ├── localizations/         # i18n resources
│   │   ├── ui_kit/                # Shared UI building blocks
│   │   └── overlay_editor/        # Overlay editing package
│   ├── features/
│   │   ├── calendar/
│   │   ├── views/
│   │   ├── converter/
│   │   ├── events/
│   │   ├── settings/
│   │   ├── calendar_generation/
│   │   ├── promo/
│   │   ├── holidays/
│   │   └── home_widgets/
│   └── integrations/
│       ├── database/              # Drift/SQLite
│       ├── firebase/              # Remote config + analytics/crash adapters
│       ├── app_update/
│       └── telegram_web/
└── scripts/
```

### Stack

- Flutter + Dart
- `flutter_bloc` (state management)
- `go_router` (navigation)
- `drift` (local database)
- `get_it` + `injectable` (dependency injection)
- `myanmar_calendar_dart` (calendar engine)

---

## 🤝 Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

### Development Commands

```bash
# Workspace dependencies
flutter pub get

# Codegen (from workspace root)
dart run build_runner build --delete-conflicting-outputs

# Analyze
flutter analyze
```

---

## 📝 License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

---

## 🙏 Acknowledgments

- Myanmar calendar calculations based on [Yan Naing Aye's algorithm](http://cool-emerald.blogspot.com/2013/06/algorithm-program-and-calculation-of.html)
- Traditional Myanmar astrology sources and community feedback
- Flutter and open-source ecosystem contributors

---

## 📞 Support

- Email: [kyawzayartun.contact@gmail.com](mailto:kyawzayartun.contact@gmail.com)
- Issues: [GitHub Issues](https://github.com/mixin27/mmcalendar/issues)

---

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=mixin27/mmcalendar&type=Date)](https://star-history.com/#mixin27/mmcalendar&Date)

---

<div align="center">

**Made for the Myanmar calendar community**

[⬆ Back to Top](#-myanmar-calendar-app)

</div>
