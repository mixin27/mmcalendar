import 'package:shared_core/shared_core.dart';
import 'package:integrations_database/integrations_database.dart' as db;

import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../../utils/event_creation_diagnostic.dart';
import '../models/event_category_model.dart';
import '../models/event_model.dart';

/// Abstract local data source for events
abstract class EventsLocalDataSource {
  // Event operations
  Future<EventModel> createEvent(EventModel event);
  Future<EventModel> updateEvent(EventModel event);
  Future<void> deleteEvent(int eventId);
  Future<EventModel?> getEventById(int eventId);
  Future<List<EventModel>> getAllEvents({bool includeCompleted = false});
  Future<List<EventModel>> getEventsByDate(DateTime date);
  Future<List<EventModel>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<EventModel>> getEventsByCategory(String category);
  Future<List<EventModel>> getEventsByStatus(EventStatus status);
  Future<List<EventModel>> searchEvents(String query);
  Future<EventModel> toggleEventCompletion(int eventId, bool isCompleted);

  // Stream operations
  Stream<List<EventModel>> watchAllEvents();
  Stream<List<EventModel>> watchEventsByDate(DateTime date);
  Stream<List<EventModel>> watchEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Stream<EventModel?> watchEventById(int eventId);

  // Category operations
  Future<List<EventCategoryModel>> getAllCategories();
  Future<EventCategoryModel> createCategory(EventCategoryModel category);
  Future<EventCategoryModel> updateCategory(EventCategoryModel category);
  Future<void> deleteCategory(int categoryId);
  Future<EventCategoryModel?> getCategoryById(int categoryId);
  Future<void> initializeDefaultCategories();
}

/// Implementation of local data source using normalized Drift event schema.
class EventsLocalDataSourceImpl implements EventsLocalDataSource {
  final db.AppDatabase database;
  late final db.EventsV2Dao _eventsDao;
  late final db.EventsDao _categoryDao;
  late final db.RecurringExceptionsDao _exceptionsDao;

  EventsLocalDataSourceImpl(this.database) {
    _eventsDao = database.eventsV2Dao;
    _categoryDao = database.eventsDao;
    _exceptionsDao = database.recurringExceptionsDao;
  }

  // ============================================================================
  // EVENT OPERATIONS
  // ============================================================================

  @override
  Future<EventModel> createEvent(EventModel event) async {
    try {
      EventCreationDiagnostic.logDatasourceCreateStart(event.title);

      final resolvedCategory = await _resolveCategoryForInput(event.category);

      final created = await database.transaction(() async {
        final id = await _eventsDao.createEvent(
          event.toCalendarEventCompanion(category: resolvedCategory),
        );

        await _persistRecurrenceAndReminders(
          eventId: id,
          event: event,
          now: DateTime.now(),
        );

        final created = await _eventsDao.getEventById(id);
        if (created == null) {
          throw CacheException('Failed to create event');
        }
        return created;
      });

      return _hydrateEvent(created, resolvedCategory: resolvedCategory);
    } catch (e) {
      throw CacheException('Failed to create event: ${e.toString()}');
    }
  }

