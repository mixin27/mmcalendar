import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/event_categories_table.dart';

part 'events_dao.g.dart';

@DriftAccessor(tables: [EventCategories])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.db);

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
