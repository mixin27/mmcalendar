import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_events_table.dart';

part 'recurring_exceptions_dao.g.dart';

@DriftAccessor(tables: [RecurringEventExceptions])
class RecurringExceptionsDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringExceptionsDaoMixin {
  RecurringExceptionsDao(super.db);

  // ========== CREATE ==========

  /// Create a new exception (modified, deleted, or completed instance)
  Future<int> createException(RecurringEventExceptionsCompanion exception) {
    return into(recurringEventExceptions).insert(exception);
  }

  // ========== READ ==========

  /// Get all exceptions for a master event
  Future<List<RecurringEventException>> getExceptionsForEvent(
    int masterEventId,
  ) {
    return (select(recurringEventExceptions)
          ..where((e) => e.masterEventId.equals(masterEventId))
          ..orderBy([(e) => OrderingTerm.asc(e.occurrenceDate)]))
        .get();
  }

  /// Get exceptions within a date range
  Future<List<RecurringEventException>> getExceptionsInRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(recurringEventExceptions)
          ..where(
            (e) =>
                e.occurrenceDate.isBiggerOrEqualValue(startDate) &
                e.occurrenceDate.isSmallerOrEqualValue(endDate),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.occurrenceDate)]))
        .get();
  }

  /// Get exception for specific occurrence date
  Future<RecurringEventException?> getExceptionForDate(
    int masterEventId,
    DateTime occurrenceDate,
  ) {
    return (select(recurringEventExceptions)..where(
          (e) =>
              e.masterEventId.equals(masterEventId) &
              e.occurrenceDate.equals(occurrenceDate),
        ))
        .getSingleOrNull();
  }

  /// Get all deleted instances for a master event
  Future<List<RecurringEventException>> getDeletedInstances(int masterEventId) {
    return (select(recurringEventExceptions)
          ..where(
            (e) =>
                e.masterEventId.equals(masterEventId) &
                e.exceptionType.equals('deleted'),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.occurrenceDate)]))
        .get();
  }

  /// Get all modified instances for a master event
  Future<List<RecurringEventException>> getModifiedInstances(
    int masterEventId,
  ) {
    return (select(recurringEventExceptions)
          ..where(
            (e) =>
                e.masterEventId.equals(masterEventId) &
                e.exceptionType.equals('modified'),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.occurrenceDate)]))
        .get();
  }

  /// Get all completed instances for a master event
  Future<List<RecurringEventException>> getCompletedInstances(
    int masterEventId,
  ) {
    return (select(recurringEventExceptions)
          ..where(
            (e) =>
                e.masterEventId.equals(masterEventId) &
                e.exceptionType.equals('completed'),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.occurrenceDate)]))
        .get();
  }

  // ========== UPDATE ==========

  /// Update an exception
  Future<bool> updateException(RecurringEventExceptionsCompanion exception) {
    return update(recurringEventExceptions).replace(exception);
  }

  /// Mark an instance as completed
  Future<void> markInstanceCompleted(
    int masterEventId,
    DateTime occurrenceDate,
  ) async {
    // Check if exception already exists
    final existing = await getExceptionForDate(masterEventId, occurrenceDate);

    if (existing != null) {
      // Update existing exception
      await (update(
        recurringEventExceptions,
      )..where((e) => e.id.equals(existing.id))).write(
        RecurringEventExceptionsCompanion(
          exceptionType: const Value('completed'),
          isCompleted: const Value(true),
          completedAt: Value(DateTime.now()),
        ),
      );
    } else {
      // Create new exception
      await createException(
        RecurringEventExceptionsCompanion.insert(
          masterEventId: masterEventId,
          occurrenceDate: occurrenceDate,
          exceptionType: 'completed',
          isCompleted: const Value(true),
          completedAt: Value(DateTime.now()),
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// Mark an instance as deleted
  Future<void> markInstanceDeleted(
    int masterEventId,
    DateTime occurrenceDate,
  ) async {
    // Check if exception already exists
    final existing = await getExceptionForDate(masterEventId, occurrenceDate);

    if (existing != null) {
      // Update existing exception
      await (update(
        recurringEventExceptions,
      )..where((e) => e.id.equals(existing.id))).write(
        const RecurringEventExceptionsCompanion(
          exceptionType: Value('deleted'),
        ),
      );
    } else {
      // Create new exception
      await createException(
        RecurringEventExceptionsCompanion.insert(
          masterEventId: masterEventId,
          occurrenceDate: occurrenceDate,
          exceptionType: 'deleted',
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  // ========== DELETE ==========

  /// Delete an exception
  Future<int> deleteException(int exceptionId) {
    return (delete(
      recurringEventExceptions,
    )..where((e) => e.id.equals(exceptionId))).go();
  }

  /// Delete all exceptions for a master event
  Future<int> deleteExceptionsForEvent(int masterEventId) {
    return (delete(
      recurringEventExceptions,
    )..where((e) => e.masterEventId.equals(masterEventId))).go();
  }

  /// Delete exception for specific occurrence
  Future<int> deleteExceptionForDate(
    int masterEventId,
    DateTime occurrenceDate,
  ) {
    return (delete(recurringEventExceptions)..where(
          (e) =>
              e.masterEventId.equals(masterEventId) &
              e.occurrenceDate.equals(occurrenceDate),
        ))
        .go();
  }

  // ========== STREAM ==========

  /// Watch exceptions for a master event
  Stream<List<RecurringEventException>> watchExceptionsForEvent(
    int masterEventId,
  ) {
    return (select(recurringEventExceptions)
          ..where((e) => e.masterEventId.equals(masterEventId))
          ..orderBy([(e) => OrderingTerm.asc(e.occurrenceDate)]))
        .watch();
  }

  /// Watch exceptions in date range
  Stream<List<RecurringEventException>> watchExceptionsInRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(recurringEventExceptions)
          ..where(
            (e) =>
                e.occurrenceDate.isBiggerOrEqualValue(startDate) &
                e.occurrenceDate.isSmallerOrEqualValue(endDate),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.occurrenceDate)]))
        .watch();
  }
}
