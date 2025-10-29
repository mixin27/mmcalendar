import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:data/data.dart' as data;

import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/repositories/events_repository.dart';
import '../datasources/events_local_datasource.dart';
import '../models/event_category_model.dart';
import '../models/event_model.dart';

/// Implementation of EventsRepository
class EventsRepositoryImpl extends data.BaseRepository
    implements EventsRepository {
  final EventsLocalDataSource localDataSource;

  EventsRepositoryImpl(this.localDataSource);

  // ============================================================================
  // EVENT OPERATIONS
  // ============================================================================

  @override
  Future<Either<Failure, Event>> createEvent(Event event) async {
    try {
      final eventModel = EventModel.fromEntity(event);
      final result = await localDataSource.createEvent(eventModel);
      return Right(result.toEntity());
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
      final events = results.map((e) => e.toEntity()).toList();
      return Right(events);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByDate(DateTime date) async {
    try {
      final results = await localDataSource.getEventsByDate(date);
      final events = results.map((e) => e.toEntity()).toList();
      return Right(events);
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
      final results = await localDataSource.getEventsByDateRange(
        startDate,
        endDate,
      );
      final events = results.map((e) => e.toEntity()).toList();
      return Right(events);
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
      final results = await localDataSource.getEventsByDateRange(now, endDate);
      final events = results
          .map((e) => e.toEntity())
          .where((e) => e.status == EventStatus.pending)
          .toList();
      events.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
      return Right(events);
    } on AppException catch (e) {
      return Left(handleException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getOverdueEvents() async {
    try {
      // final now = DateTime.now();
      final results = await localDataSource.getAllEvents();
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
          .map((events) {
            final entities = events.map((e) => e.toEntity()).toList();
            return Right<Failure, List<Event>>(entities);
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
    try {
      return localDataSource
          .watchEventsByDate(date)
          .map((events) {
            final entities = events.map((e) => e.toEntity()).toList();
            return Right<Failure, List<Event>>(entities);
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
  Stream<Either<Failure, List<Event>>> watchEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      return localDataSource
          .watchEventsByDateRange(startDate, endDate)
          .map((events) {
            final entities = events.map((e) => e.toEntity()).toList();
            return Right<Failure, List<Event>>(entities);
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
}
