import 'package:shared_core/shared_core.dart';

import '../domain/entities/event.dart';
import '../domain/entities/notification_setting.dart';
import '../domain/repositories/events_repository.dart';

class RepositoryEventMarkersPort implements EventMarkersPort {
  RepositoryEventMarkersPort(this._eventsRepository);

  final EventsRepository _eventsRepository;

  @override
  Stream<Map<DateTime, List<CalendarEventItem>>> watchEventMarkers({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _eventsRepository.watchEventsByDateRange(startDate, endDate).map((
      result,
    ) {
      return result.fold(
        (failure) => throw StateError(failure.message),
        _groupByDate,
      );
    });
  }

  @override
  Stream<List<CalendarEventItem>> watchEventsForDate(DateTime date) {
    return _eventsRepository.watchEventsByDate(date).map((result) {
      return result.fold(
        (failure) => throw StateError(failure.message),
        (events) => events.map(_mapToCalendarEventItem).toList(growable: false),
      );
    });
  }

  @override
  Future<void> toggleEventCompletion({
    required int eventId,
    required bool isCompleted,
  }) async {
    final result = await _eventsRepository.toggleEventCompletion(
      eventId,
      isCompleted,
    );
    result.fold((failure) => throw StateError(failure.message), (_) => null);
  }

  Map<DateTime, List<CalendarEventItem>> _groupByDate(List<Event> events) {
    final grouped = <DateTime, List<CalendarEventItem>>{};
    for (final event in events) {
      final key = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );
      grouped.putIfAbsent(key, () => <CalendarEventItem>[]);
      grouped[key]!.add(_mapToCalendarEventItem(event));
    }
    return grouped;
  }

  CalendarEventItem _mapToCalendarEventItem(Event event) {
    return CalendarEventItem(
      id: event.id,
      title: event.title,
      eventDate: event.eventDate,
      eventTime: event.eventTime,
      isAllDay: event.isAllDay,
      category: CalendarEventCategory(
        name: event.category.name,
        iconName: event.category.iconName,
        colorCode: event.category.colorCode,
      ),
      colorCode: event.colorCode,
      isRecurring: event.isRecurring,
      notifications: event.notifications
          .map(_mapToCalendarEventNotification)
          .toList(growable: false),
      location: event.location,
      status: _mapStatus(event.status),
      priority: _mapPriority(event.priority),
    );
  }

  CalendarEventNotification _mapToCalendarEventNotification(
    NotificationSetting notification,
  ) {
    return CalendarEventNotification(
      minutesBefore: notification.minutesBefore,
      label: notification.displayName,
    );
  }

  CalendarEventStatus _mapStatus(EventStatus status) {
    switch (status) {
      case EventStatus.pending:
        return CalendarEventStatus.pending;
      case EventStatus.completed:
        return CalendarEventStatus.completed;
      case EventStatus.cancelled:
        return CalendarEventStatus.cancelled;
    }
  }

  CalendarEventPriority _mapPriority(EventPriority priority) {
    switch (priority) {
      case EventPriority.low:
        return CalendarEventPriority.low;
      case EventPriority.normal:
        return CalendarEventPriority.normal;
      case EventPriority.high:
        return CalendarEventPriority.high;
      case EventPriority.urgent:
        return CalendarEventPriority.urgent;
    }
  }
}
