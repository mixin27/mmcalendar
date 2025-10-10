import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final int id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final DateTime? eventTime;
  final bool isAllDay;
  final String category;
  final int? categoryId;
  final int? colorCode;
  final RecurrenceRule? recurrence;
  final bool hasNotification;
  final List<int>? notificationMinutes;
  final String? location;
  final bool isCompleted;
  final DateTime? completedAt;
  final int priority;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.eventTime,
    required this.isAllDay,
    required this.category,
    this.categoryId,
    this.colorCode,
    this.recurrence,
    required this.hasNotification,
    this.notificationMinutes,
    this.location,
    required this.isCompleted,
    this.completedAt,
    required this.priority,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  Event copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? eventDate,
    DateTime? eventTime,
    bool? isAllDay,
    String? category,
    int? categoryId,
    int? colorCode,
    RecurrenceRule? recurrence,
    bool? hasNotification,
    List<int>? notificationMinutes,
    String? location,
    bool? isCompleted,
    DateTime? completedAt,
    int? priority,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      isAllDay: isAllDay ?? this.isAllDay,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      colorCode: colorCode ?? this.colorCode,
      recurrence: recurrence ?? this.recurrence,
      hasNotification: hasNotification ?? this.hasNotification,
      notificationMinutes: notificationMinutes ?? this.notificationMinutes,
      location: location ?? this.location,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    eventDate,
    eventTime,
    isAllDay,
    category,
    categoryId,
    colorCode,
    recurrence,
    hasNotification,
    notificationMinutes,
    location,
    isCompleted,
    completedAt,
    priority,
    tags,
    createdAt,
    updatedAt,
  ];
}

class RecurrenceRule extends Equatable {
  final String type;
  final int interval;
  final List<int>? daysOfWeek;
  final DateTime? endDate;
  final int? count;

  const RecurrenceRule({
    required this.type,
    required this.interval,
    this.daysOfWeek,
    this.endDate,
    this.count,
  });

  @override
  List<Object?> get props => [type, interval, daysOfWeek, endDate, count];
}

class EventCategory extends Equatable {
  final int id;
  final String name;
  final String iconName;
  final int colorCode;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;

  const EventCategory({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorCode,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    iconName,
    colorCode,
    isDefault,
    sortOrder,
    createdAt,
  ];
}
