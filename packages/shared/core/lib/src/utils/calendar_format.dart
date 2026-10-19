import 'package:flutter/widgets.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import 'translate_numbers.dart';

/// Calendar data in the calendar language: Gregorian month and weekday
/// names, dates and numbers, and Myanmar dates. Interface words (Today,
/// Events, buttons) come from the app's localizations instead.
class CalendarFormat {
  const CalendarFormat(this.language);

  final Language language;

  /// The format for the calendar language in [context]
  /// (see [CalendarLanguageScope]).
  factory CalendarFormat.of(BuildContext context) =>
      CalendarFormat(CalendarLanguageScope.of(context));

  /// "October" / "အောက်တိုဘာ".
  String month(int month) =>
      TranslationService.getWesternMonthName(month, language);

  /// "Oct" / "အောက်".
  String shortMonth(int month) =>
      TranslationService.getShortWesternMonthName(month, language);

  /// [value] in the language's digits ("၂၀၂၆" in Myanmar).
  String number(int value) => translateNumbers('$value', language: language);

  /// "October 2026".
  String monthYear(DateTime date) =>
      '${month(date.month)} ${number(date.year)}';

  /// "Oct 2026", for narrow titles.
  String shortMonthYear(DateTime date) =>
      '${shortMonth(date.month)} ${number(date.year)}';

  /// "Thursday", or "Thu" when [short].
  String weekday(DateTime date, {bool short = false}) =>
      weekdayOf(date.weekday, short: short);

  /// [weekday] as [DateTime.weekday] (Monday 1 … Sunday 7).
  String weekdayOf(int weekday, {bool short = false}) {
    // The package counts from Saturday (0).
    final index = (weekday + 1) % 7;
    return short
        ? TranslationService.getShortWeekdayName(index, language)
        : TranslationService.getWeekdayName(index, language);
  }

  /// "Thu 22 Oct".
  String shortDate(DateTime date) =>
      '${weekday(date, short: true)} ${number(date.day)} '
      '${shortMonth(date.month)}';

  /// "22 Oct".
  String dayMonth(DateTime date) =>
      '${number(date.day)} ${shortMonth(date.month)}';

  /// "Thursday 22 October 2026".
  String fullDate(DateTime date) =>
      '${weekday(date)} ${number(date.day)} ${month(date.month)} '
      '${number(date.year)}';

  /// A Myanmar date with a `formatMyanmar` [pattern].
  String myanmar(MyanmarDate date, String pattern) =>
      MyanmarCalendar.formatMyanmar(date, pattern: pattern, language: language);

  /// A package translation key ("Full Moon", holiday names) in the language.
  String translate(String key) => TranslationService.translateTo(key, language);
}

/// Hands the calendar language down the tree, so calendar data never
/// depends on the app (interface) language or on global state.
class CalendarLanguageScope extends InheritedWidget {
  const CalendarLanguageScope({
    super.key,
    required this.language,
    required super.child,
  });

  final Language language;

  /// The nearest scope's language, else the configured global default.
  static Language of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CalendarLanguageScope>()
          ?.language ??
      MyanmarCalendar.currentLanguage;

  @override
  bool updateShouldNotify(CalendarLanguageScope oldWidget) =>
      language != oldWidget.language;
}

extension CalendarLanguageContext on BuildContext {
  Language get calendarLanguage => CalendarLanguageScope.of(this);
  CalendarFormat get calendarFormat => CalendarFormat.of(this);
}
