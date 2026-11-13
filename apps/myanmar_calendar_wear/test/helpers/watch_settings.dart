import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_wear/settings/watch_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings over in-memory preferences.
Future<WatchSettings> testSettings({
  Language language = Language.english,
}) async {
  SharedPreferences.setMockInitialValues({
    WatchSettings.languageKey: language.code,
  });
  return WatchSettings.load();
}
