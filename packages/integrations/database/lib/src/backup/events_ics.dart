import 'dart:convert';

import '../database/app_database.dart';

/// The app's events as an iCalendar (.ics) file, for Google Calendar,
/// Apple Calendar and others.
///
/// All-day events are whole days; timed events last an hour, at the same
/// local time wherever the file is opened. Repeats become `RRULE`, picked
/// dates `RDATE`, and occurrences deleted in the app `EXDATE`. Reminders,
/// categories and edits to single occurrences stay in the app.
abstract final class EventsIcs {
  static const extension = 'ics';
  static const mimeType = 'text/calendar';

  /// Reads every event from [db] and encodes it.
  static Future<String> fromDatabase(AppDatabase db, {DateTime? now}) async =>
      encode(
        events: await db.select(db.calendarEvents).get(),
        rules: await db.select(db.eventRecurrenceRules).get(),
        exceptions: await db.select(db.recurringEventExceptions).get(),
        now: now ?? DateTime.now(),
      );

  static String encode({
    required List<CalendarEvent> events,
    List<EventRecurrenceRule> rules = const [],
    List<RecurringEventException> exceptions = const [],
    required DateTime now,
  }) {
    final ruleOf = {for (final r in rules) r.eventId: r};
    final out = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Myanmar Calendar//Events//EN',
      'CALSCALE:GREGORIAN',
    ];
    for (final e in events) {
      final allDay = e.isAllDay || e.eventTime == null;
      final start = allDay
          ? e.eventDate
          : DateTime(
              e.eventDate.year,
              e.eventDate.month,
              e.eventDate.day,
              e.eventTime!.hour,
              e.eventTime!.minute,
            );
      String when(DateTime d) => allDay ? _date(d) : _local(d);
      final value = allDay ? ';VALUE=DATE' : '';
      out
        ..add('BEGIN:VEVENT')
        ..add('UID:mmcalendar-${e.id}-${e.createdAt.millisecondsSinceEpoch}')
        ..add('DTSTAMP:${_utc(now)}')
        ..add(_text('SUMMARY', e.title))
        ..add('DTSTART$value:${when(start)}')
        ..add(
          'DTEND$value:${when(allDay ? DateTime(start.year, start.month, start.day + 1) : start.add(const Duration(hours: 1)))}',
        );
      if (e.description case final d? when d.trim().isNotEmpty) {
        out.add(_text('DESCRIPTION', d));
      }
      if (e.location case final l? when l.trim().isNotEmpty) {
        out.add(_text('LOCATION', l));
      }
      if (ruleOf[e.id] case final rule?) {
        out.addAll(_repeat(rule, start, allDay));
        final deleted = [
          for (final x in exceptions)
            if (x.masterEventId == e.id && x.exceptionType == 'deleted')
              x.occurrenceDate,
        ];
        if (deleted.isNotEmpty) {
          out.add(
            'EXDATE$value:${deleted.map((d) => when(_at(d, start))).join(',')}',
          );
        }
      }
      out.add('END:VEVENT');
    }
    out.add('END:VCALENDAR');
    return '${out.map(_fold).join('\r\n')}\r\n';
  }

  static const _byDay = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  static List<String> _repeat(
    EventRecurrenceRule rule,
    DateTime start,
    bool allDay,
  ) {
    if (rule.recurrenceType == 'dates') {
      final days = _list(rule.recurrenceDays)
          .map((v) => DateTime.tryParse('$v'))
          .whereType<DateTime>()
          .where((d) => !_sameDay(d, start));
      if (days.isEmpty) return const [];
      return [
        'RDATE${allDay ? ';VALUE=DATE' : ''}:'
            '${days.map((d) => allDay ? _date(d) : _local(_at(d, start))).join(',')}',
      ];
    }
    final freq = switch (rule.recurrenceType) {
      'daily' => 'DAILY',
      'weekly' => 'WEEKLY',
      'monthly' => 'MONTHLY',
      'yearly' => 'YEARLY',
      _ => null,
    };
    if (freq == null) return const [];
    final parts = ['FREQ=$freq'];
    if (rule.recurrenceInterval > 1) {
      parts.add('INTERVAL=${rule.recurrenceInterval}');
    }
    if (freq == 'WEEKLY') {
      final days = _list(
        rule.recurrenceDays,
      ).whereType<int>().where((d) => d >= 1 && d <= 7);
      if (days.isNotEmpty) {
        parts.add('BYDAY=${days.map((d) => _byDay[d - 1]).join(',')}');
      }
    }
    if (rule.recurrenceCount case final count? when count > 0) {
      parts.add('COUNT=$count');
    } else if (rule.recurrenceEndDate case final end?) {
      parts.add('UNTIL=${allDay ? _date(end) : '${_date(end)}T235959'}');
    }
    return ['RRULE:${parts.join(';')}'];
  }

  static List<Object?> _list(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      return jsonDecode(json) as List;
    } on Object {
      return const [];
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// [day] at [start]'s time of day.
  static DateTime _at(DateTime day, DateTime start) =>
      DateTime(day.year, day.month, day.day, start.hour, start.minute);

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${_two(d.month)}${_two(d.day)}';
  static String _local(DateTime d) =>
      '${_date(d)}T${_two(d.hour)}${_two(d.minute)}00';
  static String _utc(DateTime d) {
    final u = d.toUtc();
    return '${_date(u)}T${_two(u.hour)}${_two(u.minute)}${_two(u.second)}Z';
  }

  /// A text property, escaped as RFC 5545 asks.
  static String _text(String name, String value) =>
      '$name:${value.replaceAll(r'\', r'\\').replaceAll(';', r'\;').replaceAll(',', r'\,').replaceAll(RegExp(r'\r?\n'), r'\n')}';

  /// Lines longer than 75 bytes continue on the next line after a space.
  static String _fold(String line) {
    final bytes = utf8.encode(line);
    if (bytes.length <= 75) return line;
    final parts = <String>[];
    var current = StringBuffer();
    var size = 0;
    for (final rune in line.runes) {
      final char = String.fromCharCode(rune);
      final n = utf8.encode(char).length;
      if (size + n > (parts.isEmpty ? 75 : 74)) {
        parts.add(current.toString());
        current = StringBuffer();
        size = 0;
      }
      current.write(char);
      size += n;
    }
    parts.add(current.toString());
    return parts.join('\r\n ');
  }
}
