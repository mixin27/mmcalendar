import 'package:flutter/widgets.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The watch's own settings: the calendar language.
///
/// Interface words follow it as on the phone's widgets: Myanmar for
/// Myanmar, English for the other calendar languages.
class WatchSettings {
  WatchSettings(this.preferences, this.language);

  static const languageKey = 'language';

  /// The calendar languages the watch offers. Zawgyi is left out: watch
  /// fonts draw Unicode Myanmar.
  static const languages = [
    Language.myanmar,
    Language.english,
    Language.shan,
    Language.mon,
    Language.karen,
  ];

  static Future<WatchSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return WatchSettings(preferences, languageOf(preferences));
  }

  /// The saved language, or Myanmar.
  static Language languageOf(SharedPreferences preferences) {
    final code = preferences.getString(languageKey);
    return languages.firstWhere(
      (language) => language.code == code,
      orElse: () => Language.myanmar,
    );
  }

  final SharedPreferences preferences;
  Language language;

  Future<void> setLanguage(Language value) async {
    language = value;
    await preferences.setString(languageKey, value.code);
  }

  /// The interface locale for [language].
  static Locale localeFor(Language language) =>
      Locale(language == Language.myanmar ? 'my' : 'en');
}
