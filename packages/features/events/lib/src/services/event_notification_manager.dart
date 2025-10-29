import 'dart:async';

import 'package:core/core.dart';

import '../domain/entities/event.dart';
import 'notification_service.dart';

/// Manages event notifications and scheduling
class EventNotificationManager {
  final NotificationService notificationService;
  StreamSubscription? _eventSubscription;
  bool _isMonitoring = false;

  EventNotificationManager({required this.notificationService});

  /// Start monitoring events for notifications
  void startMonitoring() {
    if (_isMonitoring) return;

    // Listen to event domain events
    _eventSubscription = AppEventBus.on<EventCreatedEvent>().listen((event) {
      _handleEventCreated(event);
    });

    _eventSubscription = AppEventBus.on<EventUpdatedEvent>().listen((event) {
      _handleEventUpdated(event);
    });

    _eventSubscription = AppEventBus.on<EventDeletedEvent>().listen((event) {
      _handleEventDeleted(event);
    });

    _isMonitoring = true;
  }

  /// Stop monitoring events
  void stopMonitoring() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _isMonitoring = false;
  }

  /// Schedule all notifications for an event
  Future<void> scheduleEventNotifications(Event event) async {
    if (event.id == null || event.notifications.isEmpty) return;

    for (final notification in event.notifications) {
      await notificationService.scheduleNotification(event, notification);
    }
  }

  /// Cancel all notifications for an event
  Future<void> cancelEventNotifications(int eventId) async {
    // Cancel notifications with various time intervals
    final commonIntervals = [0, 5, 15, 30, 60, 1440]; // minutes
    for (final interval in commonIntervals) {
      final notificationId = (eventId * 10000) + interval;
      await notificationService.cancelNotification(notificationId);
    }
  }

  /// Handle event created
  Future<void> _handleEventCreated(EventCreatedEvent event) async {
    // Event will be scheduled when full event object is available
    // This is handled by the BLoC after successful creation
  }

  /// Handle event updated
  Future<void> _handleEventUpdated(EventUpdatedEvent event) async {
    // Cancel old notifications and reschedule
    await cancelEventNotifications(event.eventId);
    // New notifications will be scheduled by the caller
  }

  /// Handle event deleted
  Future<void> _handleEventDeleted(EventDeletedEvent event) async {
    await cancelEventNotifications(event.eventId);
  }

  /// Check and reschedule all pending notifications
  Future<void> rescheduleAllNotifications(List<Event> events) async {
    // Cancel all existing notifications
    await notificationService.cancelAllNotifications();

    // Schedule notifications for all upcoming events
    for (final event in events) {
      if (event.notifications.isNotEmpty && !event.isCompleted) {
        await scheduleEventNotifications(event);
      }
    }
  }

  /// Get count of pending notifications
  Future<int> getPendingNotificationsCount() async {
    final pending = await notificationService.getPendingNotifications();
    return pending.length;
  }

  void dispose() {
    stopMonitoring();
  }
}
