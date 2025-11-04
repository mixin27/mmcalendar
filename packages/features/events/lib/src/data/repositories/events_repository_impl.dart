import 'package:collection/collection.dart';
import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:data/data.dart' as data;

import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/repositories/events_repository.dart';
import '../../utils/event_creation_diagnostic.dart';
import '../datasources/events_local_datasource.dart';
import '../datasources/recurring_exceptions_datasource.dart';
import '../models/event_category_model.dart';
import '../models/event_model.dart';
import '../models/recurring_exception_model.dart';

/// Implementation of EventsRepository
class EventsRepositoryImpl extends data.BaseRepository
    implements EventsRepository {
  final EventsLocalDataSource localDataSource;
  final RecurringExceptionsDataSource exceptionsDataSource;

  EventsRepositoryImpl(this.localDataSource, this.exceptionsDataSource);

  // ============================================================================
  // EVENT OPERATIONS
  // ============================================================================

  @override
  Future<Either<Failure, Event>> createEvent(Event event) async {
    try {
      EventCreationDiagnostic.logRepositoryCreateStart(event.title);

      final eventModel = EventModel.fromEntity(event);
      final createdModel = await localDataSource.createEvent(eventModel);
      return Right(createdModel.toEntity());
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Event>> updateEvent(Event event) async {
    try {
      final eventModel = EventModel.fromEntity(event);
      final result = await localDataSource.updateEvent(eventModel);
      return Right(result.toEntity());
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvent(int eventId) async {
    try {
      await localDataSource.deleteEvent(eventId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Event>> getEventById(int eventId) async {
    try {
      final result = await localDataSource.getEventById(eventId);
      if (result == null) {
        return Left(DataFailure('Event not found'));
      }
      return Right(result.toEntity());
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getAllEvents({
    bool includeCompleted = false,
  }) async {
    try {
      final results = await localDataSource.getAllEvents(
        includeCompleted: includeCompleted,
      );

      // For "all events", show next 365 days of recurring events
      final now = DateTime.now();
      final oneYearLater = now.add(const Duration(days: 365));

      // Get exceptions for the next year
      final exceptionModels = await exceptionsDataSource.getExceptionsInRange(
        now,
        oneYearLater,
      );
      final exceptions = exceptionModels.map((e) => e.toEntity()).toList();

      final expandedEvents = <Event>[];

      for (final eventModel in results) {
        final event = eventModel.toEntity();

        if (event.isRecurring && event.recurrenceRule != null) {
          // Generate virtual instances
          final instances = _generateVirtualInstances(
            event,
            now,
            oneYearLater,
            exceptions,
          );

          // Add virtual instances as events
          expandedEvents.addAll(instances.map((i) => i.toEvent()));
        } else {
          // Add one-time event as-is
          expandedEvents.add(event);
        }
      }

      // Sort by date
      expandedEvents.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

      return Right(expandedEvents);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByDate(DateTime date) async {
    try {
      // Use date range (start of day to end of day)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return getEventsByDateRange(startOfDay, endOfDay);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get ALL base events from database (both one-time and recurring masters)
      final masterEvents = await localDataSource.getAllEvents(
        includeCompleted: false,
      );

      // Get all exceptions in this date range
      final exceptionModels = await exceptionsDataSource.getExceptionsInRange(
        startDate,
        endDate,
      );

      // Convert to domain entities
      final exceptions = exceptionModels.map((e) => e.toEntity()).toList();

      // Process events (generate virtual instances for recurring events)
      final resultEvents = <Event>[];

      for (final eventModel in masterEvents) {
        final event = eventModel.toEntity();

        if (event.isRecurring && event.recurrenceRule != null) {
          // Generate virtual instances for this recurring event
          final instances = _generateVirtualInstances(
            event,
            startDate,
            endDate,
            exceptions,
          );

          // Convert instances to events and add to results
          resultEvents.addAll(instances.map((i) => i.toEvent()));
        } else {
          // Regular one-time event - just check if it's in range
          if (_isDateInRange(event.eventDate, startDate, endDate)) {
            resultEvents.add(event);
          }
        }
      }

      // Sort by date
      resultEvents.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

      return Right(resultEvents);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByCategory(
    String category,
  ) async {
    try {
      final results = await localDataSource.getEventsByCategory(category);
      final events = results.map((e) => e.toEntity()).toList();
      return Right(events);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByStatus(
    EventStatus status,
  ) async {
    try {
      final results = await localDataSource.getEventsByStatus(status);
      final events = results.map((e) => e.toEntity()).toList();
      return Right(events);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getUpcomingEvents({int days = 7}) async {
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: days));

      // Use date range method to get virtual instances
      return getEventsByDateRange(now, endDate);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getOverdueEvents() async {
    try {
      // Get all master events
      final results = await localDataSource.getAllEvents();

      // Filter overdue (both one-time and recurring need special handling)
      final events = results
          .map((e) => e.toEntity())
          .where((e) => e.isOverdue)
          .toList();

      return Right(events);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Event>> toggleEventCompletion(
    int eventId,
    bool isCompleted,
  ) async {
    try {
      final result = await localDataSource.toggleEventCompletion(
        eventId,
        isCompleted,
      );
      return Right(result.toEntity());
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> searchEvents(String query) async {
    try {
      final results = await localDataSource.searchEvents(query);
      final events = results.map((e) => e.toEntity()).toList();
      return Right(events);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ============================================================================
  // STREAM OPERATIONS
  // ============================================================================

  @override
  Stream<Either<Failure, List<Event>>> watchAllEvents() {
    try {
      return localDataSource
          .watchAllEvents()
          .asyncMap((events) async {
            // Expand recurring events
            final now = DateTime.now();
            final oneYearLater = now.add(const Duration(days: 365));

            final exceptionModels = await exceptionsDataSource
                .getExceptionsInRange(now, oneYearLater);
            final exceptions = exceptionModels
                .map((e) => e.toEntity())
                .toList();

            final allEvents = <Event>[];
            for (final eventModel in events) {
              final masterEvent = eventModel.toEntity();

              if (masterEvent.isRecurring &&
                  masterEvent.recurrenceRule != null) {
                final instances = _generateVirtualInstances(
                  masterEvent,
                  now,
                  oneYearLater,
                  exceptions,
                );
                allEvents.addAll(instances.map((i) => i.toEvent()));
              } else {
                allEvents.add(masterEvent);
              }
            }

            allEvents.sort(
              (a, b) => a.eventDateTime.compareTo(b.eventDateTime),
            );
            return Right<Failure, List<Event>>(allEvents);
          })
          .handleError((error) {
            return Left<Failure, List<Event>>(
              error is AppException
                  ? handleException(error)
                  : UnknownFailure(error.toString()),
            );
          });
    } catch (e) {
      return Stream.value(Left(UnknownFailure(e.toString())));
    }
  }

  @override
  Stream<Either<Failure, List<Event>>> watchEventsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return watchEventsByDateRange(startOfDay, endOfDay);
  }

  @override
  Stream<Either<Failure, List<Event>>> watchEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      return localDataSource
          .watchAllEvents()
          .asyncMap((events) async {
            final exceptionModels = await exceptionsDataSource
                .getExceptionsInRange(startDate, endDate);
            final exceptions = exceptionModels
                .map((e) => e.toEntity())
                .toList();

            final resultEvents = <Event>[];
            for (final eventModel in events) {
              final masterEvent = eventModel.toEntity();

              if (masterEvent.isRecurring &&
                  masterEvent.recurrenceRule != null) {
                final instances = _generateVirtualInstances(
                  masterEvent,
                  startDate,
                  endDate,
                  exceptions,
                );
                resultEvents.addAll(instances.map((i) => i.toEvent()));
              } else {
                if (_isDateInRange(masterEvent.eventDate, startDate, endDate)) {
                  resultEvents.add(masterEvent);
                }
              }
            }

            resultEvents.sort(
              (a, b) => a.eventDateTime.compareTo(b.eventDateTime),
            );
            return Right<Failure, List<Event>>(resultEvents);
          })
          .handleError((error) {
            return Left<Failure, List<Event>>(
              error is AppException
                  ? handleException(error)
                  : UnknownFailure(error.toString()),
            );
          });
    } catch (e) {
      return Stream.value(Left(UnknownFailure(e.toString())));
    }
  }

  @override
  Stream<Either<Failure, Event?>> watchEventById(int eventId) {
    try {
      return localDataSource
          .watchEventById(eventId)
          .map((event) {
            return Right<Failure, Event?>(event?.toEntity());
          })
          .handleError((error) {
            return Left<Failure, Event?>(
              error is AppException
                  ? handleException(error)
                  : UnknownFailure(error.toString()),
            );
          });
    } catch (e) {
      return Stream.value(Left(UnknownFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> completeRecurringInstance(
    int masterEventId,
    DateTime occurrenceDate,
  ) async {
    try {
      await exceptionsDataSource.markInstanceCompleted(
        masterEventId,
        occurrenceDate,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecurringInstance(
    int masterEventId,
    DateTime occurrenceDate,
  ) async {
    try {
      await exceptionsDataSource.markInstanceDeleted(
        masterEventId,
        occurrenceDate,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> modifyRecurringInstance({
    required int masterEventId,
    required DateTime occurrenceDate,
    String? modifiedTitle,
    String? modifiedDescription,
    DateTime? modifiedDate,
    DateTime? modifiedTime,
    String? modifiedLocation,
  }) async {
    try {
      // Check if exception already exists
      final existing = await exceptionsDataSource.getExceptionForDate(
        masterEventId,
        occurrenceDate,
      );

      if (existing != null) {
        // Update existing exception
        final updated = RecurringExceptionModel(
          id: existing.id,
          masterEventId: masterEventId,
          occurrenceDate: occurrenceDate,
          exceptionType: ExceptionType.modified,
          modifiedTitle: modifiedTitle,
          modifiedDescription: modifiedDescription,
          modifiedDate: modifiedDate,
          modifiedTime: modifiedTime,
          modifiedLocation: modifiedLocation,
          isCompleted: existing.isCompleted,
          completedAt: existing.completedAt,
          createdAt: existing.createdAt,
        );
        await exceptionsDataSource.createException(updated);
      } else {
        // Create new exception
        final newException = RecurringExceptionModel(
          id: 0, // Will be auto-generated
          masterEventId: masterEventId,
          occurrenceDate: occurrenceDate,
          exceptionType: ExceptionType.modified,
          modifiedTitle: modifiedTitle,
          modifiedDescription: modifiedDescription,
          modifiedDate: modifiedDate,
          modifiedTime: modifiedTime,
          modifiedLocation: modifiedLocation,
          createdAt: DateTime.now(),
        );
        await exceptionsDataSource.createException(newException);
      }

      return const Right(null);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecurringEventException>>> getExceptionsForEvent(
    int masterEventId,
  ) async {
    try {
      final results = await exceptionsDataSource.getExceptionsForEvent(
        masterEventId,
      );
      final entities = results.map((e) => e.toEntity()).toList();
      return Right(entities);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> restoreRecurringInstance(
    int masterEventId,
    DateTime occurrenceDate,
  ) async {
    try {
      final exception = await exceptionsDataSource.getExceptionForDate(
        masterEventId,
        occurrenceDate,
      );

      if (exception != null) {
        await exceptionsDataSource.deleteException(exception.id);
      }

      return const Right(null);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ============================================================================
  // CATEGORY OPERATIONS
  // ============================================================================

  @override
  Future<Either<Failure, List<EventCategory>>> getAllCategories() async {
    try {
      final results = await localDataSource.getAllCategories();
      final categories = results.map((c) => c.toEntity()).toList();
      return Right(categories);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EventCategory>> createCategory(
    EventCategory category,
  ) async {
    try {
      final categoryModel = EventCategoryModel.fromEntity(category);
      final result = await localDataSource.createCategory(categoryModel);
      return Right(result.toEntity());
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EventCategory>> updateCategory(
    EventCategory category,
  ) async {
    try {
      final categoryModel = EventCategoryModel.fromEntity(category);
      final result = await localDataSource.updateCategory(categoryModel);
      return Right(result.toEntity());
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(int categoryId) async {
    try {
      await localDataSource.deleteCategory(categoryId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EventCategory>> getCategoryById(int categoryId) async {
    try {
      final result = await localDataSource.getCategoryById(categoryId);
      if (result == null) {
        return Left(DataFailure('Category not found'));
      }
      return Right(result.toEntity());
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> initializeDefaultCategories() async {
    try {
      await localDataSource.initializeDefaultCategories();
      return const Right(null);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Generate virtual instances for a recurring event within a date range
  /// This method properly handles exceptions (deleted, modified, completed)
  List<EventInstance> _generateVirtualInstances(
    Event masterEvent,
    DateTime rangeStart,
    DateTime rangeEnd,
    List<RecurringEventException> allExceptions,
  ) {
    final instances = <EventInstance>[];

    // STEP 1: Get exceptions for this specific master event
    final eventExceptions = allExceptions
        .where((e) => e.masterEventId == masterEvent.id)
        .toList();

    // STEP 2: Generate occurrence dates using the recurrence rule
    final occurrenceDates = masterEvent.recurrenceRule!.generateOccurrences(
      masterEvent.eventDate,
      rangeStart,
      rangeEnd,
    );

    // STEP 3: For each occurrence, create a virtual instance
    for (final occurrenceDate in occurrenceDates) {
      // Check if this occurrence has an exception
      final exception = eventExceptions.firstWhereOrNull(
        (e) => _isSameDay(e.occurrenceDate, occurrenceDate),
      );

      // SKIP deleted instances completely
      if (exception?.exceptionType == ExceptionType.deleted) {
        continue;
      }

      // Calculate occurrence time (preserving time from master event)
      DateTime? occurrenceTime;
      if (masterEvent.eventTime != null && !masterEvent.isAllDay) {
        occurrenceTime = DateTime(
          occurrenceDate.year,
          occurrenceDate.month,
          occurrenceDate.day,
          masterEvent.eventTime!.hour,
          masterEvent.eventTime!.minute,
          masterEvent.eventTime!.second,
        );
      }

      // Create virtual instance with exception data (if any)
      instances.add(
        EventInstance(
          masterEvent: masterEvent,
          occurrenceDate: occurrenceDate,
          occurrenceTime: occurrenceTime,
          exception: exception,
        ),
      );
    }

    return instances;
  }

  // Check if date is in range
  bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(start.year, start.month, start.day);
    final endOnly = DateTime(end.year, end.month, end.day);

    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }

  // Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
