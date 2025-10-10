import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';

abstract class EventsRepository {
  Future<Either<Failure, List<Event>>> getAllEvents();
  Future<Either<Failure, List<Event>>> getEventsByDate(DateTime date);
  Future<Either<Failure, List<Event>>> getEventsByDateRange(
    DateTime start,
    DateTime end,
  );
  Future<Either<Failure, Event>> getEventById(int id);
  Future<Either<Failure, List<Event>>> getEventsByCategory(String category);
  Future<Either<Failure, Event>> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    DateTime? eventTime,
    bool isAllDay = true,
    required String category,
    int? categoryId,
    int? colorCode,
    RecurrenceRule? recurrence,
    bool hasNotification = false,
    List<int>? notificationMinutes,
    String? location,
    int priority = 0,
    List<String>? tags,
  });
  Future<Either<Failure, Event>> updateEvent({
    required int id,
    String? title,
    String? description,
    DateTime? eventDate,
    DateTime? eventTime,
    bool? isAllDay,
    String? category,
    int? categoryId,
    int? colorCode,
    String? location,
    int? priority,
  });
  Future<Either<Failure, void>> deleteEvent(int id);
  Future<Either<Failure, Event>> toggleComplete(int id);
  Future<Either<Failure, List<EventCategory>>> getAllCategories();
  Future<Either<Failure, EventCategory>> createCategory({
    required String name,
    required String iconName,
    required int colorCode,
    int sortOrder = 0,
  });
  Future<Either<Failure, void>> deleteCategory(int id);
  Stream<Either<Failure, List<Event>>> watchAllEvents();
  Stream<Either<Failure, Event>> watchEventById(int id);
  Future<Either<Failure, void>> initializeDefaultCategories();
}
