import 'package:flutter/widgets.dart';

export 'locale_keys.g.dart';

class L10n {
  static String translationPath = 'assets/translations';

  static List<Locale> all = [en, enUs, my];

  static Locale en = const Locale('en');
  static Locale enUs = const Locale('en', 'US');
  static Locale my = const Locale('my');
}
