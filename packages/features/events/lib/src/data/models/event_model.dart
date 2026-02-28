import 'dart:convert';

import 'package:integrations_database/integrations_database.dart' as db;
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

  /// Convert from normalized v2 event schema to EventModel.
  factory EventModel.fromV2DatabaseEntity(
    db.CalendarEvent dbEvent, {
    required EventCategory category,
    db.EventRecurrenceRule? recurrenceRule,
    List<db.EventReminder> reminders = const [],
  }) {
    return EventModel(
      id: dbEvent.id,
      title: dbEvent.title,
      description: dbEvent.description,
      eventDate: dbEvent.eventDate,
      eventTime: dbEvent.eventTime,
      isAllDay: dbEvent.isAllDay,
      category: category,
      colorCode: dbEvent.colorCode,
      recurrenceRule: _parseV2RecurrenceRule(recurrenceRule, dbEvent.eventDate),
      notifications: _parseV2Notifications(reminders),
      location: dbEvent.location,
      status: parseStatus(dbEvent.status),
      priority: EventPriority.fromValue(dbEvent.priority),
      tags: _parseTags(dbEvent.tags),
      createdAt: dbEvent.createdAt,
      updatedAt: dbEvent.updatedAt,
      completedAt: dbEvent.completedAt,
    );
  }

  /// Convert to normalized v2 event companion.
  db.CalendarEventsCompanion toCalendarEventCompanion({
    required EventCategory category,
  }) {
    return db.CalendarEventsCompanion.insert(
      id: id != null ? Value(id!) : const Value.absent(),
      title: title,
      description: Value(description),
      eventDate: eventDate,
      eventTime: Value(eventTime),
      isAllDay: Value(isAllDay),
      timezoneId: const Value('Asia/Yangon'),
      categoryId: Value(category.id),
      categoryName: Value(category.name),
      colorCode: Value(colorCode),
      location: Value(location),
      status: Value(serializeStatus(status)),
      priority: Value(priority.value),
      tags: Value(_serializeTags(tags)),
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: Value(completedAt),
      legacyEventId: id != null ? Value(id) : const Value.absent(),
    );
  }

  db.EventRecurrenceRulesCompanion? toRecurrenceCompanion({
    required int eventId,
    required DateTime now,
  }) {
    final rule = recurrenceRule;
    if (rule == null || rule.type == RecurrenceType.none) {
      return null;
    }

    return db.EventRecurrenceRulesCompanion.insert(
      eventId: Value(eventId),
      recurrenceType: rule.type.name,
      recurrenceInterval: Value(rule.interval),
      recurrenceDays: Value(_serializeDaysOfWeek(rule.daysOfWeek)),
      dayOfMonth: Value(rule.dayOfMonth),
      monthOfYear: Value(rule.monthOfYear),
      recurrenceEndDate: Value(rule.endDate),
      recurrenceCount: Value(rule.occurrenceCount),
      createdAt: now,
      updatedAt: now,
    );
  }

  List<db.EventRemindersCompanion> toReminderCompanions({
    required int eventId,
    required DateTime now,
  }) {
    return notifications
        .map(
          (notification) => db.EventRemindersCompanion.insert(
            eventId: eventId,
            minutesBefore: notification.minutesBefore,
            channel: Value(notification.channel.name),
            createdAt: now,
          ),
        )
        .toList(growable: false);
  }

  // ============================================================================
  // SERIALIZATION HELPERS
  // ============================================================================

  static EventStatus parseStatus(String status) {
    switch (status) {
      case 'completed':
        return EventStatus.completed;
      case 'cancelled':
        return EventStatus.cancelled;
      case 'pending':
      default:
        return EventStatus.pending;
    }
  }

  static String serializeStatus(EventStatus status) {
    switch (status) {
      case EventStatus.completed:
        return 'completed';
      case EventStatus.cancelled:
        return 'cancelled';
      case EventStatus.pending:
        return 'pending';
    }
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

  static List<NotificationSetting> _parseV2Notifications(
    List<db.EventReminder> reminders,
  ) {
    if (reminders.isEmpty) return const [];
    final parsed = reminders
        .map(
          (reminder) => NotificationSetting(
            minutesBefore: reminder.minutesBefore,
            channel: _parseNotificationChannel(reminder.channel),
          ),
        )
        .toList(growable: false);
    parsed.sort((a, b) => b.minutesBefore.compareTo(a.minutesBefore));
    return parsed;
  }

  static NotificationChannel _parseNotificationChannel(String channel) {
    switch (channel) {
      case 'push':
        return NotificationChannel.push;
      case 'email':
        return NotificationChannel.email;
      case 'local':
      default:
        return NotificationChannel.local;
    }
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

  static RecurrenceRule? _parseV2RecurrenceRule(
    db.EventRecurrenceRule? rule,
    DateTime originalEventDate,
  ) {
    if (rule == null) return null;

    final type = RecurrenceType.values.firstWhere(
      (item) => item.name == rule.recurrenceType,
      orElse: () => RecurrenceType.none,
    );
    if (type == RecurrenceType.none) return null;

    return RecurrenceRule(
      type: type,
      interval: rule.recurrenceInterval,
      daysOfWeek: _parseDaysOfWeek(rule.recurrenceDays),
      dayOfMonth:
          rule.dayOfMonth ??
          (type == RecurrenceType.monthly ? originalEventDate.day : null),
      monthOfYear:
          rule.monthOfYear ??
          (type == RecurrenceType.yearly ? originalEventDate.month : null),
      endDate: rule.recurrenceEndDate,
      occurrenceCount: rule.recurrenceCount,
    );
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
}
