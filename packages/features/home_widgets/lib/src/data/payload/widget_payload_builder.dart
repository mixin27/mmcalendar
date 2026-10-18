import 'package:intl/intl.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' show MoonPhaseState;

import 'widget_strings.dart';

/// One event as the widgets show it.
class WidgetAgendaEvent {
  const WidgetAgendaEvent({
    required this.id,
    required this.date,
    required this.title,
    required this.color,
    this.time,
    this.done = false,
  });

  final int? id;
  final DateTime date;
  final String title;
  final int color;

  /// Start time, or null for all-day events.
  final DateTime? time;
  final bool done;

  factory WidgetAgendaEvent.fromItem(CalendarEventItem item, DateTime day) =>
      WidgetAgendaEvent(
        id: item.id,
        date: day,
        title: item.title,
        color: item.effectiveColor,
        time: item.isAllDay ? null : item.eventTime,
        done: item.isCompleted,
      );
}

/// Builds `widget_data_v2`: everything the native widgets draw, so they
/// never compute calendar data or hard-code text.
///
/// Shape (keys kept short; the payload is read on every widget refresh):
/// - `v`, `lang`, `gen`, `start`: version, calendar language, build time,
///   first day.
/// - `s`: labels and calendar words ([WidgetStrings]).
/// - `days`: one entry per day from `start`: `d` date, `wd` weekday (Sunday
///   0), `my` Myanmar date, `lu` short lunar label, `ln` lunar day, `ph`
///   moon phase (0 waxing, 1 full, 2 waning, 3 new), `il` illumination, `wx`
///   waxing, `hol` holidays, `sab` (1 Sabbath, 2 Sabbath eve), `good` /
///   `avoid` / `info` astrological days.
/// - `months`: `yyyy-MM` → `title`, `sub` (Myanmar months and year), and 42
///   Sunday-first `cells` (`d`, `in`, `ln`, `ph`, `hol`, `sab`). There is no
///   "today" flag: widgets compare with their own date.
/// - `upcoming`: next holidays, Sabbath days, full and new moons (`d`, `k`,
///   `n`), oldest first.
/// - `thingyan`: the next Thingyan's first day and name.
/// - `events`: the next two weeks (`d`, `t`, `ti`, `c`, `id`, `done`).
/// - `year`: Myanmar year `n`, `start`, `end` (exclusive), current `month`.
/// - `styles`, `prefs`: passed through.
abstract final class WidgetPayloadBuilder {
  static const version = 2;
  static const horizonDays = 180;

  static const _good = {'Thamanyo', 'Thamaphyu'};
  static const _info = {'Nagapor'};

  static Map<String, Object?> build({
    required DateTime today,
    required Language language,
    List<WidgetAgendaEvent> events = const [],
    Map<String, Object> styles = const {},
    Map<String, Object?> prefs = const {},
    DateTime? generatedAt,
    int days = horizonDays,
  }) {
    final start = DateTime(today.year, today.month, today.day);
    final format = CalendarFormat(language);
    String t(String key) => TranslationService.translateTo(key, language);

    final dayList = <Map<String, Object?>>[];
    for (var i = 0; i < days; i++) {
      final date = DateTime(start.year, start.month, start.day + i);
      dayList.add(_day(date, language, format, t));
    }

    return {
      'v': version,
      'lang': language.code,
      'gen': (generatedAt ?? DateTime.now()).toIso8601String(),
      'start': _key(start),
      's': WidgetStrings.forLanguage(language),
      'days': dayList,
      'months': {
        for (var offset = -1; offset <= 5; offset++)
          _monthKey(DateTime(start.year, start.month + offset)): _month(
            DateTime(start.year, start.month + offset),
            language,
            format,
          ),
      },
      'upcoming': _upcoming(start, language, t),
      'thingyan': _thingyan(start, t),
      'events': [
        for (final event in events.take(40))
          {
            'd': _key(event.date),
            't': event.time == null
                ? null
                : DateFormat('HH:mm').format(event.time!),
            'ti': event.title,
            'c': event.color,
            'id': event.id,
            'done': event.done,
          },
      ],
      'year': _year(start, language, format),
      'styles': styles,
      'prefs': prefs,
    };
  }

  static Map<String, Object?> _day(
    DateTime date,
    Language language,
    CalendarFormat format,
    String Function(String) t,
  ) {
    final mdt = MyanmarCalendar.fromWestern(date.year, date.month, date.day);
    final moon = MoonPhaseState.evening(date);
    final good = <String>[], avoid = <String>[], info = <String>[];
    for (final name in [
      ...mdt.astrologicalDays,
      if (mdt.isYatyaza) mdt.yatyaza,
      if (mdt.hasPyathada) mdt.pyathada,
    ]) {
      (_good.contains(name)
              ? good
              : _info.contains(name)
              ? info
              : avoid)
          .add(t(name));
    }
    return {
      'd': _key(date),
      'wd': date.weekday % 7,
      'my': mdt.formatMyanmar('&M &P &f', language),
      'lu': mdt.formatMyanmar('&P &f', language),
      'ln': format.number(mdt.fortnightDay),
      'ph': mdt.moonPhase,
      'il': double.parse(moon.illumination.toStringAsFixed(3)),
      'wx': moon.isWaxing,
      'hol': [for (final h in mdt.allHolidays) t(h)],
      'sab': mdt.isSabbath ? 1 : (mdt.isSabbathEve ? 2 : 0),
      'good': good,
      'avoid': avoid,
      'info': info,
    };
  }

