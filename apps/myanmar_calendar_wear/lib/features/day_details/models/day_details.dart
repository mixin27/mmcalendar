import 'package:equatable/equatable.dart';
import 'package:holidays/holidays.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';

/// One astrological mark of a day, in the calendar language, with the
/// app's tone for it ([GoodDays.tone]).
typedef AstroMark = ({String name, AstroTone tone});

/// A day as the watch shows it: the Myanmar date from
/// `myanmar_calendar_dart`, holidays from the phone's catalog
/// ([HolidayYears]) and astrology by the phone's rule ([GoodDays]), all in
/// the calendar [language].
class DayDetails extends Equatable {
  DayDetails(DateTime date, this.language)
    : date = DateTime(date.year, date.month, date.day),
      myanmar = MyanmarCalendar.fromWestern(date.year, date.month, date.day);

  /// The calendar day (no time).
  final DateTime date;
  final Language language;
  final MyanmarDateTime myanmar;

  CalendarFormat get _format => CalendarFormat(language);

  String _t(String key) => TranslationService.translateTo(key, language);

  DayDetails get previousDay =>
      DayDetails(DateTime(date.year, date.month, date.day - 1), language);

  DayDetails get nextDay =>
      DayDetails(DateTime(date.year, date.month, date.day + 1), language);

  DayDetails inLanguage(Language other) => DayDetails(date, other);

  bool isToday(DateTime now) =>
      date.year == now.year && date.month == now.month && date.day == now.day;

  /// "Thursday".
  String get weekday => _format.weekday(date);

  /// "22 October 2026".
  String get westernDate =>
      '${_format.westernNumber(date.day)} ${_format.month(date.month)} '
      '${_format.westernNumber(date.year)}';

  /// The Myanmar date with its year; a Shan calendar shows the Shan year,
  /// as the phone does by default (Settings › Prefer Shan Year).
  String get myanmarDate => formatMyanmarDate(
    myanmar.myanmarDate,
    pattern: '&y &M &P &ff',
    language: language,
    preferShanYear: true,
  );

  /// "Tazaungmon".
  String get monthName => myanmar.formatMyanmar('&M', language);

  /// Waxing, Full Moon, Waning or New Moon.
  String get moonPhaseName =>
      TranslationService.getMoonPhaseName(myanmar.moonPhase, language);

  /// The day of the fortnight in the language's digits.
  String get fortnightDay => _format.number(myanmar.fortnightDay);

  bool get isSabbath => myanmar.isSabbath;
  bool get isSabbathEve => myanmar.isSabbathEve;

  /// "Sabbath" or "Sabbath Eve"; empty on other days.
  String get sabbathLabel => isSabbath
      ? _t('Sabbath')
      : isSabbathEve
      ? _t('Sabbath Eve')
      : '';

  /// The day's holidays as the phone titles them, anniversaries included.
  List<String> holidays(AppLocalizations l10n) => [
    for (final o in HolidayYears.of(date.year, language))
      if (o.contains(date)) o.entry.title(l10n),
  ];

  /// Yatyaza, Pyathada and the named days.
  List<AstroMark> get astrology => [
    for (final mark in [
      if (myanmar.isYatyaza) myanmar.yatyaza,
      if (myanmar.hasPyathada) myanmar.pyathada,
      ...myanmar.astrologicalDays,
    ])
      (name: _t(mark), tone: GoodDays.tone(mark)),
  ];

  String get nagahle => _t(myanmar.nagahle);
  String get mahabote => _t(myanmar.mahabote);
  String get nakhat => _t(myanmar.nakhat);

  @override
  List<Object?> get props => [date, language];
}
