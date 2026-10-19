import '../entities/event.dart';
import '../entities/recurrence_rule.dart';

/// Weekly series set up from a timetable: chosen weekdays, each optionally
/// at its own time.
abstract final class WeeklyTimetable {
  /// The first of [weekdays] (`DateTime.monday`…`sunday`) on or after
  /// [from], date only.
  static DateTime firstOnOrAfter(DateTime from, Set<int> weekdays) {
    var day = DateTime(from.year, from.month, from.day);
    if (weekdays.isEmpty) return day;
    while (!weekdays.contains(day.weekday)) {
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return day;
  }

  /// The events to save for [event]. A weekly series on chosen weekdays
  /// starts on the first of them, so the start date is never an extra
  /// class. With [dayTimes] (weekday → time) on a timed event, days that
  /// share a time become one weekly series each, in time order.
  static List<Event> eventsToSave(
    Event event, {
    Map<int, DateTime> dayTimes = const {},
  }) {
    final rule = event.recurrenceRule;
    // Specific dates start on the earliest of them.
    final dates = rule?.type == RecurrenceType.dates ? rule!.dates : null;
    if (dates != null && dates.isNotEmpty) {
      final first = dates.reduce((a, b) => a.isBefore(b) ? a : b);
      return [
        _startOn(event.copyWith(eventDate: first), const {}, event.eventTime),
      ];
    }
    final days = rule?.daysOfWeek?.toSet() ?? const <int>{};
    if (rule == null || rule.type != RecurrenceType.weekly || days.isEmpty) {
      return [event];
    }
    if (dayTimes.isEmpty || event.isAllDay || event.id != null) {
      return [_startOn(event, days, event.eventTime)];
    }

    // "After N classes" counts the whole timetable, so the split series
    // all end on the date of the Nth class rather than each running N.
    var shared = rule;
    final count = rule.occurrenceCount;
    if (count != null) {
      final first = firstOnOrAfter(event.eventDate, days);
      final dates = rule.generateOccurrences(
        first,
        first,
        DateTime(first.year + 20, first.month, first.day),
      );
      shared = RecurrenceRule(
        type: rule.type,
        interval: rule.interval,
        daysOfWeek: rule.daysOfWeek,
        endDate: dates.isEmpty ? rule.endDate : dates.last,
        exceptions: rule.exceptions,
      );
    }

    // Days sharing an hour and minute become one series.
    final groups = <int, List<int>>{};
    for (final day in days) {
      final time = dayTimes[day] ?? event.eventTime;
      final key = time == null ? -1 : time.hour * 60 + time.minute;
      (groups[key] ??= []).add(day);
    }
    final keys = groups.keys.toList()..sort();
    return [
      for (final key in keys)
        _startOn(
          event.copyWith(
            recurrenceRule: shared.copyWith(daysOfWeek: (groups[key]!..sort())),
          ),
          groups[key]!.toSet(),
          key < 0 ? event.eventTime : DateTime(2000, 1, 1, key ~/ 60, key % 60),
        ),
    ];
  }

  static Event _startOn(Event event, Set<int> days, DateTime? time) {
    final start = firstOnOrAfter(event.eventDate, days);
    return event.copyWith(
      eventDate: start,
      eventTime: time == null
          ? null
          : DateTime(
              start.year,
              start.month,
              start.day,
              time.hour,
              time.minute,
            ),
    );
  }
}
