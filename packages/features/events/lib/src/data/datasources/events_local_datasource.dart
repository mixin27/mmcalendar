import 'package:core/core.dart';
import 'package:data/data.dart' as db;

import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../models/event_category_model.dart';
import '../models/event_model.dart';

/// Abstract local data source for events
abstract class EventsLocalDataSource {
  // Event operations
  Future<EventModel> createEvent(EventModel event);
  Future<EventModel> updateEvent(EventModel event);
  Future<void> deleteEvent(int eventId);
  Future<EventModel?> getEventById(int eventId);
  Future<List<EventModel>> getAllEvents();
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

/// Implementation of local data source using Drift database
class EventsLocalDataSourceImpl implements EventsLocalDataSource {
  final db.AppDatabase database;
  late final db.EventsDao _dao;

  EventsLocalDataSourceImpl(this.database) {
    _dao = database.eventsDao;
  }

  // ============================================================================
  // EVENT OPERATIONS
  // ============================================================================

  @override
  Future<EventModel> createEvent(EventModel event) async {
    try {
      // Get category if needed
      EventCategory? category = event.category;
      if (category.id == null && category.name.isNotEmpty) {
        final categories = await _dao.getAllCategories();
        final matching = categories.where((c) => c.name == event.category.name);
        if (matching.isNotEmpty) {
          // convert DB entity to domain model before assigning
          category = EventCategoryModel.fromDatabaseEntity(matching.first);
        } else {
          category = EventCategory.personal;
        }
      }

      final companion = event.toDatabaseCompanion();
      final id = await _dao.createEvent(companion);
      final created = await _dao.getEventById(id);

      if (created == null) {
        throw CacheException('Failed to create event');
      }

      return EventModel.fromDatabaseEntity(created, category);
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

      final companion = event.toDatabaseCompanion();
      final success = await _dao.updateEvent(companion);

      if (!success) {
        throw CacheException('Failed to update event');
      }

      final updated = await _dao.getEventById(event.id!);
      if (updated == null) {
        throw CacheException('Event not found after update');
      }

      return EventModel.fromDatabaseEntity(updated, event.category);
    } catch (e) {
      throw CacheException('Failed to update event: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteEvent(int eventId) async {
    try {
      final deleted = await _dao.deleteEvent(eventId);
      if (deleted == 0) {
        throw CacheException('Event not found');
      }
    } catch (e) {
      throw CacheException('Failed to delete event: ${e.toString()}');
    }
  }

  @override
  Future<EventModel?> getEventById(int eventId) async {
    try {
      final event = await _dao.getEventById(eventId);
      if (event == null) return null;

      final category = await _getCategoryForEvent(event);
      return EventModel.fromDatabaseEntity(event, category);
    } catch (e) {
      throw CacheException('Failed to get event: ${e.toString()}');
    }
  }

  @override
  Future<List<EventModel>> getAllEvents() async {
    try {
      final events = await _dao.getAllEvents();
      return Future.wait(
        events.map((e) async {
          final category = await _getCategoryForEvent(e);
          return EventModel.fromDatabaseEntity(e, category);
        }),
      );
    } catch (e) {
      throw CacheException('Failed to get all events: ${e.toString()}');
    }
  }

  @override
  Future<List<EventModel>> getEventsByDate(DateTime date) async {
    try {
      final events = await _dao.getEventsByDate(date);
      return Future.wait(
        events.map((e) async {
          final category = await _getCategoryForEvent(e);
          return EventModel.fromDatabaseEntity(e, category);
        }),
      );
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
      final events = await _dao.getEventsByDateRange(startDate, endDate);
      return Future.wait(
        events.map((e) async {
          final category = await _getCategoryForEvent(e);
          return EventModel.fromDatabaseEntity(e, category);
        }),
      );
    } catch (e) {
      throw CacheException(
        'Failed to get events by date range: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<EventModel>> getEventsByCategory(String category) async {
    try {
      final events = await _dao.getEventsByCategory(category);
      return Future.wait(
        events.map((e) async {
          final cat = await _getCategoryForEvent(e);
          return EventModel.fromDatabaseEntity(e, cat);
        }),
      );
    } catch (e) {
      throw CacheException('Failed to get events by category: ${e.toString()}');
    }
  }

  @override
  Future<List<EventModel>> getEventsByStatus(EventStatus status) async {
    try {
      final events = await _dao.getAllEvents();
      final filtered = events.where((e) {
        final isCompleted = e.isCompleted;
        return status == EventStatus.completed ? isCompleted : !isCompleted;
      }).toList();

      return Future.wait(
        filtered.map((e) async {
          final category = await _getCategoryForEvent(e);
          return EventModel.fromDatabaseEntity(e, category);
        }),
      );
    } catch (e) {
      throw CacheException('Failed to get events by status: ${e.toString()}');
    }
  }

  @override
  Future<List<EventModel>> searchEvents(String query) async {
    try {
      final events = await _dao.getAllEvents();
      final filtered = events.where((e) {
        final titleMatch = e.title.toLowerCase().contains(query.toLowerCase());
        final descMatch =
            e.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
        return titleMatch || descMatch;
      }).toList();

      return Future.wait(
        filtered.map((e) async {
          final category = await _getCategoryForEvent(e);
          return EventModel.fromDatabaseEntity(e, category);
        }),
      );
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
      await _dao.toggleComplete(eventId, isCompleted);
      final updated = await _dao.getEventById(eventId);

      if (updated == null) {
        throw CacheException('Event not found');
      }

      final category = await _getCategoryForEvent(updated);
      return EventModel.fromDatabaseEntity(updated, category);
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
      return _dao.watchAllEvents().asyncMap((events) async {
        return Future.wait(
          events.map((e) async {
            final category = await _getCategoryForEvent(e);
            return EventModel.fromDatabaseEntity(e, category);
          }),
        );
      });
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
      return _dao.watchAllEvents().asyncMap((events) async {
        final filtered = events.where((e) {
          return !e.eventDate.isBefore(startDate) &&
              !e.eventDate.isAfter(endDate);
        }).toList();

        return Future.wait(
          filtered.map((e) async {
            final category = await _getCategoryForEvent(e);
            return EventModel.fromDatabaseEntity(e, category);
          }),
        );
      });
    } catch (e) {
      throw CacheException('Failed to watch events by range: ${e.toString()}');
    }
  }

  @override
  Stream<EventModel?> watchEventById(int eventId) {
    try {
      return _dao.watchEventById(eventId).asyncMap((event) async {
        if (event == null) return null;
        final category = await _getCategoryForEvent(event);
        return EventModel.fromDatabaseEntity(event, category);
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
      final categories = await _dao.getAllCategories();
      return categories
          .map((c) => EventCategoryModel.fromDatabaseEntity(c))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get categories: ${e.toString()}');
    }
  }

  @override
  Future<EventCategoryModel> createCategory(EventCategoryModel category) async {
    try {
      final companion = category.toDatabaseCompanion();
      final id = await _dao.createCategory(companion);
      final created = await _dao.getCategoryById(id);

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
      final success = await _dao.updateCategory(companion);

      if (!success) {
        throw CacheException('Failed to update category');
      }

      final updated = await _dao.getCategoryById(category.id!);
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
      final deleted = await _dao.deleteCategory(categoryId);
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
      final category = await _dao.getCategoryById(categoryId);
      if (category == null) return null;
      return EventCategoryModel.fromDatabaseEntity(category);
    } catch (e) {
      throw CacheException('Failed to get category: ${e.toString()}');
    }
  }

  @override
  Future<void> initializeDefaultCategories() async {
    try {
      await _dao.initializeDefaultCategories();
    } catch (e) {
      throw CacheException('Failed to initialize categories: ${e.toString()}');
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Future<EventCategory> _getCategoryForEvent(db.UserEvent event) async {
    if (event.categoryId != null) {
      final category = await _dao.getCategoryById(event.categoryId!);
      if (category != null) {
        return EventCategoryModel.fromDatabaseEntity(category);
      }
    }

    // Fallback to default category
    final dbCategories = await _dao.getAllCategories();
    final matching = dbCategories
        .where((c) => c.name == event.category)
        .toList();
    if (matching.isNotEmpty) {
      return EventCategoryModel.fromDatabaseEntity(matching.first);
    }
    return EventCategory.personal;
  }
}
