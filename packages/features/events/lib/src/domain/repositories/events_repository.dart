import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';
import '../entities/event_category.dart';

/// Abstract repository for events operations
abstract class EventsRepository {
  // ============================================================================
  // EVENT OPERATIONS
  // ============================================================================

  /// Create a new event
  Future<Either<Failure, Event>> createEvent(Event event);

  /// Update an existing event
  Future<Either<Failure, Event>> updateEvent(Event event);

  /// Delete an event
  Future<Either<Failure, void>> deleteEvent(int eventId);

  /// Get event by ID
  Future<Either<Failure, Event>> getEventById(int eventId);

  /// Get all events
  Future<Either<Failure, List<Event>>> getAllEvents();

  /// Get events by date
  Future<Either<Failure, List<Event>>> getEventsByDate(DateTime date);

  /// Get events by date range
  Future<Either<Failure, List<Event>>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get events by category
  Future<Either<Failure, List<Event>>> getEventsByCategory(String category);

  /// Get events by status
  Future<Either<Failure, List<Event>>> getEventsByStatus(EventStatus status);

  /// Get upcoming events (within next N days)
  Future<Either<Failure, List<Event>>> getUpcomingEvents({int days = 7});

  /// Get overdue events
  Future<Either<Failure, List<Event>>> getOverdueEvents();

  /// Toggle event completion
  Future<Either<Failure, Event>> toggleEventCompletion(
    int eventId,
    bool isCompleted,
  );

  /// Search events by text
  Future<Either<Failure, List<Event>>> searchEvents(String query);

  // ============================================================================
  // STREAM OPERATIONS
  // ============================================================================

  /// Watch all events
  Stream<Either<Failure, List<Event>>> watchAllEvents();

  /// Watch events by date
  Stream<Either<Failure, List<Event>>> watchEventsByDate(DateTime date);

  /// Watch events by date range
  Stream<Either<Failure, List<Event>>> watchEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Watch event by ID
  Stream<Either<Failure, Event?>> watchEventById(int eventId);

  // ============================================================================
  // CATEGORY OPERATIONS
  // ============================================================================

  /// Get all categories
  Future<Either<Failure, List<EventCategory>>> getAllCategories();

  /// Create category
  Future<Either<Failure, EventCategory>> createCategory(EventCategory category);

  /// Update category
  Future<Either<Failure, EventCategory>> updateCategory(EventCategory category);

  /// Delete category
  Future<Either<Failure, void>> deleteCategory(int categoryId);

  /// Get category by ID
  Future<Either<Failure, EventCategory>> getCategoryById(int categoryId);

  /// Initialize default categories
  Future<Either<Failure, void>> initializeDefaultCategories();
}