  static Map<String, Object?> _month(
    DateTime month,
    Language language,
    CalendarFormat format,
  ) {
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    final gridStart = first.subtract(Duration(days: first.weekday % 7));
    final firstMy = MyanmarCalendar.fromWestern(first.year, first.month, 1);
    final lastMy = MyanmarCalendar.fromWestern(last.year, last.month, last.day);
    final months = {
      firstMy.formatMyanmar('&M', language),
      lastMy.formatMyanmar('&M', language),
    };
    return {
      'title': format.monthYear(first),
      'sub': '${months.join(' – ')} · ${lastMy.formatMyanmar('&y', language)}',
      'cells': [
        for (var i = 0; i < 42; i++)
          () {
            final date = DateTime(
              gridStart.year,
              gridStart.month,
              gridStart.day + i,
            );
            final mdt = MyanmarCalendar.fromWestern(
              date.year,
              date.month,
              date.day,
            );
            return {
              'd': date.day,
              'in': date.month == month.month,
              'ln': format.number(mdt.fortnightDay),
              'ph': mdt.moonPhase,
              'hol': mdt.allHolidays.isNotEmpty,
              'sab': mdt.isSabbath,
            };
          }(),
      ],
    };
  }

  static List<Map<String, Object?>> _upcoming(
    DateTime start,
    Language language,
    String Function(String) t,
  ) {
    final items = <Map<String, Object?>>[];
    String? previousHoliday;
    for (var i = 0; i < 120 && items.length < 16; i++) {
      final date = DateTime(start.year, start.month, start.day + i);
      final mdt = MyanmarCalendar.fromWestern(date.year, date.month, date.day);
      final holiday = mdt.allHolidays.firstOrNull;
      // A run of days with the same holiday (Thadingyut 25–27) counts once.
      if (holiday != null && holiday != previousHoliday) {
        items.add({'d': _key(date), 'k': 'holiday', 'n': t(holiday)});
      }
      previousHoliday = holiday;
      if (mdt.isFullMoon) {
        items.add({
          'd': _key(date),
          'k': 'fullMoon',
          'n': TranslationService.getMoonPhaseName(1, language),
        });
      } else if (mdt.isNewMoon) {
        items.add({
          'd': _key(date),
          'k': 'newMoon',
          'n': TranslationService.getMoonPhaseName(3, language),
        });
      }
      if (mdt.isSabbath) {
        items.add({'d': _key(date), 'k': 'sabbath', 'n': t('Sabbath')});
      }
    }
    return items;
  }

  static Map<String, Object?>? _thingyan(
    DateTime start,
    String Function(String) t,
  ) {
    for (var i = 0; i < 400; i++) {
      final date = DateTime(start.year, start.month, start.day + i);
      final mdt = MyanmarCalendar.fromWestern(date.year, date.month, date.day);
      final name = mdt.allHolidays
          .where((h) => h.contains('Thingyan'))
          .firstOrNull;
      if (name != null) return {'d': _key(date), 'n': t(name)};
    }
    return null;
  }

  static Map<String, Object?> _year(
    DateTime start,
    Language language,
    CalendarFormat format,
  ) {
    final now = MyanmarCalendar.fromWestern(start.year, start.month, start.day);
    // The year number changes on Myanmar New Year Day (mid-Tagu), so find
    // that day either side of [start] by the year number itself.
    int yearAt(int offset) {
      final date = DateTime(start.year, start.month, start.day + offset);
      return MyanmarCalendar.fromWestern(
        date.year,
        date.month,
        date.day,
      ).myanmarYear;
    }

    int firstOffset(int lo, int hi, bool Function(int) test) {
      // Smallest offset in (lo, hi] passing [test]; [test] is monotonic.
      while (hi - lo > 1) {
        final mid = (lo + hi) ~/ 2;
        test(mid) ? hi = mid : lo = mid;
      }
      return hi;
    }

    final year = now.myanmarYear;
    final startOffset = firstOffset(-400, 0, (o) => yearAt(o) >= year);
    final endOffset = firstOffset(0, 400, (o) => yearAt(o) > year);
    DateTime at(int offset) =>
        DateTime(start.year, start.month, start.day + offset);
    final yearStart = at(startOffset);
    final nextStart = at(endOffset);
    return {
      'n': now.formatMyanmar('&y', language),
      'start': _key(yearStart),
      'end': _key(nextStart),
      'month': now.formatMyanmar('&M', language),
    };
  }

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}';
}
