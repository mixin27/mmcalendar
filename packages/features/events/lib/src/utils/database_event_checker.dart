import 'package:data/data.dart' as db;
import 'package:flutter/foundation.dart';

class DatabaseEventChecker {
  final db.AppDatabase database;

  DatabaseEventChecker(this.database);

  Future<void> checkRecurringEvents() async {
    final dao = database.eventsDao;

    // Get all events with recurrence
    final allEvents = await dao.getAllEvents();
    final recurringEvents = allEvents
        .where((e) => e.recurrenceType != null && e.recurrenceType!.isNotEmpty)
        .toList();

    debugPrint('\n${'=' * 60}');
    debugPrint('DATABASE RECURRING EVENTS CHECK');
    debugPrint('=' * 60);

    // Group by title and recurrence type
    final grouped = <String, List<db.UserEvent>>{};
    for (final event in recurringEvents) {
      final key = '${event.title}|${event.recurrenceType}';
      grouped[key] = [...(grouped[key] ?? []), event];
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
    // final dao = database.eventsDao;

    debugPrint('Cleaning up duplicate recurring events...');

    // This SQL will keep only the first occurrence of each recurring event
    await database.customStatement('''
      DELETE FROM user_events
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM user_events
        WHERE recurrence_type IS NOT NULL
        GROUP BY title, recurrence_type
      )
      AND recurrence_type IS NOT NULL
    ''');

    debugPrint('✅ Cleanup complete');
  }
}
