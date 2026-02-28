import 'package:integrations_database/integrations_database.dart' as db;
import 'package:flutter/foundation.dart';

class DatabaseEventChecker {
  final db.AppDatabase database;

  DatabaseEventChecker(this.database);

  Future<void> checkRecurringEvents() async {
    final dao = database.eventsV2Dao;
    final allEvents = await dao.getAllEvents();
    final recurrenceByEventId = await dao.getRecurrenceRulesForEventIds(
      allEvents.map((event) => event.id),
    );

    debugPrint('\n${'=' * 60}');
    debugPrint('DATABASE RECURRING EVENTS CHECK');
    debugPrint('=' * 60);

    // Group recurring masters by title + recurrence type.
    final grouped = <String, List<db.CalendarEvent>>{};
    for (final event in allEvents) {
      final recurrence = recurrenceByEventId[event.id];
      if (recurrence == null) continue;

      final key = '${event.title}|${recurrence.recurrenceType}';
      grouped[key] = [...(grouped[key] ?? const []), event];
    }

    for (final entry in grouped.entries) {
      final parts = entry.key.split('|');
      final title = parts[0];
      final recurrenceType = parts[1];
      final count = entry.value.length;

      if (count == 1) {
        debugPrint('✅ "$title" ($recurrenceType): 1 master event - CORRECT');
      } else {
        debugPrint('❌ "$title" ($recurrenceType): $count rows - PROBLEM!');
        debugPrint('   IDs: ${entry.value.map((e) => e.id).join(", ")}');
        debugPrint(
          '   Dates: ${entry.value.map((e) => e.eventDate).join(", ")}',
        );
      }
    }

    debugPrint('=' * 60 + '\n');
  }

  Future<void> cleanupDuplicateRecurringEvents() async {
    debugPrint('Cleaning up duplicate recurring events...');

    await database.customStatement('''
      DELETE FROM calendar_events
      WHERE id IN (
        SELECT ce.id
        FROM calendar_events ce
        JOIN event_recurrence_rules rr ON rr.event_id = ce.id
        WHERE ce.id NOT IN (
          SELECT MIN(ce2.id)
          FROM calendar_events ce2
          JOIN event_recurrence_rules rr2 ON rr2.event_id = ce2.id
          GROUP BY ce2.title, rr2.recurrence_type
        )
      )
    ''');

    debugPrint('✅ Cleanup complete');
  }
}
