import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// Labels for calendar facts in the calendar language, so "Sasana Year"
/// reads "သာသနာနှစ်" beside a Myanmar value.
///
/// Words come from myanmar_calendar_dart. The few it lacks are written out
/// for English and Myanmar; other calendar languages fall back to the
/// app's own label rather than show a word in the wrong script.
abstract final class CalendarLabels {
  /// Keys myanmar_calendar_dart has no word for.
  static const _own = <String, Map<Language, String>>{
    'Month': {Language.english: 'Month', Language.myanmar: 'လ'},
    'Year Type': {Language.english: 'Type', Language.myanmar: 'နှစ်အမျိုးအစား'},
    'Buddhist Era': {
      Language.english: 'Buddhist Era (BE)',
      Language.myanmar: 'ဗုဒ္ဓသက္ကရာဇ်',
    },
    'Myanmar Era': {
      Language.english: 'Myanmar Era (ME)',
      Language.myanmar: 'မြန်မာသက္ကရာဇ်',
    },
    'Eras': {
      Language.english: 'Buddhist calendar',
      Language.myanmar: 'သက္ကရာဇ်များ',
    },
  };

  /// The label for [key] in [language], or [fallback] (the app's label)
  /// when there is no word for it in that language.
  static String of(String key, Language language, String fallback) {
    final own = _own[key]?[language];
    if (own != null) return own;
    if (_own.containsKey(key)) return fallback;
    return TranslationService.hasTranslation(key, language)
        ? TranslationService.translateTo(key, language)
        : fallback;
  }

  /// The Myanmar day of the month: "ရက်" rather than "နေ့" (a weekday).
  static String day(Language language, String fallback) =>
      language == Language.english ? 'Day' : of('Yat', language, fallback);
}
