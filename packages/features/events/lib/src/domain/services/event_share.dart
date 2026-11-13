import 'dart:convert';

import '../entities/event.dart';
import '../entities/event_category.dart';
import '../entities/recurrence_rule.dart';

/// An event as a link someone else can open to add it to their calendar:
/// `mmcalendar://add-event?e=<data>`, where the data is the event's title,
/// day, time, notes, place, category name and repeat (Myanmar-date repeats
/// included) as base64url JSON. Reminders, status and tags stay behind.
abstract final class EventShare {
  static const scheme = 'mmcalendar';
  static const host = 'add-event';
  static const param = 'e';

  /// The data's format; links from a newer one aren't read.
  static const version = 1;

  /// Longest link that still makes a QR code a phone camera reads easily.
  static const qrLimit = 1200;

  static const _maxTitle = 200;
  static const _maxText = 2000;

  /// The link for [event]. Without [description], the notes are left out.
  static Uri link(Event event, {bool description = true}) => Uri(
    scheme: scheme,
    host: host,
    queryParameters: {param: encode(event, description: description)},
  );

  /// The link for a QR code: the whole event when it fits in [qrLimit],
  /// else without the notes; null when even that is too long.
  static ({Uri link, bool withoutNotes})? qrLink(Event event) {
    final full = link(event);
    if (full.toString().length <= qrLimit) {
      return (link: full, withoutNotes: false);
    }
    final short = link(event, description: false);
    if (short.toString().length <= qrLimit) {
      return (link: short, withoutNotes: true);
    }
    return null;
  }

  static String encode(Event event, {bool description = true}) {
    String day(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';
    final time = event.isAllDay ? null : event.eventTime;
    final rule = event.recurrenceRule;
    final json = <String, Object?>{
      'v': version,
      't': _cut(event.title, _maxTitle),
      'd': day(event.eventDate),
      if (time != null) 'h': '${_two(time.hour)}:${_two(time.minute)}',
      if (description && (event.description ?? '').trim().isNotEmpty)
        'n': _cut(event.description!.trim(), _maxText),
      if ((event.location ?? '').trim().isNotEmpty)
        'l': _cut(event.location!.trim(), _maxTitle),
      'g': event.category.name,
      if (rule != null && rule.type != RecurrenceType.none)
        'r': {
          'k': rule.type.name,
          if (rule.interval > 1) 'i': rule.interval,
          if (rule.daysOfWeek case final days? when days.isNotEmpty) 'w': days,
          'c': ?rule.occurrenceCount,
          if (rule.endDate case final end?) 'u': day(end),
          if (rule.dates case final dates? when dates.isNotEmpty)
            'x': [for (final d in dates) day(d)],
          if (rule.exceptions case final skip? when skip.isNotEmpty)
            's': [for (final d in skip) day(d)],
        },
    };
    return base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  }

  /// The event in [uri], or null when it isn't an event link (or is from a
  /// newer app).
  static SharedEvent? fromLink(Uri? uri) {
    if (uri == null || uri.scheme != scheme || uri.host != host) return null;
    return decode(uri.queryParameters[param]);
  }

  /// The event in [data], or null when it can't be read.
  static SharedEvent? decode(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      final padded = data.padRight((data.length + 3) ~/ 4 * 4, '=');
      final json = jsonDecode(utf8.decode(base64Url.decode(padded)));
      if (json is! Map<String, Object?>) return null;
      if (json['v'] case final int v when v > version) return null;
      final title = (json['t'] as String?)?.trim() ?? '';
      final date = _day(json['d']);
      if (title.isEmpty || date == null) return null;
      DateTime? time;
      if (json['h'] case final String h) {
        final parts = h.split(':').map(int.tryParse).toList();
        if (parts.length == 2 &&
            parts.every((p) => p != null) &&
            parts[0]! < 24 &&
            parts[1]! < 60) {
          time = DateTime(
            date.year,
            date.month,
            date.day,
            parts[0]!,
            parts[1]!,
          );
        }
      }
      RecurrenceRule? rule;
      if (json['r'] case final Map<String, Object?> r) {
        final type = RecurrenceType.values
            .where((t) => t.name == r['k'] && t != RecurrenceType.none)
            .firstOrNull;
        if (type != null) {
          List<DateTime>? days(Object? v) =>
              v is List ? [for (final d in v) ?_day(d)] : null;
          rule = RecurrenceRule(
            type: type,
            interval: switch (r['i']) {
              final int i when i > 0 && i < 1000 => i,
              _ => 1,
            },
            daysOfWeek: switch (r['w']) {
              final List<Object?> w => [
                for (final d in w)
                  if (d is int && d >= 1 && d <= 7) d,
              ],
              _ => null,
            },
            occurrenceCount: switch (r['c']) {
              final int c when c > 0 => c,
              _ => null,
            },
            endDate: _day(r['u']),
            dates: days(r['x']),
            exceptions: days(r['s']),
          );
        }
      }
      String? text(String key, int max) {
        final v = (json[key] as String?)?.trim();
        return v == null || v.isEmpty ? null : _cut(v, max);
      }

      return SharedEvent(
        title: _cut(title, _maxTitle),
        date: date,
        time: time,
        description: text('n', _maxText),
        location: text('l', _maxTitle),
        categoryName: text('g', _maxTitle),
        recurrence: rule,
      );
    } on Object {
      return null;
    }
  }

  static DateTime? _day(Object? v) {
    if (v is! String) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
    if (m == null) return null;
    final d = DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    // Reject 2026-02-31 and the like.
    return d.month == int.parse(m[2]!) ? d : null;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _cut(String s, int max) =>
      s.length > max ? s.substring(0, max) : s;
}

/// An event read from a shared link, before it's added.
class SharedEvent {
  const SharedEvent({
    required this.title,
    required this.date,
    this.time,
    this.description,
    this.location,
    this.categoryName,
    this.recurrence,
  });

  final String title;

  /// The first day, at midnight.
  final DateTime date;

  /// The time on [date]; null for all day.
  final DateTime? time;
  final String? description;
  final String? location;

  /// The sender's category, used when the receiver has one by that name.
  final String? categoryName;
  final RecurrenceRule? recurrence;

  bool get allDay => time == null;

  /// A new event in [category], or the receiver's category named
  /// [categoryName] when [categories] has one.
  Event toEvent({
    required EventCategory category,
    List<EventCategory> categories = const [],
    DateTime? now,
  }) {
    final stamp = now ?? DateTime.now();
    final match = categories
        .where((c) => c.name.toLowerCase() == categoryName?.toLowerCase())
        .firstOrNull;
    return Event(
      title: title,
      description: description,
      eventDate: date,
      eventTime: time,
      isAllDay: allDay,
      location: location,
      category: match ?? category,
      recurrenceRule: recurrence,
      createdAt: stamp,
      updatedAt: stamp,
    );
  }
}
