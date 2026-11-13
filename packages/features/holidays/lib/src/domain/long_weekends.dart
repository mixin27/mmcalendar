import 'package:flutter/foundation.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import 'holiday_year.dart';

/// A long break: the days off in a row, and the work days to take as leave
/// to get them (none when the holidays and weekend already join up).
@immutable
class LongWeekend {
  const LongWeekend({
    required this.start,
    required this.end,
    required this.leave,
    required this.holidays,
  });

  /// The first and last day off, at midnight.
  final DateTime start;
  final DateTime end;

  /// The work days to take off, earliest first; empty when none are needed.
  final List<DateTime> leave;

  /// The office-closed holidays in the break.
  final List<HolidayOccurrence> holidays;

  /// Days off in a row.
  int get length => end.difference(start).inDays + 1;

  /// Days off gained for each day of leave; the whole break with none.
  double get ratio => leave.isEmpty ? length.toDouble() : length / leave.length;

  @override
  String toString() =>
      'LongWeekend($start–$end, $length days, leave: ${leave.length})';
}

/// Long breaks around the year's public holidays: the stretches the
/// holidays and weekends already make, and the work days that, taken as
/// leave, join them into longer ones.
abstract final class LongWeekends {
  /// Breaks shorter than this aren't worth showing: two days is a weekend.
  static const minLength = 4;

  /// Days off a break must have besides the leave taken for it, so two
  /// days of leave for a four-day break isn't suggested.
  static const minFreeDays = 3;

  /// The breaks that start in [year] and end on or after [today], earliest
  /// first, taking up to [maxLeave] days of leave. Weekends are Saturday
  /// and Sunday.
  ///
  /// A break needs at least one public holiday, [minLength] days and
  /// [minFreeDays] days off besides the leave. When
  /// breaks overlap, the one with the most days off per day of leave is
  /// kept (the longer one on a tie).
  static List<LongWeekend> plan(
    int year,
    Language language, {
    int maxLeave = 1,
    DateTime? today,
  }) {
    // A margin either side, so breaks across New Year are whole.
    final from = DateTime(year - 1, 12, 1);
    final to = DateTime(year + 1, 1, 31);
    final closed = HolidayYears.between(
      from,
      to,
      language,
    ).where((o) => o.entry.officeClosed).toList();
    final holidayDays = <DateTime>{
      for (final o in closed)
        for (final d in o.days) _day(d.date),
    };
    bool weekend(DateTime d) =>
        d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
    bool off(DateTime d) => weekend(d) || holidayDays.contains(d);

    final days = [
      for (
        var d = from;
        !d.isAfter(to);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        d,
    ];
    // Every run of up to [maxLeave] work days next to one another (counting
    // off days between them as free) that touches an off day, and the
    // stretch it makes.
    final candidates = <LongWeekend>[];
    void consider(int first, int last, List<DateTime> leave) {
      var s = first, e = last;
      while (s > 0 && off(days[s - 1])) {
        s--;
      }
      while (e < days.length - 1 && off(days[e + 1])) {
        e++;
      }
      final start = days[s], end = days[e];
      final holidays = [
        for (final o in closed)
          if (!_day(o.end).isBefore(start) && !_day(o.start).isAfter(end)) o,
      ];
      if (holidays.isEmpty) return;
      final length = end.difference(start).inDays + 1;
      if (length < minLength) return;
      // Worth it: at least [minFreeDays] days off besides the leave.
      if (length - leave.length < minFreeDays) return;
      candidates.add(
        LongWeekend(start: start, end: end, leave: leave, holidays: holidays),
      );
    }

    // Breaks that need no leave.
    for (var i = 0; i < days.length; i++) {
      if (off(days[i]) && (i == 0 || !off(days[i - 1]))) consider(i, i, []);
    }
    // Breaks made by taking 1..maxLeave work days.
    for (var i = 0; i < days.length; i++) {
      if (off(days[i])) continue;
      final leave = <DateTime>[];
      var j = i;
      while (j < days.length && leave.length < maxLeave) {
        if (!off(days[j])) leave.add(days[j]);
        consider(i, j, List.of(leave));
        j++;
        // Stop at a gap of two work days we aren't taking.
        if (leave.length == maxLeave) break;
      }
    }

    // Keep the best of overlapping breaks.
    candidates.sort((a, b) {
      final byRatio = b.ratio.compareTo(a.ratio);
      if (byRatio != 0) return byRatio;
      final byLength = b.length.compareTo(a.length);
      if (byLength != 0) return byLength;
      return a.leave.length.compareTo(b.leave.length);
    });
    final kept = <LongWeekend>[];
    for (final c in candidates) {
      final overlaps = kept.any(
        (k) => !c.end.isBefore(k.start) && !c.start.isAfter(k.end),
      );
      if (!overlaps) kept.add(c);
    }

    final now = _day(today ?? DateTime.now());
    return [
      for (final k in kept)
        if (k.start.year == year && !k.end.isBefore(now)) k,
    ]..sort((a, b) => a.start.compareTo(b.start));
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
