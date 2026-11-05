import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// How often a Myanmar-date repeat comes.
enum MyanmarRepeat {
  /// The same Myanmar month and day each year: birthdays, anniversaries.
  yearly,

  /// The same Myanmar day each month: every full moon, every waxing 8.
  monthly,
}

/// Days that repeat by the Myanmar calendar, from the Myanmar date of an
/// anchor day.
///
/// A day matches when it has the anchor's day of the month (1–30); when
/// the anchor is a new moon, when it is the new moon, since months have 29
/// or 30 days.
/// Yearly, it must also be the anchor's month:
/// - Tagu and Late Tagu (the days before Thingyan) count as one month, as
///   do Kason and Late Kason;
/// - First Waso, which only watat years have, is Waso in other years.
///
/// Occurrences are at least [_yearGap] or [_monthGap] days apart, so a year
/// (or month) never has two.
abstract final class MyanmarRecurrence {
  static const _yearGap = 300;
  static const _monthGap = 20;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// [d]'s Myanmar date.
  static MyanmarDate myanmarOf(DateTime d) =>
      MyanmarCalendar.getCompleteDateFor(d.year, d.month, d.day).myanmar;

  static MyanmarDate _myanmar(DateTime d) => myanmarOf(d);

  static bool _sameMonth(int anchor, int month) => switch (anchor) {
    0 => month == 0 || month == 4,
    1 || 13 => month == 1 || month == 13,
    2 || 14 => month == 2 || month == 14,
    _ => month == anchor,
  };

  /// Whether [day] has the Myanmar day (and, [MyanmarRepeat.yearly], the
  /// month) of [anchor]. The gap rule isn't applied here.
  static bool matches(MyanmarDate anchor, MyanmarDate day, MyanmarRepeat r) {
    // A new moon is the 29th or the 30th, whichever the month ends on.
    final sameDay = anchor.moonPhase == 3
        ? day.moonPhase == 3
        : day.day == anchor.day;
    if (!sameDay) return false;
    return r == MyanmarRepeat.monthly || _sameMonth(anchor.month, day.month);
  }

  /// The occurrences from [from] to [to] (both included) of a repeat that
  /// starts on [anchor]: every [interval]th one, at most [count] in all
  /// (days in [skip] don't count, as with Western repeats), none after
  /// [until].
  static List<DateTime> occurrences(
    DateTime anchor,
    MyanmarRepeat repeat, {
    required DateTime from,
    required DateTime to,
    int interval = 1,
    int? count,
    DateTime? until,
    bool Function(DateTime day)? skip,
  }) {
    final start = _day(anchor);
    final first = _day(from);
    var last = _day(to);
    if (until != null && _day(until).isBefore(last)) last = _day(until);
    if (last.isBefore(start) || last.isBefore(first)) return const [];
    final gap = repeat == MyanmarRepeat.yearly ? _yearGap : _monthGap;
    final step = interval < 1 ? 1 : interval;
    final a = _myanmar(start);

    // Without a count or an interval the series needn't be walked from the
    // anchor; starting a little before the range keeps the gap rule right.
    final countAll = count != null || step > 1;
    var d = countAll || !first.isAfter(start)
        ? start
        : first.subtract(Duration(days: gap));
    if (d.isBefore(start)) d = start;

    final out = <DateTime>[];
    DateTime? previous;
    var index = 0, taken = 0;
    for (; !d.isAfter(last); d = DateTime(d.year, d.month, d.day + 1)) {
      if (previous != null && d.difference(previous).inDays < gap) continue;
      if (d != start && !matches(a, _myanmar(d), repeat)) continue;
      previous = d;
      if (index++ % step != 0) continue;
      if (skip?.call(d) ?? false) continue;
      if (count != null && ++taken > count) break;
      if (!d.isBefore(first)) out.add(d);
    }
    return out;
  }

  /// The next occurrence on or after [from] of a yearly repeat from
  /// [anchor] (a birthday), within about three years.
  static DateTime? next(DateTime anchor, DateTime from) {
    final hits = occurrences(
      anchor,
      MyanmarRepeat.yearly,
      from: from,
      to: DateTime(from.year + 3, from.month, from.day),
    );
    return hits.isEmpty ? null : hits.first;
  }
}