  @override
  Future<EventModel> updateEvent(EventModel event) async {
    try {
      if (event.id == null) {
        throw CacheException('Event ID is required for update');
      }

      final resolvedCategory = await _resolveCategoryForInput(event.category);

      final updated = await database.transaction(() async {
        final success = await _eventsDao.updateEvent(
          event.toCalendarEventCompanion(category: resolvedCategory),
        );

        if (!success) {
          throw CacheException('Failed to update event');
        }

        await _persistRecurrenceAndReminders(
          eventId: event.id!,
          event: event,
          now: DateTime.now(),
        );

        final updated = await _eventsDao.getEventById(event.id!);
        if (updated == null) {
          throw CacheException('Event not found after update');
        }
        return updated;
      });

      return _hydrateEvent(updated, resolvedCategory: resolvedCategory);
    } catch (e) {
      throw CacheException('Failed to update event: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteEvent(int eventId) async {
    try {
      await database.transaction(() async {
        final deleted = await _eventsDao.deleteEvent(eventId);
        if (deleted == 0) {
          throw CacheException('Event not found');
        }

        // Keep exceptions table consistent even if legacy rows still exist.
        await _exceptionsDao.deleteExceptionsForEvent(eventId);
      });
    } catch (e) {
      throw CacheException('Failed to delete event: ${e.toString()}');
    }
  }

  @override
  Future<EventModel?> getEventById(int eventId) async {
    try {
      final event = await _eventsDao.getEventById(eventId);
      if (event == null) return null;
      return _hydrateEvent(event);
    } catch (e) {
      throw CacheException('Failed to get event: ${e.toString()}');
    }
  }

  @override
  Future<List<EventModel>> getAllEvents({bool includeCompleted = false}) async {
    try {
      final events = includeCompleted
          ? await _eventsDao.getAllEvents()
          : await _eventsDao.getAllIncompleteEvents();
      return _hydrateEvents(events);
    } catch (e) {
      throw CacheException('Failed to get all events: ${e.toString()}');
    }
  }

  @override
  Future<List<EventModel>> getEventsByDate(DateTime date) async {
    try {
      final events = await _eventsDao.getEventsByDate(date);
      return _hydrateEvents(events);
    } catch (e) {
      throw CacheException('Failed to get events by date: ${e.toString()}');
    }
  }

  @override
  Future<List<EventModel>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Keep behavior compatible with recurrence expansion in repository:
      // return all master events so virtual instances can be generated.
      final events = await _eventsDao.getAllEvents();
      return _hydrateEvents(events);
    } catch (e) {
      throw CacheException(
        'Failed to get events by date range: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<EventModel>> getEventsByCategory(String category) async {
    try {
      final events = await _eventsDao.getEventsByCategoryName(category);
      return _hydrateEvents(events);
    } catch (e) {
      throw CacheException('Failed to get events by category: ${e.toString()}');
    }
  }

  @override
  Future<List<EventModel>> getEventsByStatus(EventStatus status) async {
    try {
      final events = await _eventsDao.getAllEvents();
      final filtered = events
          .where((event) {
            final eventStatus = EventModel.parseStatus(event.status);
            return status == eventStatus;
          })
          .toList(growable: false);
      return _hydrateEvents(filtered);
    } catch (e) {
      throw CacheException('Failed to get events by status: ${e.toString()}');
    }
  }

  @override
  Future<List<EventModel>> searchEvents(String query) async {
    try {
      final normalizedQuery = query.trim().toLowerCase();
      final events = await _eventsDao.getAllEvents();
      final filtered = events
          .where((event) {
            final titleMatch = event.title.toLowerCase().contains(
              normalizedQuery,
            );
            final descMatch =
                event.description?.toLowerCase().contains(normalizedQuery) ??
                false;
            return titleMatch || descMatch;
          })
          .toList(growable: false);

      return _hydrateEvents(filtered);
    } catch (e) {
      throw CacheException('Failed to search events: ${e.toString()}');
    }
  }

  @override
  Future<EventModel> toggleEventCompletion(
    int eventId,
    bool isCompleted,
  ) async {
    try {
      final now = DateTime.now();
      await _eventsDao.updateEventCompletion(
        eventId: eventId,
        isCompleted: isCompleted,
        now: now,
      );

      final updated = await _eventsDao.getEventById(eventId);
      if (updated == null) {
        throw CacheException('Event not found');
      }

      return _hydrateEvent(updated);
    } catch (e) {
      throw CacheException('Failed to toggle completion: ${e.toString()}');
    }
  }

  // ============================================================================
  // STREAM OPERATIONS
  // ============================================================================

  @override
  Stream<List<EventModel>> watchAllEvents() {
    try {
      return _eventsDao.watchAllEvents().asyncMap(_hydrateEvents);
    } catch (e) {
      throw CacheException('Failed to watch all events: ${e.toString()}');
    }
  }

  @override
  Stream<List<EventModel>> watchEventsByDate(DateTime date) {
    return watchEventsByDateRange(date, date.add(const Duration(days: 1)));
  }

  @override
  Stream<List<EventModel>> watchEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      // Keep behavior compatible with recurrence expansion in repository:
      // watch all masters, repository applies range and recurrence.
      return _eventsDao.watchAllEvents().asyncMap(_hydrateEvents);
    } catch (e) {
      throw CacheException('Failed to watch events by range: ${e.toString()}');
    }
  }

  @override
  Stream<EventModel?> watchEventById(int eventId) {
    try {
      return _eventsDao.watchEventById(eventId).asyncMap((event) async {
        if (event == null) return null;
        return _hydrateEvent(event);
      });
    } catch (e) {
      throw CacheException('Failed to watch event: ${e.toString()}');
    }
  }

  // ============================================================================
  // CATEGORY OPERATIONS
  // ============================================================================

  @override
  Future<List<EventCategoryModel>> getAllCategories() async {
    try {
      final categories = await _categoryDao.getAllCategories();
      return categories
          .map((category) => EventCategoryModel.fromDatabaseEntity(category))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get categories: ${e.toString()}');
    }
  }

  @override
  Future<EventCategoryModel> createCategory(EventCategoryModel category) async {
    try {
      final companion = category.toDatabaseCompanion();
      final id = await _categoryDao.createCategory(companion);
      final created = await _categoryDao.getCategoryById(id);

      if (created == null) {
        throw CacheException('Failed to create category');
      }

      return EventCategoryModel.fromDatabaseEntity(created);
    } catch (e) {
      throw CacheException('Failed to create category: ${e.toString()}');
    }
  }

