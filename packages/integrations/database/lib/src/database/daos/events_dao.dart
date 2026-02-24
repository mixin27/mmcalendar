import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_events_table.dart';

part 'events_dao.g.dart';

@DriftAccessor(tables: [UserEvents, EventCategories])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.db);

  // ========== USER EVENTS ==========

  Future<List<UserEvent>> getAllEvents() {
    return (select(
      userEvents,
    )..orderBy([(e) => OrderingTerm.asc(e.eventDate)])).get();
  }

  Future<List<UserEvent>> getAllIncompleteEvents() {
    return (select(userEvents)
          ..where((e) => e.isCompleted.equals(false))
          ..orderBy([(e) => OrderingTerm.asc(e.eventDate)]))
        .get();
  }

  Future<List<UserEvent>> getAllCompletedEvents() {
    return (select(userEvents)
          ..where((e) => e.isCompleted.equals(true))
          ..orderBy([(e) => OrderingTerm.asc(e.eventDate)]))
        .get();
  }

  Future<List<UserEvent>> getEventsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(userEvents)..where(
          (e) =>
              e.eventDate.isBiggerOrEqualValue(startOfDay) &
              e.eventDate.isSmallerThanValue(endOfDay) &
              e.isCompleted.equals(false),
        ))
        .get();
  }

  Future<List<UserEvent>> getEventsByDateRange(DateTime start, DateTime end) {
    return (select(userEvents)
          ..where(
            (e) =>
                e.eventDate.isBiggerOrEqualValue(start) &
                e.eventDate.isSmallerOrEqualValue(end) &
                e.isCompleted.equals(false),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.eventDate)]))
        .get();
  }

  Future<UserEvent?> getEventById(int id) {
    return (select(
      userEvents,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  Future<List<UserEvent>> getEventsByCategory(String category) {
    return (select(userEvents)..where(
          (e) => e.category.equals(category) & e.isCompleted.equals(false),
        ))
        .get();
  }

  Future<int> createEvent(UserEventsCompanion event) {
    return into(userEvents).insert(event);
  }

  Future<bool> updateEvent(UserEventsCompanion event) {
    return update(userEvents).replace(event);
  }

  Future<int> deleteEvent(int id) {
    return (delete(userEvents)..where((e) => e.id.equals(id))).go();
  }

  Future<void> toggleComplete(int id, bool isCompleted) async {
    await (update(userEvents)..where((e) => e.id.equals(id))).write(
      UserEventsCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? DateTime.now() : null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<UserEvent>> watchAllEvents() {
    return (select(userEvents)
          ..where((e) => e.isCompleted.equals(false))
          ..orderBy([(e) => OrderingTerm.asc(e.eventDate)]))
        .watch();
  }

  Stream<UserEvent?> watchEventById(int id) {
    return (select(
      userEvents,
    )..where((e) => e.id.equals(id))).watchSingleOrNull();
  }

  // ========== CATEGORIES ==========

  Future<List<EventCategory>> getAllCategories() {
    return (select(
      eventCategories,
    )..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).get();
  }

  Future<int> createCategory(EventCategoriesCompanion category) {
    return into(eventCategories).insert(category);
  }

  Future<int> deleteCategory(int id) {
    return (delete(eventCategories)..where((c) => c.id.equals(id))).go();
  }

  /// Get category by ID
  Future<EventCategory?> getCategoryById(int id) {
    return (select(
      eventCategories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Get default categories
  Future<List<EventCategory>> getDefaultCategories() {
    return (select(
      eventCategories,
    )..where((c) => c.isDefault.equals(true))).get();
  }

  /// Update category
  Future<bool> updateCategory(EventCategoriesCompanion category) {
    return update(eventCategories).replace(category);
  }

  Future<void> initializeDefaultCategories() async {
    final categories = [
      EventCategoriesCompanion.insert(
        name: 'Personal',
        iconName: 'person',
        colorCode: 0xFF2196F3, // Blue
        isDefault: const Value(true),
        sortOrder: 1,
        createdAt: DateTime.now(),
      ),
      EventCategoriesCompanion.insert(
        name: 'Work',
        iconName: 'work',
        colorCode: 0xFF4CAF50, // Green
        isDefault: const Value(true),
        sortOrder: 2,
        createdAt: DateTime.now(),
      ),
      EventCategoriesCompanion.insert(
        name: 'Religious',
        iconName: 'auto_awesome',
        colorCode: 0xFFFF9800, // Orange
        isDefault: const Value(true),
        sortOrder: 3,
        createdAt: DateTime.now(),
      ),
      EventCategoriesCompanion.insert(
        name: 'Family',
        iconName: 'family_restroom',
        colorCode: 0xFFE91E63, // Pink
        isDefault: const Value(true),
        sortOrder: 4,
        createdAt: DateTime.now(),
      ),
      EventCategoriesCompanion.insert(
        name: 'Health',
        iconName: 'favorite',
        colorCode: 0xFFF44336, // Red
        isDefault: const Value(true),
        sortOrder: 5,
        createdAt: DateTime.now(),
      ),
    ];

    for (final category in categories) {
      await into(
        eventCategories,
      ).insert(category, mode: InsertMode.insertOrIgnore);
    }
  }
}
