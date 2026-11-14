# Myanmar Calendar for Wear OS

A standalone Wear OS app (Wear OS 3+, minSdk 30) with the same calendar as
the phone app: `myanmar_calendar_dart`, the holiday catalog
(`HolidayYears` in `packages/features/holidays`), the good-day rule
(`GoodDays`) and `shared_localizations`.

- **App:** the Apple Watch app's layout. Vertical pages for today and the
  next six days (the moon, the Myanmar date, the Western date, Sabbath and
  holidays), then **Coming up** (the next holidays, Sabbath days and moons,
  from the Tile's payload) with the calendar language button (Myanmar,
  English, Shan, Mon, Karen). Tap a day for its astrology. Interface words
  are Myanmar for Myanmar and English otherwise. Ambient mode shows today
  dimmed.
- **Tile:** today's Myanmar date, the moon phase and the next holiday or
  Sabbath.
- **Complication:** `SHORT_TEXT` (moon and day of the fortnight),
  `LONG_TEXT` (Myanmar date) and `RANGED_VALUE` (moon illumination).

## How the Tile and complication get their data

No Kotlin converts dates. On launch, on a language change and once a day
(Workmanager), Dart writes `WidgetPayloadBuilder.buildSlim` from
`packages/shared/widget_payload` — 90 `days`, the words (`s`) and what's
`upcoming` — to SharedPreferences (`flutter.watch_payload` in
`FlutterSharedPreferences`). `WatchApplication` asks the Tile and
complications to redraw when it changes. Both carry the next days in a
timeline, so they turn over at midnight on their own; an inexact midnight
alarm (re-armed on boot, clock and time-zone changes) is the backstop.

## Versions

The app id is the phone's, `dev.mixin27.mmcalendar`, so Play serves it from
the same listing. The build number is `1_000_000 +` the phone's build
number (phone `2.6.0+260` → watch `2.6.0+1000260`); raise both together.

## Run

```bash
flutter run -d <wear-emulator>
```

Release builds use `android/key.properties` (or the `ANDROID_KEYSTORE_*`
environment variables) and fall back to the debug key without them.
