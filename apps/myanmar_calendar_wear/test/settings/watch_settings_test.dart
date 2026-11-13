import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_wear/settings/watch_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults to Myanmar and remembers the choice', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await WatchSettings.load();
    expect(settings.language, Language.myanmar);

    await settings.setLanguage(Language.shan);
    expect((await WatchSettings.load()).language, Language.shan);
  });

  test('an unknown saved code falls back to Myanmar', () async {
    SharedPreferences.setMockInitialValues({'language': 'zawgyi'});
    expect((await WatchSettings.load()).language, Language.myanmar);
  });

  test('interface words are Myanmar only for Myanmar', () {
    expect(WatchSettings.localeFor(Language.myanmar), const Locale('my'));
    for (final language in [Language.english, Language.shan, Language.mon]) {
      expect(WatchSettings.localeFor(language), const Locale('en'));
    }
  });
}
