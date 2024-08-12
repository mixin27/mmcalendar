# Myanmar Calendar

The Myanmar Calendar app is a beautifully designed tool that brings the traditional Myanmar calendar to your fingertips. Built with Flutter, this app offers a seamless experience across devices, ensuring you stay connected with Myanmar’s rich cultural heritage.

## Libraries

- [flutter_mmcalendar](https://pub.dev/packages/flutter_mmcalendar)
- [table_calendar](https://pub.dev/packages/table_calendar)

## Project Setup

To clone the repo for the first time

```bash
git clone https://github.com/mixin27/mmcalendar.git
cd mmcalendar/
flutter packages get
```

Generate `build_runner` and `easy_localization`

```bash
# build_runner
dart run build_runner build

# easy_localization
dart run easy_localization:generate -S assets/translations -O lib/src/l10n -o locale_keys.g.dart -f keys
```

You will need to create firebase project to configure firebase

```bash
flutterfire configure
```

Go to onesignal, login or create an account and create an app. Then copy onesignalAppId and paste to `.env` file.
