import 'dart:convert';

import 'package:data/data.dart' as db;

import '../../domain/entities/event.dart';

class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.title,
    super.description,
    required super.eventDate,
    super.eventTime,
    required super.isAllDay,
    required super.category,
    super.categoryId,
    super.colorCode,
    super.recurrence,
    required super.hasNotification,
    super.notificationMinutes,
    super.location,
    required super.isCompleted,
    super.completedAt,
    required super.priority,
    super.tags,
    required super.createdAt,
    required super.updatedAt,
  });

  factory EventModel.fromDrift(db.UserEvent event) {
    return EventModel(
      id: event.id,
      title: event.title,
      description: event.description,
      eventDate: event.eventDate,
      eventTime: event.eventTime,
      isAllDay: event.isAllDay,
      category: event.category,
      categoryId: event.categoryId,
      colorCode: event.colorCode,
      recurrence: _parseRecurrence(event),
      hasNotification: event.hasNotification,
      notificationMinutes: _parseIntList(event.notificationTimes),
      location: event.location,
      isCompleted: event.isCompleted,
      completedAt: event.completedAt,
      priority: event.priority,
      tags: _parseStringList(event.tags),
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    );
  }

  Event toEntity() {
    return Event(
      id: id,
      title: title,
      eventDate: eventDate,
      isAllDay: isAllDay,
      category: category,
      hasNotification: hasNotification,
      isCompleted: isCompleted,
      priority: priority,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static RecurrenceRule? _parseRecurrence(db.UserEvent event) {
    if (event.recurrenceType == null) return null;
    return RecurrenceRule(
      type: event.recurrenceType!,
      interval: event.recurrenceInterval ?? 1,
      daysOfWeek: _parseIntList(event.recurrenceDays),
      endDate: event.recurrenceEndDate,
      count: event.recurrenceCount,
    );
  }

  static List<int>? _parseIntList(String? json) {
    if (json == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.cast<int>();
    } catch (e) {
      return null;
    }
  }

  static List<String>? _parseStringList(String? json) {
    if (json == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.cast<String>();
    } catch (e) {
      return null;
    }
  }
}

class CategoryModel extends EventCategory {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.iconName,
    required super.colorCode,
    required super.isDefault,
    required super.sortOrder,
    required super.createdAt,
  });

  factory CategoryModel.fromDrift(db.EventCategory category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      iconName: category.iconName,
      colorCode: category.colorCode,
      isDefault: category.isDefault,
      sortOrder: category.sortOrder,
      createdAt: category.createdAt,
    );
  }

  EventCategory toEntity() {
    return EventCategory(
      id: id,
      name: name,
      iconName: iconName,
      colorCode: colorCode,
      isDefault: isDefault,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }
}
