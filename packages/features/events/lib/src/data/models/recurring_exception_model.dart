import 'package:integrations_database/integrations_database.dart' as db;
import 'package:drift/drift.dart';

import '../../domain/entities/recurrence_rule.dart';

class RecurringExceptionModel {
  final int id;
  final int masterEventId;
  final DateTime occurrenceDate;
  final ExceptionType exceptionType;
  final String? modifiedTitle;
  final String? modifiedDescription;
  final DateTime? modifiedDate;
  final DateTime? modifiedTime;
  final String? modifiedLocation;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  const RecurringExceptionModel({
    required this.id,
    required this.masterEventId,
    required this.occurrenceDate,
    required this.exceptionType,
    this.modifiedTitle,
    this.modifiedDescription,
    this.modifiedDate,
    this.modifiedTime,
    this.modifiedLocation,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });

  /// Convert from database entity
  factory RecurringExceptionModel.fromDatabaseEntity(
    db.RecurringEventException dbException,
  ) {
    return RecurringExceptionModel(
      id: dbException.id,
      masterEventId: dbException.masterEventId,
      occurrenceDate: dbException.occurrenceDate,
      exceptionType: _parseExceptionType(dbException.exceptionType),
      modifiedTitle: dbException.modifiedTitle,
      modifiedDescription: dbException.modifiedDescription,
      modifiedDate: dbException.modifiedDate,
      modifiedTime: dbException.modifiedTime,
      modifiedLocation: dbException.modifiedLocation,
      isCompleted: dbException.isCompleted,
      completedAt: dbException.completedAt,
      createdAt: dbException.createdAt,
    );
  }

  /// Convert to database companion
  db.RecurringEventExceptionsCompanion toDatabaseCompanion() {
    return db.RecurringEventExceptionsCompanion.insert(
      id: Value(id),
      masterEventId: masterEventId,
      occurrenceDate: occurrenceDate,
      exceptionType: exceptionType.name,
      modifiedTitle: Value(modifiedTitle),
      modifiedDescription: Value(modifiedDescription),
      modifiedDate: Value(modifiedDate),
      modifiedTime: Value(modifiedTime),
      modifiedLocation: Value(modifiedLocation),
      isCompleted: Value(isCompleted),
      completedAt: Value(completedAt),
      createdAt: createdAt,
    );
  }

  /// Convert to domain entity
  RecurringEventException toEntity() {
    return RecurringEventException(
      id: id,
      masterEventId: masterEventId,
      occurrenceDate: occurrenceDate,
      exceptionType: exceptionType,
      modifiedTitle: modifiedTitle,
      modifiedDescription: modifiedDescription,
      modifiedDate: modifiedDate,
      modifiedTime: modifiedTime,
      modifiedLocation: modifiedLocation,
      isCompleted: isCompleted,
      completedAt: completedAt,
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory RecurringExceptionModel.fromEntity(RecurringEventException entity) {
    return RecurringExceptionModel(
      id: entity.id,
      masterEventId: entity.masterEventId,
      occurrenceDate: entity.occurrenceDate,
      exceptionType: entity.exceptionType,
      modifiedTitle: entity.modifiedTitle,
      modifiedDescription: entity.modifiedDescription,
      modifiedDate: entity.modifiedDate,
      modifiedTime: entity.modifiedTime,
      modifiedLocation: entity.modifiedLocation,
      isCompleted: entity.isCompleted,
      completedAt: entity.completedAt,
      createdAt: entity.createdAt,
    );
  }

  static ExceptionType _parseExceptionType(String typeStr) {
    return ExceptionType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => ExceptionType.modified,
    );
  }

  RecurringExceptionModel copyWith({
    int? id,
    int? masterEventId,
    DateTime? occurrenceDate,
    ExceptionType? exceptionType,
    String? modifiedTitle,
    String? modifiedDescription,
    DateTime? modifiedDate,
    DateTime? modifiedTime,
    String? modifiedLocation,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return RecurringExceptionModel(
      id: id ?? this.id,
      masterEventId: masterEventId ?? this.masterEventId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      exceptionType: exceptionType ?? this.exceptionType,
      modifiedTitle: modifiedTitle ?? this.modifiedTitle,
      modifiedDescription: modifiedDescription ?? this.modifiedDescription,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      modifiedLocation: modifiedLocation ?? this.modifiedLocation,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
