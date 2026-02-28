import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/events_v2_tables.dart';

part 'events_v2_dao.g.dart';

@DriftAccessor(tables: [CalendarEvents, EventReminders, EventRecurrenceRules])
class EventsV2Dao extends DatabaseAccessor<AppDatabase>
    with _$EventsV2DaoMixin {
  EventsV2Dao(super.db);

  // ============================================================================
  // EVENT MASTER
  // ============================================================================

  Future<int> createEvent(CalendarEventsCompanion event) {
    return into(calendarEvents).insert(event);
  }

  Future<bool> updateEvent(CalendarEventsCompanion event) {
    return update(calendarEvents).replace(event);
  }

  Future<int> deleteEvent(int id) {
    return (delete(calendarEvents)..where((e) => e.id.equals(id))).go();
  }

  Future<CalendarEvent?> getEventById(int id) {
    return (select(
      calendarEvents,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  Future<List<CalendarEvent>> getAllEvents() {
    return (select(calendarEvents)..orderBy([
          (e) => OrderingTerm.asc(e.eventDate),
          (e) => OrderingTerm.asc(e.eventTime),
        ]))
        .get();
  }

  Future<List<CalendarEvent>> getAllIncompleteEvents() {
    return (select(calendarEvents)
          ..where((e) => e.status.isNotValue('completed'))
          ..orderBy([
            (e) => OrderingTerm.asc(e.eventDate),
            (e) => OrderingTerm.asc(e.eventTime),
          ]))
        .get();
  }

  Future<List<CalendarEvent>> getAllCompletedEvents() {
    return (select(calendarEvents)
          ..where((e) => e.status.equals('completed'))
          ..orderBy([
            (e) => OrderingTerm.asc(e.eventDate),
            (e) => OrderingTerm.asc(e.eventTime),
          ]))
        .get();
  }

  Future<List<CalendarEvent>> getEventsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(calendarEvents)
          ..where(
            (e) =>
                e.eventDate.isBiggerOrEqualValue(startOfDay) &
                e.eventDate.isSmallerThanValue(endOfDay) &
                e.status.isNotValue('completed'),
          )
          ..orderBy([
            (e) => OrderingTerm.asc(e.eventDate),
            (e) => OrderingTerm.asc(e.eventTime),
          ]))
        .get();
  }

  Future<List<CalendarEvent>> getEventsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(calendarEvents)
          ..where(
            (e) =>
                e.eventDate.isBiggerOrEqualValue(start) &
                e.eventDate.isSmallerOrEqualValue(end) &
                e.status.isNotValue('completed'),
          )
          ..orderBy([
            (e) => OrderingTerm.asc(e.eventDate),
            (e) => OrderingTerm.asc(e.eventTime),
          ]))
        .get();
  }

  Future<List<CalendarEvent>> getEventsByCategoryName(String categoryName) {
    return (select(calendarEvents)
          ..where(
            (e) =>
                e.categoryName.equals(categoryName) &
                e.status.isNotValue('completed'),
          )
          ..orderBy([
            (e) => OrderingTerm.asc(e.eventDate),
            (e) => OrderingTerm.asc(e.eventTime),
          ]))
        .get();
  }

  Future<void> updateEventCompletion({
    required int eventId,
    required bool isCompleted,
    required DateTime now,
  }) {
    return (update(calendarEvents)..where((e) => e.id.equals(eventId))).write(
      CalendarEventsCompanion(
        status: Value(isCompleted ? 'completed' : 'pending'),
        completedAt: Value(isCompleted ? now : null),
        updatedAt: Value(now),
      ),
    );
  }

  Stream<List<CalendarEvent>> watchAllEvents() {
    return (select(calendarEvents)
          ..where((e) => e.status.isNotValue('completed'))
          ..orderBy([
            (e) => OrderingTerm.asc(e.eventDate),
            (e) => OrderingTerm.asc(e.eventTime),
          ]))
        .watch();
  }

  Stream<CalendarEvent?> watchEventById(int id) {
    return (select(
      calendarEvents,
    )..where((e) => e.id.equals(id))).watchSingleOrNull();
  }

  // ============================================================================
  // REMINDERS
  // ============================================================================

  Future<List<EventReminder>> getRemindersForEvent(int eventId) {
    return (select(eventReminders)
          ..where((r) => r.eventId.equals(eventId))
          ..orderBy([(r) => OrderingTerm.desc(r.minutesBefore)]))
        .get();
  }

  Future<Map<int, List<EventReminder>>> getRemindersForEventIds(
    Iterable<int> eventIds,
  ) async {
    final ids = eventIds.toSet().toList(growable: false);
    if (ids.isEmpty) return <int, List<EventReminder>>{};

    final rows = await (select(
      eventReminders,
    )..where((r) => r.eventId.isIn(ids))).get();

    final map = <int, List<EventReminder>>{};
    for (final row in rows) {
      final bucket = map.putIfAbsent(row.eventId, () => <EventReminder>[]);
      bucket.add(row);
    }

    for (final bucket in map.values) {
      bucket.sort((a, b) => b.minutesBefore.compareTo(a.minutesBefore));
    }
    return map;
  }

  Future<void> replaceRemindersForEvent(
    int eventId,
    List<EventRemindersCompanion> reminders,
  ) async {
    await transaction(() async {
      await (delete(
        eventReminders,
      )..where((r) => r.eventId.equals(eventId))).go();
      if (reminders.isEmpty) return;
      await batch((batch) {
        batch.insertAll(
          eventReminders,
          reminders,
          mode: InsertMode.insertOrIgnore,
        );
      });
    });
  }

  // ============================================================================
  // RECURRENCE
  // ============================================================================

  Future<EventRecurrenceRule?> getRecurrenceRuleForEvent(int eventId) {
    return (select(
      eventRecurrenceRules,
    )..where((r) => r.eventId.equals(eventId))).getSingleOrNull();
  }

  Future<Map<int, EventRecurrenceRule>> getRecurrenceRulesForEventIds(
    Iterable<int> eventIds,
  ) async {
    final ids = eventIds.toSet().toList(growable: false);
    if (ids.isEmpty) return <int, EventRecurrenceRule>{};

    final rows = await (select(
      eventRecurrenceRules,
    )..where((r) => r.eventId.isIn(ids))).get();

    final map = <int, EventRecurrenceRule>{};
    for (final row in rows) {
      map[row.eventId] = row;
    }
    return map;
  }

  Future<void> upsertRecurrenceRule(EventRecurrenceRulesCompanion rule) {
    return into(eventRecurrenceRules).insertOnConflictUpdate(rule);
  }

  Future<void> deleteRecurrenceRuleForEvent(int eventId) {
    return (delete(
      eventRecurrenceRules,
    )..where((r) => r.eventId.equals(eventId))).go();
  }
}
