import 'package:core/core.dart';
import 'package:data/data.dart' as db;
import 'package:flutter/foundation.dart';

import '../models/recurring_exception_model.dart';

abstract class RecurringExceptionsDataSource {
  Future<List<RecurringExceptionModel>> getExceptionsInRange(
    DateTime startDate,
    DateTime endDate,
  );

  Future<List<RecurringExceptionModel>> getExceptionsForEvent(
    int masterEventId,
  );

  Future<RecurringExceptionModel?> getExceptionForDate(
    int masterEventId,
    DateTime occurrenceDate,
  );

  Future<RecurringExceptionModel> createException(
    RecurringExceptionModel exception,
  );

  Future<void> markInstanceCompleted(
    int masterEventId,
    DateTime occurrenceDate,
  );

  Future<void> markInstanceDeleted(int masterEventId, DateTime occurrenceDate);

  Future<void> deleteException(int exceptionId);

  Future<void> deleteExceptionsForEvent(int masterEventId);

  Stream<List<RecurringExceptionModel>> watchExceptionsForEvent(
    int masterEventId,
  );
}

class RecurringExceptionsDataSourceImpl
    implements RecurringExceptionsDataSource {
  final db.AppDatabase database;
  late final db.RecurringExceptionsDao _dao;

  RecurringExceptionsDataSourceImpl(this.database) {
    _dao = database.recurringExceptionsDao;
  }

  @override
  Future<List<RecurringExceptionModel>> getExceptionsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final exceptions = await _dao.getExceptionsInRange(startDate, endDate);
      return exceptions
          .map((e) => RecurringExceptionModel.fromDatabaseEntity(e))
          .toList();
    } catch (e) {
      throw CacheException(
        'Failed to get exceptions in range: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<RecurringExceptionModel>> getExceptionsForEvent(
    int masterEventId,
  ) async {
    try {
      final exceptions = await _dao.getExceptionsForEvent(masterEventId);
      return exceptions
          .map((e) => RecurringExceptionModel.fromDatabaseEntity(e))
          .toList();
    } catch (e) {
      throw CacheException(
        'Failed to get exceptions for event: ${e.toString()}',
      );
    }
  }

  @override
  Future<RecurringExceptionModel?> getExceptionForDate(
    int masterEventId,
    DateTime occurrenceDate,
  ) async {
    try {
      final exception = await _dao.getExceptionForDate(
        masterEventId,
        occurrenceDate,
      );
      return exception != null
          ? RecurringExceptionModel.fromDatabaseEntity(exception)
          : null;
    } catch (e) {
      throw CacheException('Failed to get exception for date: ${e.toString()}');
    }
  }

  @override
  Future<RecurringExceptionModel> createException(
    RecurringExceptionModel exception,
  ) async {
    try {
      final companion = exception.toDatabaseCompanion();
      final id = await _dao.createException(companion);
      debugPrint(
        "[RecurringExceptionsDataSource]: recurring exception created with id = $id",
      );

      // Fetch the created exception
      final created = await _dao.getExceptionForDate(
        exception.masterEventId,
        exception.occurrenceDate,
      );

      if (created == null) {
        throw CacheException('Failed to create exception');
      }

      return RecurringExceptionModel.fromDatabaseEntity(created);
    } catch (e) {
      throw CacheException('Failed to create exception: ${e.toString()}');
    }
  }

  @override
  Future<void> markInstanceCompleted(
    int masterEventId,
    DateTime occurrenceDate,
  ) async {
    try {
      await _dao.markInstanceCompleted(masterEventId, occurrenceDate);
    } catch (e) {
      throw CacheException(
        'Failed to mark instance completed: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> markInstanceDeleted(
    int masterEventId,
    DateTime occurrenceDate,
  ) async {
    try {
      await _dao.markInstanceDeleted(masterEventId, occurrenceDate);
    } catch (e) {
      throw CacheException('Failed to mark instance deleted: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteException(int exceptionId) async {
    try {
      await _dao.deleteException(exceptionId);
    } catch (e) {
      throw CacheException('Failed to delete exception: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteExceptionsForEvent(int masterEventId) async {
    try {
      await _dao.deleteExceptionsForEvent(masterEventId);
    } catch (e) {
      throw CacheException(
        'Failed to delete exceptions for event: ${e.toString()}',
      );
    }
  }

  @override
  Stream<List<RecurringExceptionModel>> watchExceptionsForEvent(
    int masterEventId,
  ) {
    try {
      return _dao
          .watchExceptionsForEvent(masterEventId)
          .map(
            (exceptions) => exceptions
                .map((e) => RecurringExceptionModel.fromDatabaseEntity(e))
                .toList(),
          );
    } catch (e) {
      throw CacheException('Failed to watch exceptions: ${e.toString()}');
    }
  }
}
