import 'package:core/core.dart';
import 'package:data/data.dart' as db;
import 'package:drift/drift.dart';

import '../models/event_model.dart';

abstract class EventsLocalDataSource {
  Future<List<EventModel>> getAllEvents();
  Future<List<EventModel>> getEventsByDate(DateTime date);
  Future<List<EventModel>> getEventsByDateRange(DateTime start, DateTime end);
  Future<EventModel> getEventById(int id);
  Future<List<EventModel>> getEventsByCategory(String category);
  Future<EventModel> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    DateTime? eventTime,
    bool isAllDay = true,
    required String category,
    int? categoryId,
    int? colorCode,
  });
  Future<EventModel> updateEvent({
    required int id,
    String? title,
    String? description,
    DateTime? eventDate,
    String? location,
  });
  Future<void> deleteEvent(int id);
  Future<EventModel> toggleComplete(int id);
  Future<List<CategoryModel>> getAllCategories();
  Future<CategoryModel> createCategory({
    required String name,
    required String iconName,
    required int colorCode,
  });
  Future<void> deleteCategory(int id);
  Stream<List<EventModel>> watchAllEvents();
  Stream<EventModel> watchEventById(int id);
  Future<void> initializeDefaultCategories();
}

class EventsLocalDataSourceImpl implements EventsLocalDataSource {
  final db.EventsDao eventsDao;

  EventsLocalDataSourceImpl(this.eventsDao);

  @override
  Future<List<EventModel>> getAllEvents() async {
    final events = await eventsDao.getAllEvents();
    return events.map((e) => EventModel.fromDrift(e)).toList();
  }

  @override
  Future<List<EventModel>> getEventsByDate(DateTime date) async {
    final events = await eventsDao.getEventsByDate(date);
    return events.map((e) => EventModel.fromDrift(e)).toList();
  }

  @override
  Future<List<EventModel>> getEventsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final events = await eventsDao.getEventsByDateRange(start, end);
    return events.map((e) => EventModel.fromDrift(e)).toList();
  }

  @override
  Future<EventModel> getEventById(int id) async {
    final event = await eventsDao.getEventById(id);
    if (event == null) throw const NotFoundException('Event not found');
    return EventModel.fromDrift(event);
  }

  @override
  Future<List<EventModel>> getEventsByCategory(String category) async {
    final events = await eventsDao.getEventsByCategory(category);
    return events.map((e) => EventModel.fromDrift(e)).toList();
  }

  @override
  Future<EventModel> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    DateTime? eventTime,
    bool isAllDay = true,
    required String category,
    int? categoryId,
    int? colorCode,
  }) async {
    final companion = db.UserEventsCompanion.insert(
      title: title,
      description: Value(description),
      eventDate: eventDate,
      eventTime: Value(eventTime),
      isAllDay: Value(isAllDay),
      category: category,
      categoryId: Value(categoryId),
      colorCode: Value(colorCode),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

    final id = await eventsDao.createEvent(companion);
    final event = await eventsDao.getEventById(id);
    if (event == null) throw const CacheException('Failed to create event');
    return EventModel.fromDrift(event);
  }

  @override
  Future<EventModel> updateEvent({
    required int id,
    String? title,
    String? description,
    DateTime? eventDate,
    String? location,
  }) async {
    final companion = db.UserEventsCompanion(
      id: Value(id),
      title: title != null ? Value(title) : const Value.absent(),
      description: description != null
          ? Value(description)
          : const Value.absent(),
      eventDate: eventDate != null ? Value(eventDate) : const Value.absent(),
      location: location != null ? Value(location) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    final success = await eventsDao.updateEvent(companion);
    if (!success) throw const CacheException('Failed to update event');

    final event = await eventsDao.getEventById(id);
    if (event == null) {
      throw const NotFoundException('Event not found after update');
    }
    return EventModel.fromDrift(event);
  }

  @override
  Future<void> deleteEvent(int id) async {
    await eventsDao.deleteEvent(id);
  }

  @override
  Future<EventModel> toggleComplete(int id) async {
    final event = await eventsDao.getEventById(id);
    if (event == null) throw const NotFoundException('Event not found');

    await eventsDao.toggleComplete(id, !event.isCompleted);

    final updatedEvent = await eventsDao.getEventById(id);
    if (updatedEvent == null) {
      throw const CacheException('Failed to toggle complete');
    }
    return EventModel.fromDrift(updatedEvent);
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    final categories = await eventsDao.getAllCategories();
    return categories.map((c) => CategoryModel.fromDrift(c)).toList();
  }

  @override
  Future<CategoryModel> createCategory({
    required String name,
    required String iconName,
    required int colorCode,
  }) async {
    final companion = db.EventCategoriesCompanion.insert(
      name: name,
      iconName: iconName,
      colorCode: colorCode,
      sortOrder: 0,
      createdAt: DateTime.now(),
    );

    final id = await eventsDao.createCategory(companion);
    final category = await eventsDao.getCategoryById(id);
    if (category == null) {
      throw CacheException("Failed to create event category");
    }
    return CategoryModel.fromDrift(category);
  }

  @override
  Future<void> deleteCategory(int id) async {
    await eventsDao.deleteCategory(id);
  }

  @override
  Stream<List<EventModel>> watchAllEvents() {
    return eventsDao.watchAllEvents().map(
      (events) => events.map((e) => EventModel.fromDrift(e)).toList(),
    );
  }

  @override
  Stream<EventModel> watchEventById(int id) {
    return eventsDao.watchEventById(id).map((event) {
      if (event == null) throw const NotFoundException('Event not found');
      return EventModel.fromDrift(event);
    });
  }

  @override
  Future<void> initializeDefaultCategories() async {
    return eventsDao.initializeDefaultCategories();
  }
}
