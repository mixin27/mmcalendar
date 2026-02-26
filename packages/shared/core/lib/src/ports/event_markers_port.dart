import 'package:equatable/equatable.dart';

class CalendarEventCategory extends Equatable {
  const CalendarEventCategory({
    required this.name,
    required this.iconName,
    required this.colorCode,
  });

  final String name;
  final String iconName;
  final int colorCode;

  @override
  List<Object?> get props => <Object?>[name, iconName, colorCode];
}

class CalendarEventNotification extends Equatable {
  const CalendarEventNotification({
    required this.minutesBefore,
    required this.label,
  });

  final int minutesBefore;
  final String label;

  @override
  List<Object?> get props => <Object?>[minutesBefore, label];
}

enum CalendarEventStatus { pending, completed, cancelled }

enum CalendarEventPriority { low, normal, high, urgent }

class CalendarEventItem extends Equatable {
  const CalendarEventItem({
    this.id,
    required this.title,
    required this.eventDate,
    this.eventTime,
    required this.isAllDay,
    required this.category,
    this.colorCode,
    required this.isRecurring,
    this.notifications = const <CalendarEventNotification>[],
    this.location,
    this.status = CalendarEventStatus.pending,
    this.priority = CalendarEventPriority.normal,
  });

  final int? id;
  final String title;
  final DateTime eventDate;
  final DateTime? eventTime;
  final bool isAllDay;
  final CalendarEventCategory category;
  final int? colorCode;
  final bool isRecurring;
  final List<CalendarEventNotification> notifications;
  final String? location;
  final CalendarEventStatus status;
  final CalendarEventPriority priority;

  int get effectiveColor => colorCode ?? category.colorCode;

  bool get isCompleted => status == CalendarEventStatus.completed;

  bool get hasNotifications => notifications.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    eventDate,
    eventTime,
    isAllDay,
    category,
    colorCode,
    isRecurring,
    notifications,
    location,
    status,
    priority,
  ];
}

abstract interface class EventMarkersPort {
  Stream<Map<DateTime, List<CalendarEventItem>>> watchEventMarkers({
    required DateTime startDate,
    required DateTime endDate,
  });

  Stream<List<CalendarEventItem>> watchEventsForDate(DateTime date);

  Future<void> toggleEventCompletion({
    required int eventId,
    required bool isCompleted,
  });
}
