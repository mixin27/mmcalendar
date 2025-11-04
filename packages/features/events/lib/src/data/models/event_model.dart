import 'dart:convert';

import 'package:data/data.dart' as db;
import 'package:drift/drift.dart';

import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/entities/notification_setting.dart';
import '../../domain/entities/recurrence_rule.dart';

/// Data model for Event entity
class EventModel extends Event {
  const EventModel({
    super.id,
    required super.title,
    super.description,
    required super.eventDate,
    super.eventTime,
    super.isAllDay,
    required super.category,
    super.colorCode,
    super.recurrenceRule,
    super.notifications,
    super.location,
    super.status,
    super.priority,
    super.tags,
    required super.createdAt,
    required super.updatedAt,
    super.completedAt,
  });

  /// Convert from domain entity to data model
  factory EventModel.fromEntity(Event entity) {
    return EventModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      eventDate: entity.eventDate,
      eventTime: entity.eventTime,
      isAllDay: entity.isAllDay,
      category: entity.category,
      colorCode: entity.colorCode,
      recurrenceRule: entity.recurrenceRule,
      notifications: entity.notifications,
      location: entity.location,
      status: entity.status,
      priority: entity.priority,
      tags: entity.tags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      completedAt: entity.completedAt,
    );
  }

  /// Convert from database UserEvent to EventModel
  factory EventModel.fromDatabaseEntity(
    db.UserEvent dbEvent,
    EventCategory category,
  ) {
    return EventModel(
      id: dbEvent.id,
      title: dbEvent.title,
      description: dbEvent.description,
      eventDate: dbEvent.eventDate,
      eventTime: dbEvent.eventTime,
      isAllDay: dbEvent.isAllDay,
      category: category,
      colorCode: dbEvent.colorCode,
      recurrenceRule: dbEvent.recurrenceType != null
          ? _parseRecurrenceRule(
              dbEvent.recurrenceType,
              dbEvent.recurrenceInterval,
              dbEvent.recurrenceDays,
              dbEvent.recurrenceEndDate,
              dbEvent.recurrenceCount,
              dbEvent.eventDate,
            )
          : null,
      notifications: _parseNotifications(dbEvent.notificationTimes),
      location: dbEvent.location,
      status: dbEvent.isCompleted ? EventStatus.completed : EventStatus.pending,
      priority: EventPriority.fromValue(dbEvent.priority),
      tags: _parseTags(dbEvent.tags),
      createdAt: dbEvent.createdAt,
      updatedAt: dbEvent.updatedAt,
      completedAt: dbEvent.completedAt,
    );
  }

  /// Convert to database companion for insert/update
  db.UserEventsCompanion toDatabaseCompanion() {
    return db.UserEventsCompanion.insert(
      id: id != null ? Value(id!) : const Value.absent(),
      title: title,
      description: Value(description),
      eventDate: eventDate,
      eventTime: Value(eventTime),
      isAllDay: Value(isAllDay),
      category: category.name,
      categoryId: Value(category.id),
      colorCode: Value(colorCode),
      recurrenceType: Value(recurrenceRule?.type.name),
      recurrenceInterval: Value(recurrenceRule?.interval),
      recurrenceDays: Value(_serializeDaysOfWeek(recurrenceRule?.daysOfWeek)),
      recurrenceEndDate: Value(recurrenceRule?.endDate),
      recurrenceCount: Value(recurrenceRule?.occurrenceCount),
      isRecurringMaster: Value(recurrenceRule != null),
      hasNotification: Value(notifications.isNotEmpty),
      notificationTimes: Value(_serializeNotifications(notifications)),
      location: Value(location),
      isCompleted: Value(status == EventStatus.completed),
      completedAt: Value(completedAt),
      priority: Value(priority.value),
      tags: Value(_serializeTags(tags)),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  // ============================================================================
  // SERIALIZATION HELPERS
  // ============================================================================

  static RecurrenceRule? _parseRecurrenceRule(
    String? typeStr,
    int? interval,
    String? daysJson,
    DateTime? endDate,
    int? count,
    DateTime originalEventDate, // Pass the original event date
  ) {
    if (typeStr == null) return null;

    final type = RecurrenceType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => RecurrenceType.none,
    );

    if (type == RecurrenceType.none) return null;

    // Extract month and day from original event date for yearly/monthly recurrence
    int? dayOfMonth;
    int? monthOfYear;

    if (type == RecurrenceType.yearly) {
      monthOfYear = originalEventDate.month;
      dayOfMonth = originalEventDate.day;
    } else if (type == RecurrenceType.monthly) {
      dayOfMonth = originalEventDate.day;
    }

    return RecurrenceRule(
      type: type,
      interval: interval ?? 1,
      daysOfWeek: _parseDaysOfWeek(daysJson),
      dayOfMonth: dayOfMonth,
      monthOfYear: monthOfYear,
      endDate: endDate,
      occurrenceCount: count,
    );
  }

  static List<int>? _parseDaysOfWeek(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => e as int).toList();
    } catch (e) {
      return null;
    }
  }

  static String? _serializeDaysOfWeek(List<int>? days) {
    if (days == null || days.isEmpty) return null;
    return jsonEncode(days);
  }

  static List<NotificationSetting> _parseNotifications(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((minutes) => NotificationSetting(minutesBefore: minutes as int))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static String? _serializeNotifications(
    List<NotificationSetting> notifications,
  ) {
    if (notifications.isEmpty) return null;
    final minutes = notifications.map((n) => n.minutesBefore).toList();
    return jsonEncode(minutes);
  }

  static List<String> _parseTags(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  static String? _serializeTags(List<String> tags) {
    if (tags.isEmpty) return null;
    return jsonEncode(tags);
  }

  /// Convert to domain entity
  Event toEntity() {
    return Event(
      id: id,
      title: title,
      description: description,
      eventDate: eventDate,
      eventTime: eventTime,
      isAllDay: isAllDay,
      category: category,
      colorCode: colorCode,
      recurrenceRule: recurrenceRule,
      notifications: notifications,
      location: location,
      status: status,
      priority: priority,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
    );
  }

  @override
  EventModel copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? eventDate,
    DateTime? eventTime,
    bool? isAllDay,
    EventCategory? category,
    int? colorCode,
    RecurrenceRule? recurrenceRule,
    List<NotificationSetting>? notifications,
    String? location,
    EventStatus? status,
    EventPriority? priority,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      isAllDay: isAllDay ?? this.isAllDay,
      category: category ?? this.category,
      colorCode: colorCode ?? this.colorCode,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      notifications: notifications ?? this.notifications,
      location: location ?? this.location,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
