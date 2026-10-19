import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// Astrological values said the way people say them, e.g. "ဘင်္ဂဖွား"
/// rather than "ဘင်္ဂ", in the calendar language.
///
/// The words come from myanmar_calendar_dart; the phrasing is written out
/// for English and Myanmar. Other languages put the core's word for the
/// kind after the value ("ဘဒြ နှစ်"), the order Myanmar script uses.
abstract final class AstroPhrases {
  static String _t(String key, Language language) =>
      TranslationService.translateTo(key, language);

  /// A day mark such as Sabbath or Thamanyo, said as a day in Myanmar,
  /// e.g. "ဥပုသ် နေ့"; names that already say "ရက်" (ရက်ရာဇာ) stay as they
  /// are.
  static String mark(String key, Language language) {
    final name = _t(key, language);
    if (language != Language.myanmar || name.contains('ရက်')) return name;
    return '$name နေ့';
  }

  /// Where the dragon's head turns, e.g. "နဂါးခေါင်း တောင်ဘက်သို့ လှည့်".
  static String nagahle(String direction, Language language) {
    final dir = _t(direction, language);
    return switch (language) {
      Language.english => 'Naga head faces $dir',
      Language.myanmar => 'နဂါးခေါင်း $dirဘက်သို့ လှည့်',
      _ => '${_t('Naga Head', language)} $dir',
    };
  }

  /// The Mahabote birth house, e.g. "ဘင်္ဂဖွား".
  static String mahabote(String house, Language language) {
    final value = _t(house, language);
    return switch (language) {
      Language.english => 'Born in $value',
      Language.myanmar => '$valueဖွား',
      _ => '$value ${_t('Born', language)}',
    };
  }

  /// The Nakhat, e.g. "လူ နက္ခတ်".
  static String nakhat(String nakhat, Language language) {
    final value = _t(nakhat, language);
    return switch (language) {
      Language.english => '$value nakhat',
      _ => '$value ${_t('Nakhat', language)}',
    };
  }

  /// The year's name in the 12-year cycle, e.g. "ဘဒြ နှစ်".
  static String yearName(String name, Language language) {
    final value = _t(name, language);
    return switch (language) {
      Language.english => '$value year',
      _ => '$value ${_t('Year', language)}',
    };
  }
}
