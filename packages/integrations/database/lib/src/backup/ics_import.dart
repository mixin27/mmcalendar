import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// One event read from an iCalendar file.
class IcsEvent {
  IcsEvent({
    required this.title,
    required this.start,
    required this.allDay,
    this.description,
    this.location,
    this.repeat,
    this.interval = 1,
    this.weekdays = const [],
    this.count,
    this.until,
    this.dates = const [],
    this.deleted = const [],
  });

  final String title;

  /// The first day, with its time unless [allDay].
  final DateTime start;
  final bool allDay;
  final String? description;
  final String? location;

  /// `daily`, `weekly`, `monthly`, `yearly` or `dates`, as the app stores
  /// repeats; null for a single event.
  final String? repeat;
  final int interval;

  /// For weekly: `DateTime` weekdays.
  final List<int> weekdays;
  final int? count;
  final DateTime? until;

  /// For `dates`: every day it falls on, the first included.
  final List<DateTime> dates;

  /// Occurrences deleted in the other calendar.
  final List<DateTime> deleted;
}

/// What an iCalendar file holds.
class IcsCalendar {
  const IcsCalendar(this.events, {this.simplified = 0, this.skipped = 0});

  final List<IcsEvent> events;

  /// Events whose repeat the app can't express ("the 2nd Monday"), read as
  /// single events.
  final int simplified;

  /// Cancelled events and edits to single occurrences, left out.
  final int skipped;
}

/// Reads iCalendar (.ics) files from Google Calendar, Apple Calendar and
/// others, and adds their events to the app.
abstract final class IcsImport {
  static const _weekdays = {
    'MO': DateTime.monday,
    'TU': DateTime.tuesday,
    'WE': DateTime.wednesday,
    'TH': DateTime.thursday,
    'FR': DateTime.friday,
    'SA': DateTime.saturday,
    'SU': DateTime.sunday,
  };

