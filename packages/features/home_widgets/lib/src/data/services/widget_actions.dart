import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_widget_payload/shared_widget_payload.dart';

/// An event ticked done (or not done) on a home-screen widget.
@immutable
class WidgetEventToggle {
  const WidgetEventToggle({
    required this.id,
    required this.date,
    required this.done,
    this.recurring = false,
  });

  final int id;

  /// The occurrence's day.
  final DateTime date;
  final bool done;

  /// A repeating event: only [date]'s occurrence changes.
  final bool recurring;

  /// What the native widgets write: `{"id": 5, "d": "2026-11-13",
  /// "rec": false, "done": true}`. Null when it can't be read.
  static WidgetEventToggle? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final date = DateTime.tryParse('${json['d']}');
    final done = json['done'];
    if (id is! int || date == null || done is! bool) return null;
    return WidgetEventToggle(
      id: id,
      date: DateTime(date.year, date.month, date.day),
      done: done,
      recurring: json['rec'] == true,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'd':
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}',
    'rec': recurring,
    'done': done,
  };

  /// The same occurrence: the same event on the same day.
  bool sameOccurrence(WidgetEventToggle other) =>
      id == other.id && date == other.date;

  bool matches(WidgetAgendaEvent event) =>
      event.id == id &&
      event.date.year == date.year &&
      event.date.month == date.month &&
      event.date.day == date.day;

  @override
  bool operator ==(Object other) =>
      other is WidgetEventToggle &&
      sameOccurrence(other) &&
      done == other.done &&
      recurring == other.recurring;

  @override
  int get hashCode => Object.hash(id, date, done, recurring);

  @override
  String toString() => 'WidgetEventToggle(${toJson()})';
}

/// Ticks made on the widgets, waiting for the app.
///
/// The widgets can't reach the events database, so their own code (iOS
/// `ToggleEventIntent`, Android `ToggleEventAction`) flips the event in the
/// saved payload, which redraws the widget at once, and adds a
/// [WidgetEventToggle] to this queue. The app applies the queue when it
/// starts or comes back ([apply]); until then a refresh that draws from
/// the cached events shows the ticks too ([overlay]).
///
/// The queue lives where home_widget keeps its data (the app group on iOS,
/// `HomeWidgetPreferences` on Android), as a JSON list under [key].
abstract final class WidgetActions {
  static const key = 'widget_actions_v1';

  /// The queue in [raw], oldest first; entries that can't be read are
  /// skipped.
  static List<WidgetEventToggle> parse(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [for (final item in list) ?WidgetEventToggle.fromJson(item)];
    } on FormatException {
      return const [];
    }
  }

  /// The last toggle for each occurrence: ticking twice cancels out to
  /// whatever the second tap set.
  static List<WidgetEventToggle> latest(List<WidgetEventToggle> toggles) {
    final out = <WidgetEventToggle>[];
    for (final t in toggles) {
      out.removeWhere(t.sameOccurrence);
      out.add(t);
    }
    return out;
  }

  /// [events] with the queued ticks applied.
  static List<WidgetAgendaEvent> overlay(
    List<WidgetAgendaEvent> events,
    List<WidgetEventToggle> toggles,
  ) {
    if (toggles.isEmpty) return events;
    final last = latest(toggles);
    return [
      for (final e in events)
        switch (last.where((t) => t.matches(e)).firstOrNull) {
          final t? => e.copyWith(done: t.done),
          null => e,
        },
    ];
  }

  static Future<List<WidgetEventToggle>> read() async {
    try {
      return parse(await HomeWidget.getWidgetData<String>(key));
    } catch (e) {
      debugPrint('Widget actions unavailable: $e');
      return const [];
    }
  }

  /// Applies the queued ticks with [toggle] and removes them from the
  /// queue. Ticks added while this runs are kept for next time; a tick that
  /// fails (its event was deleted, say) is dropped. Returns how many were
  /// applied.
  static Future<int> apply(
    Future<void> Function(WidgetEventToggle toggle) toggle,
  ) async {
    final queued = await read();
    if (queued.isEmpty) return 0;
    var applied = 0;
    for (final t in latest(queued)) {
      try {
        await toggle(t);
        applied++;
      } catch (e) {
        debugPrint('Widget tick not applied ($t): $e');
      }
    }
    // Keep only what arrived after the read. Never write null: on iOS that
    // reaches UserDefaults as NSNull, which terminates the app.
    final now = await read();
    final rest = now.length > queued.length
        ? now.sublist(queued.length)
        : const <WidgetEventToggle>[];
    await HomeWidget.saveWidgetData<String>(
      key,
      jsonEncode([for (final t in rest) t.toJson()]),
    );
    return applied;
  }

  /// Applies the queue through the events feature's completion, the same
  /// call day details makes.
  static Future<int> applyWith(EventMarkersPort events) => apply(
    (t) => events.toggleEventCompletion(
      eventId: t.id,
      isCompleted: t.done,
      isRecurring: t.recurring,
      occurrenceDate: t.date,
    ),
  );
}
