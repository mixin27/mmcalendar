import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../../domain/entities/event.dart';
import '../../domain/repositories/events_repository.dart';
import '../datasources/events_local_datasource.dart';

class EventsRepositoryImpl implements EventsRepository {
  final EventsLocalDataSource localDataSource;

  EventsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Event>>> getAllEvents() async {
    try {
      final events = await localDataSource.getAllEvents();
      return Right(events.map((e) => e.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get all events: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByDate(DateTime date) async {
    try {
      final events = await localDataSource.getEventsByDate(date);
      return Right(events.map((e) => e.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Failed to get events by date: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final events = await localDataSource.getEventsByDateRange(start, end);
      return Right(events.map((e) => e.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Failed to get events by range: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Event>> getEventById(int id) async {
    try {
      final event = await localDataSource.getEventById(id);
      return Right(event.toEntity());
    } on NotFoundException catch (e) {
      return Left(DataFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get event by id: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByCategory(
    String category,
  ) async {
    try {
      final events = await localDataSource.getEventsByCategory(category);
      return Right(events.map((e) => e.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Failed to get events by category: ${e.toString()}'),
      );
    }
  }

  @override
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
  }) async {
    try {
      // Validate input
      if (title.trim().isEmpty) {
        return const Left(ValidationFailure('Event title cannot be empty'));
      }

      final event = await localDataSource.createEvent(
        title: title,
        description: description,
        eventDate: eventDate,
        eventTime: eventTime,
        isAllDay: isAllDay,
        category: category,
        categoryId: categoryId,
        colorCode: colorCode,
      );

      final entity = event.toEntity();

      // Fire event bus event
      AppEventBus.fire(EventCreatedEvent(entity.id, entity.title));

      return Right(entity);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to create event: ${e.toString()}'));
    }
  }

  @override
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
  }) async {
    try {
      // Validate input
      if (title != null && title.trim().isEmpty) {
        return const Left(ValidationFailure('Event title cannot be empty'));
      }

      final event = await localDataSource.updateEvent(
        id: id,
        title: title,
        description: description,
        eventDate: eventDate,
        location: location,
      );

      final entity = event.toEntity();

      // Fire event bus event
      AppEventBus.fire(EventUpdatedEvent(entity.id, entity.title));

      return Right(entity);
    } on NotFoundException catch (e) {
      return Left(DataFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to update event: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvent(int id) async {
    try {
      await localDataSource.deleteEvent(id);

      // Fire event bus event
      AppEventBus.fire(EventDeletedEvent(id));

      return const Right(null);
    } on NotFoundException catch (e) {
      return Left(DataFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to delete event: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Event>> toggleComplete(int id) async {
    try {
      final event = await localDataSource.toggleComplete(id);
      final entity = event.toEntity();

      // Fire event bus event
      AppEventBus.fire(EventUpdatedEvent(entity.id, entity.title));

      return Right(entity);
    } on NotFoundException catch (e) {
      return Left(DataFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to toggle complete: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<EventCategory>>> getAllCategories() async {
    try {
      final categories = await localDataSource.getAllCategories();
      return Right(categories.map((c) => c.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get categories: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, EventCategory>> createCategory({
    required String name,
    required String iconName,
    required int colorCode,
    int sortOrder = 0,
  }) async {
    try {
      if (name.trim().isEmpty) {
        return const Left(ValidationFailure('Category name cannot be empty'));
      }

      final category = await localDataSource.createCategory(
        name: name,
        iconName: iconName,
        colorCode: colorCode,
      );

      return Right(category.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to create category: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(int id) async {
    try {
      await localDataSource.deleteCategory(id);
      return const Right(null);
    } on NotFoundException catch (e) {
      return Left(DataFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to delete category: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, List<Event>>> watchAllEvents() {
    try {
      return localDataSource.watchAllEvents().map(
        (events) => Right(events.map((e) => e.toEntity()).toList()),
      );
      // .handleError((error) {
      //   if (error is CacheException) {
      //     return Left(CacheFailure(error.message));
      //   }
      //   return Left(UnknownFailure('Stream error: ${error.toString()}'));
      // });
    } catch (e) {
      return Stream.value(
        Left(UnknownFailure('Failed to watch events: ${e.toString()}')),
      );
    }
  }

  @override
  Stream<Either<Failure, Event>> watchEventById(int id) {
    try {
      return localDataSource
          .watchEventById(id)
          .map((event) => Right(event.toEntity()));
      // .handleError((error) {
      //   if (error is NotFoundException) {
      //     return Left(DataFailure(error.message));
      //   }
      //   if (error is CacheException) {
      //     return Left(CacheFailure(error.message));
      //   }
      //   return Left(UnknownFailure('Stream error: ${error.toString()}'));
      // });
    } catch (e) {
      return Stream.value(
        Left(UnknownFailure('Failed to watch event: ${e.toString()}')),
      );
    }
  }

  @override
  Future<Either<Failure, void>> initializeDefaultCategories() async {
    try {
      await localDataSource.initializeDefaultCategories();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure(
          'Failed to initialize default categories: ${e.toString()}',
        ),
      );
    }
  }
}