  /// Parses [text]; throws [FormatException] when it isn't a calendar.
  static IcsCalendar parse(String text) {
    // Folded lines continue after a space or a tab.
    final lines = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp('\n[ \t]'), '')
        .split('\n');
    if (!lines.any((l) => l.trim().toUpperCase() == 'BEGIN:VCALENDAR')) {
      throw const FormatException('Not an iCalendar file');
    }
    final events = <IcsEvent>[];
    var simplified = 0, skipped = 0;
    Map<String, List<_Property>>? current;
    var nested = 0;
    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;
      final upper = line.toUpperCase();
      if (upper == 'BEGIN:VEVENT') {
        current = {};
        nested = 0;
        continue;
      }
      if (current == null) continue;
      if (upper.startsWith('BEGIN:')) {
        nested++; // VALARM and the like.
        continue;
      }
      if (upper.startsWith('END:') && nested > 0) {
        nested--;
        continue;
      }
      if (upper == 'END:VEVENT') {
        final props = current;
        current = null;
        if (_one(props, 'RECURRENCE-ID') != null ||
            _one(props, 'STATUS')?.value.toUpperCase() == 'CANCELLED') {
          skipped++;
          continue;
        }
        final (event, lossy) = _event(props);
        if (event == null) {
          skipped++;
        } else {
          events.add(event);
          if (lossy) simplified++;
        }
        continue;
      }
      if (nested > 0) continue;
      final p = _Property.parse(line);
      if (p != null) (current[p.name] ??= []).add(p);
    }
    return IcsCalendar(events, simplified: simplified, skipped: skipped);
  }

  static _Property? _one(Map<String, List<_Property>> props, String name) =>
      props[name]?.first;

  /// The event, and whether its repeat had to be simplified.
  static (IcsEvent?, bool) _event(Map<String, List<_Property>> props) {
    final dtStart = _one(props, 'DTSTART');
    if (dtStart == null) return (null, false);
    final start = _dateTime(dtStart.value, dtStart.params);
    if (start == null) return (null, false);
    final allDay =
        dtStart.params['VALUE']?.toUpperCase() == 'DATE' ||
        dtStart.value.length == 8;
    final title = _text(_one(props, 'SUMMARY')?.value ?? '').trim();
    String? text(String name) {
      final v = _one(props, name)?.value;
      if (v == null) return null;
      final t = _text(v).trim();
      return t.isEmpty ? null : t;
    }

    List<DateTime> days(String name) => [
      for (final p in props[name] ?? const <_Property>[])
        for (final v in p.value.split(',')) ?_dateTime(v.trim(), p.params),
    ];

    var lossy = false;
    String? repeat;
    var interval = 1;
    var weekdays = <int>[];
    int? count;
    DateTime? until;
    final rrule = _one(props, 'RRULE');
    final rdates = days('RDATE');
    if (rrule != null) {
      final parts = {
        for (final kv in rrule.value.split(';'))
          if (kv.contains('='))
            kv.substring(0, kv.indexOf('=')).toUpperCase(): kv.substring(
              kv.indexOf('=') + 1,
            ),
      };
      final freq = parts['FREQ']?.toUpperCase();
      repeat = switch (freq) {
        'DAILY' => 'daily',
        'WEEKLY' => 'weekly',
        'MONTHLY' => 'monthly',
        'YEARLY' => 'yearly',
        _ => null,
      };
      interval = int.tryParse(parts['INTERVAL'] ?? '') ?? 1;
      count = int.tryParse(parts['COUNT'] ?? '');
      until = parts['UNTIL'] == null ? null : _dateTime(parts['UNTIL']!, {});
      final byDay = parts['BYDAY']?.split(',') ?? const [];
      if (repeat == 'weekly') {
        for (final d in byDay) {
          final day = _weekdays[d.toUpperCase()];
          if (day == null) {
            lossy = true;
          } else {
            weekdays.add(day);
          }
        }
      } else if (byDay.isNotEmpty) {
        lossy = true; // "The 2nd Monday" and the like.
      }
      if (parts['BYMONTHDAY'] case final day?
          when int.tryParse(day) != start.day) {
        lossy = true;
      }
      if (parts['BYMONTH'] case final month?
          when int.tryParse(month) != start.month) {
        lossy = true;
      }
      const understood = {
        'FREQ',
        'INTERVAL',
        'COUNT',
        'UNTIL',
        'BYDAY',
        'BYMONTHDAY',
        'BYMONTH',
        'WKST',
      };
      if (repeat == null || parts.keys.any((k) => !understood.contains(k))) {
        lossy = true;
      }
      if (rdates.isNotEmpty) lossy = true;
      if (lossy) {
        repeat = null;
        weekdays = [];
        interval = 1;
        count = null;
        until = null;
      }
    } else if (rdates.isNotEmpty) {
      repeat = 'dates';
    }
    final day = DateTime(start.year, start.month, start.day);
    return (
      IcsEvent(
        title: title.isEmpty ? '(No title)' : title,
        start: start,
        allDay: allDay,
        description: text('DESCRIPTION'),
        location: text('LOCATION'),
        repeat: repeat,
        interval: interval < 1 ? 1 : interval,
        weekdays: weekdays,
        count: count,
        until: until,
        dates: repeat == 'dates'
            ? ({
                day,
                for (final d in rdates) DateTime(d.year, d.month, d.day),
              }.toList()..sort())
            : const [],
        deleted: repeat == null
            ? const []
            : [
                for (final d in days('EXDATE'))
                  DateTime(d.year, d.month, d.day),
              ],
      ),
      lossy,
    );
  }

  /// `20261105`, `20261105T090000`, or `…Z` (UTC, read as local time).
  /// Times with a `TZID` are taken as the wall-clock time they say.
  static DateTime? _dateTime(String value, Map<String, String> params) {
    final m = RegExp(
      r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$',
    ).firstMatch(value.trim());
    if (m == null) return null;
    int g(int i) => int.parse(m.group(i) ?? '0');
    if (m.group(4) == null) return DateTime(g(1), g(2), g(3));
    if (m.group(7) != null) {
      return DateTime.utc(g(1), g(2), g(3), g(4), g(5), g(6)).toLocal();
    }
    return DateTime(g(1), g(2), g(3), g(4), g(5), g(6));
  }

  static String _text(String v) => v.replaceAllMapped(
    RegExp(r'\\([\\,;nN])'),
    (m) => switch (m.group(1)!) {
      'n' || 'N' => '\n',
      final c => c,
    },
  );

  /// Adds [calendar]'s events to [db], skipping those already here (same
  /// title, day and time). Returns how many were added.
  static Future<int> importInto(
    AppDatabase db,
    IcsCalendar calendar, {
    DateTime? now,
  }) => db.transaction(() async {
    final stamp = now ?? DateTime.now();
    String key(String title, DateTime date, DateTime? time) =>
        '$title|${date.year}-${date.month}-${date.day}|'
        '${time == null ? '' : '${time.hour}:${time.minute}'}';
    final here = {
      for (final e in await db.select(db.calendarEvents).get())
        key(e.title, e.eventDate, e.isAllDay ? null : e.eventTime),
    };
    final personal = await (db.select(
      db.eventCategories,
    )..where((c) => c.name.equals('Personal'))).getSingleOrNull();
    var added = 0;
    for (final e in calendar.events) {
      final day = DateTime(e.start.year, e.start.month, e.start.day);
      final time = e.allDay ? null : e.start;
      final title = e.title.length > 200 ? e.title.substring(0, 200) : e.title;
      if (!here.add(key(title, day, time))) continue;
      final id = await db
          .into(db.calendarEvents)
          .insert(
            CalendarEventsCompanion.insert(
              title: title,
              description: Value(e.description),
              eventDate: day,
              eventTime: Value(time),
              isAllDay: Value(e.allDay),
              categoryId: Value(personal?.id),
              categoryName: Value(personal?.name ?? 'Personal'),
              location: Value(e.location),
              createdAt: stamp,
              updatedAt: stamp,
            ),
          );
      added++;
      final repeat = e.repeat;
      if (repeat == null) continue;
      String two(int n) => n.toString().padLeft(2, '0');
      await db
          .into(db.eventRecurrenceRules)
          .insert(
            EventRecurrenceRulesCompanion.insert(
              eventId: Value(id),
              recurrenceType: repeat,
              recurrenceInterval: Value(e.interval),
              recurrenceDays: Value(switch (repeat) {
                'weekly' when e.weekdays.isNotEmpty => jsonEncode(e.weekdays),
                'dates' => jsonEncode([
                  for (final d in e.dates)
                    '${d.year}-${two(d.month)}-${two(d.day)}',
                ]),
                _ => null,
              }),
              recurrenceEndDate: Value(e.until),
              recurrenceCount: Value(e.count),
              createdAt: stamp,
              updatedAt: stamp,
            ),
          );
      for (final d in e.deleted) {
        await db
            .into(db.recurringEventExceptions)
            .insert(
              RecurringEventExceptionsCompanion.insert(
                masterEventId: id,
                occurrenceDate: d,
                exceptionType: 'deleted',
                createdAt: stamp,
              ),
            );
      }
    }
    return added;
  });
}

class _Property {
  const _Property(this.name, this.params, this.value);

  final String name;
  final Map<String, String> params;
  final String value;

  /// `NAME;PARAM=VALUE;…:value`; a colon inside a quoted parameter doesn't
  /// end the name.
  static _Property? parse(String line) {
    var quoted = false;
    var colon = -1;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') quoted = !quoted;
      if (c == ':' && !quoted) {
        colon = i;
        break;
      }
    }
    if (colon <= 0) return null;
    final head = line.substring(0, colon).split(';');
    return _Property(head.first.toUpperCase(), {
      for (final p in head.skip(1))
        if (p.contains('='))
          p.substring(0, p.indexOf('=')).toUpperCase(): p
              .substring(p.indexOf('=') + 1)
              .replaceAll('"', ''),
    }, line.substring(colon + 1));
  }
}
