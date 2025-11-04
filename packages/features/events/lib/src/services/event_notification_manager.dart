import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/entities/event.dart';
import 'notification_service.dart';

/// Manages event notifications and scheduling
/// This is the LOW-LEVEL manager that handles individual notification operations
/// Use SmartNotificationScheduler for high-level scheduling logic
class EventNotificationManager {
  final NotificationService notificationService;

  EventNotificationManager({required this.notificationService});

  // ============================================================================
  // SCHEDULE NOTIFICATIONS
  // ============================================================================

  /// Schedule all notifications for an event
  /// Handles both one-time and recurring events
  Future<void> scheduleEventNotifications(Event event) async {
    if (event.id == null || event.notifications.isEmpty) return;

    try {
      for (final notification in event.notifications) {
        await notificationService.scheduleNotification(event, notification);
      }
      debugPrint(
        'EventNotificationManager: Scheduled ${event.notifications.length} notifications for "${event.title}"',
      );
    } catch (e) {
      debugPrint(
        'EventNotificationManager: Error scheduling notifications - $e',
      );
    }
  }

  /// Cancel all notifications for an event
  Future<void> cancelEventNotifications(int eventId) async {
    try {
      // Cancel notifications with various time intervals
      final commonIntervals = [0, 5, 15, 30, 60, 1440]; // minutes
      for (final interval in commonIntervals) {
        final notificationId = _generateNotificationId(eventId, interval);
        await notificationService.cancelNotification(notificationId);
      }
      debugPrint(
        'EventNotificationManager: Cancelled notifications for event $eventId',
      );
    } catch (e) {
      debugPrint(
        'EventNotificationManager: Error cancelling notifications - $e',
      );
    }
  }

  /// Reschedule notifications for an event (cancel old + schedule new)
  Future<void> rescheduleEventNotifications(Event event) async {
    if (event.id == null) return;

    await cancelEventNotifications(event.id!);
    await scheduleEventNotifications(event);
  }

  // ============================================================================
  // BATCH OPERATIONS
  // ============================================================================

  /// Check and reschedule all pending notifications
  /// This is called by SmartNotificationScheduler
  Future<void> rescheduleAllNotifications(List<Event> events) async {
    try {
      // Cancel all existing notifications
      await notificationService.cancelAllNotifications();

      // Schedule notifications for all upcoming events
      int scheduledCount = 0;
      for (final event in events) {
        if (event.notifications.isNotEmpty && !event.isCompleted) {
          await scheduleEventNotifications(event);
          scheduledCount++;
        }
      }

      debugPrint(
        'EventNotificationManager: Rescheduled $scheduledCount events',
      );
    } catch (e) {
      debugPrint(
        'EventNotificationManager: Error rescheduling all notifications - $e',
      );
    }
  }

  // ============================================================================
  // DIAGNOSTICS
  // ============================================================================

  /// Get count of pending notifications
  Future<int> getPendingNotificationsCount() async {
    try {
      final pending = await notificationService.getPendingNotifications();
      return pending.length;
    } catch (e) {
      debugPrint(
        'EventNotificationManager: Error getting notification count - $e',
      );
      return 0;
    }
  }

  /// Get list of pending notifications with details
  Future<List<Map<String, dynamic>>> getPendingNotificationsDetails() async {
    try {
      final pending = await notificationService.getPendingNotifications();
      return pending.map((notification) {
        return {
          'id': notification.id,
          'title': notification.title,
          'body': notification.body,
          'payload': notification.payload,
        };
      }).toList();
    } catch (e) {
      debugPrint(
        'EventNotificationManager: Error getting notification details - $e',
      );
      return [];
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Generate unique notification ID
  /// Format: eventId * 10000 + minutesBefore
  /// This ensures each event+time combination has a unique ID
  int _generateNotificationId(int eventId, int minutesBefore) {
    return (eventId * 10000) + minutesBefore;
  }

  void dispose() {
    // Cleanup if needed
  }
}