  @override
  Future<EventCategoryModel> updateCategory(EventCategoryModel category) async {
    try {
      if (category.id == null) {
        throw CacheException('Category ID is required for update');
      }

      final companion = category.toDatabaseCompanion();
      final success = await _categoryDao.updateCategory(companion);

      if (!success) {
        throw CacheException('Failed to update category');
      }

      final updated = await _categoryDao.getCategoryById(category.id!);
      if (updated == null) {
        throw CacheException('Category not found after update');
      }

      return EventCategoryModel.fromDatabaseEntity(updated);
    } catch (e) {
      throw CacheException('Failed to update category: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCategory(int categoryId) async {
    try {
      final deleted = await _categoryDao.deleteCategory(categoryId);
      if (deleted == 0) {
        throw CacheException('Category not found');
      }
    } catch (e) {
      throw CacheException('Failed to delete category: ${e.toString()}');
    }
  }

  @override
  Future<EventCategoryModel?> getCategoryById(int categoryId) async {
    try {
      final category = await _categoryDao.getCategoryById(categoryId);
      if (category == null) return null;
      return EventCategoryModel.fromDatabaseEntity(category);
    } catch (e) {
      throw CacheException('Failed to get category: ${e.toString()}');
    }
  }

  @override
  Future<void> initializeDefaultCategories() async {
    try {
      await _categoryDao.initializeDefaultCategories();
    } catch (e) {
      throw CacheException('Failed to initialize categories: ${e.toString()}');
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  Future<void> _persistRecurrenceAndReminders({
    required int eventId,
    required EventModel event,
    required DateTime now,
  }) async {
    final recurrenceCompanion = event.toRecurrenceCompanion(
      eventId: eventId,
      now: now,
    );
    if (recurrenceCompanion == null) {
      await _eventsDao.deleteRecurrenceRuleForEvent(eventId);
    } else {
      await _eventsDao.upsertRecurrenceRule(recurrenceCompanion);
    }

    final reminderCompanions = event.toReminderCompanions(
      eventId: eventId,
      now: now,
    );
    await _eventsDao.replaceRemindersForEvent(eventId, reminderCompanions);
  }

  Future<EventCategory> _resolveCategoryForInput(EventCategory category) async {
    if (category.id != null) {
      final byId = await _categoryDao.getCategoryById(category.id!);
      if (byId != null) {
        return EventCategoryModel.fromDatabaseEntity(byId);
      }
    }

    final all = await _categoryDao.getAllCategories();
    final byName = all.where((item) => item.name == category.name).toList();
    if (byName.isNotEmpty) {
      return EventCategoryModel.fromDatabaseEntity(byName.first);
    }

    return EventCategory.personal;
  }

  Future<EventModel> _hydrateEvent(
    db.CalendarEvent event, {
    EventCategory? resolvedCategory,
  }) async {
    final recurrence = await _eventsDao.getRecurrenceRuleForEvent(event.id);
    final reminders = await _eventsDao.getRemindersForEvent(event.id);

    final category =
        resolvedCategory ?? await _resolveCategoryForStoredEvent(event);
    return EventModel.fromV2DatabaseEntity(
      event,
      category: category,
      recurrenceRule: recurrence,
      reminders: reminders,
    );
  }

  Future<List<EventModel>> _hydrateEvents(List<db.CalendarEvent> events) async {
    if (events.isEmpty) return const [];

    final eventIds = events.map((event) => event.id).toList(growable: false);
    final recurrenceMap = await _eventsDao.getRecurrenceRulesForEventIds(
      eventIds,
    );
    final remindersMap = await _eventsDao.getRemindersForEventIds(eventIds);

    final categories = await _categoryDao.getAllCategories();
    final categoriesById = <int, db.EventCategory>{
      for (final category in categories) category.id: category,
    };
    final categoriesByName = <String, db.EventCategory>{
      for (final category in categories) category.name: category,
    };

    return events
        .map((event) {
          final category = _resolveCategoryFromCaches(
            event: event,
            categoriesById: categoriesById,
            categoriesByName: categoriesByName,
          );
          return EventModel.fromV2DatabaseEntity(
            event,
            category: category,
            recurrenceRule: recurrenceMap[event.id],
            reminders: remindersMap[event.id] ?? const [],
          );
        })
        .toList(growable: false);
  }

  Future<EventCategory> _resolveCategoryForStoredEvent(
    db.CalendarEvent event,
  ) async {
    if (event.categoryId != null) {
      final category = await _categoryDao.getCategoryById(event.categoryId!);
      if (category != null) {
        return EventCategoryModel.fromDatabaseEntity(category);
      }
    }

    final categories = await _categoryDao.getAllCategories();
    final matching = categories
        .where((category) => category.name == event.categoryName)
        .toList();
    if (matching.isNotEmpty) {
      return EventCategoryModel.fromDatabaseEntity(matching.first);
    }
    return EventCategory.personal;
  }

  EventCategory _resolveCategoryFromCaches({
    required db.CalendarEvent event,
    required Map<int, db.EventCategory> categoriesById,
    required Map<String, db.EventCategory> categoriesByName,
  }) {
    if (event.categoryId != null) {
      final byId = categoriesById[event.categoryId!];
      if (byId != null) {
        return EventCategoryModel.fromDatabaseEntity(byId);
      }
    }

    final byName = categoriesByName[event.categoryName];
    if (byName != null) {
      return EventCategoryModel.fromDatabaseEntity(byName);
    }

    return EventCategory.personal;
  }
}
