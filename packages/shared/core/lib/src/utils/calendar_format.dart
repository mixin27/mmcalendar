import 'package:flutter/widgets.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import 'translate_numbers.dart';

/// Calendar data in the calendar language: Gregorian month and weekday
/// names, dates and numbers, and Myanmar dates. Interface words (Today,
/// Events, buttons) come from the app's localizations instead.
class CalendarFormat {
  const CalendarFormat(this.language, {this.englishWesternDates = false});

  final Language language;

  /// Western dates in English, month names and digits (Settings › English
  /// for Western dates); Myanmar dates, weekdays and other numbers keep the
  /// language's.
  final bool englishWesternDates;

  /// The format for the calendar language in [context]
  /// (see [CalendarLanguageScope]).
  factory CalendarFormat.of(BuildContext context) => CalendarFormat(
    CalendarLanguageScope.of(context),
    englishWesternDates: CalendarLanguageScope.englishWesternDatesOf(context),
  );

  /// The language for Western month names: English with
  /// [englishWesternDates].
  Language get _westernLanguage =>
      englishWesternDates ? Language.english : language;

  /// "October" / "အောက်တိုဘာ".
  String month(int month) =>
      TranslationService.getWesternMonthName(month, _westernLanguage);

  /// "Oct" / "အောက်".
  String shortMonth(int month) =>
      TranslationService.getShortWesternMonthName(month, _westernLanguage);

  /// [value] in the language's digits ("၂၀၂၆" in Myanmar).
  String number(int value) => translateNumbers('$value', language: language);

  /// A Western day or year: [number], or English digits with
  /// [englishWesternDates].
  String westernNumber(int value) =>
      englishWesternDates ? '$value' : number(value);

  /// "October 2026".
  String monthYear(DateTime date) =>
      '${month(date.month)} ${westernNumber(date.year)}';

  /// "Oct 2026", for narrow titles.
  String shortMonthYear(DateTime date) =>
      '${shortMonth(date.month)} ${westernNumber(date.year)}';

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
      '${weekday(date, short: true)} ${westernNumber(date.day)} '
      '${shortMonth(date.month)}';

  /// "22 Oct".
  String dayMonth(DateTime date) =>
      '${westernNumber(date.day)} ${shortMonth(date.month)}';

  /// "Thursday 22 October 2026".
  String fullDate(DateTime date) =>
      '${weekday(date)} ${westernNumber(date.day)} ${month(date.month)} '
      '${westernNumber(date.year)}';

  /// A Myanmar date with a `formatMyanmar` [pattern]. With
  /// [preferShanYear] a Shan calendar shows the Shan year
  /// (see [formatMyanmarDate]).
  String myanmar(
    MyanmarDate date,
    String pattern, {
    bool preferShanYear = false,
  }) => formatMyanmarDate(
    date,
    pattern: pattern,
    language: language,
    preferShanYear: preferShanYear,
  );

  /// A package translation key ("Full Moon", holiday names) in the language.
  String translate(String key) => TranslationService.translateTo(key, language);
}

/// Whether years show as Shan years: the calendar language is Shan and
/// Settings › Prefer Shan Year ([preferShanYear]) is on.
bool showsShanYear(Language language, {required bool preferShanYear}) =>
    language == Language.shan && preferShanYear;

/// [date] in a `formatMyanmar` [pattern] (the package default when null).
/// When [showsShanYear], its year (`&y`, `&yyyy`) is the Shan year in Shan
/// digits instead of the Myanmar year.
String formatMyanmarDate(
  MyanmarDate date, {
  String? pattern,
  required Language language,
  bool preferShanYear = false,
}) {
  var effective = pattern ?? '&y &M &P &ff';
  if (showsShanYear(language, preferShanYear: preferShanYear)) {
    final shanYear = MyanmarDateTime.fromMyanmarDate(date).shanYear;
    final year = translateNumbers('$shanYear', language: Language.shan);
    effective = effective.replaceAll('&yyyy', year).replaceAll('&y', year);
  }
  return MyanmarCalendar.formatMyanmar(
    date,
    pattern: effective,
    language: language,
  );
}

/// Hands the calendar language down the tree, so calendar data never
/// depends on the app (interface) language or on global state.
class CalendarLanguageScope extends InheritedWidget {
  const CalendarLanguageScope({
    super.key,
    required this.language,
    this.englishWesternDates = false,
    required super.child,
  });

  final Language language;

  /// See [CalendarFormat.englishWesternDates].
  final bool englishWesternDates;

  /// The nearest scope's language, else the configured global default.
  static Language of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CalendarLanguageScope>()
          ?.language ??
      MyanmarCalendar.currentLanguage;

  /// The nearest scope's [englishWesternDates], else false.
  static bool englishWesternDatesOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CalendarLanguageScope>()
          ?.englishWesternDates ??
      false;

  @override
  bool updateShouldNotify(CalendarLanguageScope oldWidget) =>
      language != oldWidget.language ||
      englishWesternDates != oldWidget.englishWesternDates;
}

extension CalendarLanguageContext on BuildContext {
  Language get calendarLanguage => CalendarLanguageScope.of(this);
  CalendarFormat get calendarFormat => CalendarFormat.of(this);
}
