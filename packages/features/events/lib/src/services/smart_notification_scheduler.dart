import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/entities/event.dart';
import '../domain/repositories/events_repository.dart';
import 'event_notification_manager.dart';

/// Smart scheduler that handles recurring event notifications efficiently
///
/// Key Features:
/// - Only schedules notifications for the next 30 days (not all future occurrences)
/// - Automatically refreshes notifications daily
/// - Handles recurring instances properly
/// - Supports background scheduling via WorkManager (optional)
class SmartNotificationScheduler {
  final EventNotificationManager notificationManager;
  final EventsRepository eventsRepository;

  Timer? _refreshTimer;
  bool _isInitialized = false;

  // Configuration
  static const int lookAheadDays =
      30; // Schedule notifications for next 30 days
  static const Duration refreshInterval = Duration(hours: 24); // Refresh daily

  SmartNotificationScheduler({
    required this.notificationManager,
    required this.eventsRepository,
  });

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize the smart scheduler
  /// Call this when app starts
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('SmartNotificationScheduler: Initializing...');

    // Schedule initial notifications
    await scheduleUpcomingNotifications();

    // Start auto-refresh timer
    startAutoRefresh();

    _isInitialized = true;
    debugPrint('SmartNotificationScheduler: Initialized successfully');
  }

  /// Dispose the scheduler
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _isInitialized = false;
    debugPrint('SmartNotificationScheduler: Disposed');
  }

  // ============================================================================
  // SCHEDULING LOGIC
  // ============================================================================

  /// Schedule notifications for upcoming events (next 30 days)
  /// This includes virtual instances of recurring events
  Future<void> scheduleUpcomingNotifications() async {
    try {
      debugPrint(
        'SmartNotificationScheduler: Scheduling upcoming notifications...',
      );

      final now = DateTime.now();
      final lookAheadDate = now.add(const Duration(days: lookAheadDays));

      // Get all events in the next 30 days (includes virtual instances)
      final result = await eventsRepository.getEventsByDateRange(
        now,
        lookAheadDate,
      );

      await result.fold(
        (failure) async {
          debugPrint(
            'SmartNotificationScheduler: Failed to get events - $failure',
          );
        },
        (events) async {
          debugPrint(
            'SmartNotificationScheduler: Found ${events.length} events',
          );

          int scheduledCount = 0;

          for (final event in events) {
            // Skip completed events
            if (event.isCompleted) continue;

            // Skip events without notifications
            if (!event.hasNotifications) continue;

            // Skip past events
            if (event.eventDateTime.isBefore(now)) continue;

            // Schedule notifications for this event
            await notificationManager.scheduleEventNotifications(event);
            scheduledCount++;
          }

          debugPrint(
            'SmartNotificationScheduler: Scheduled $scheduledCount event notifications',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'SmartNotificationScheduler: Error scheduling notifications - $e',
      );
    }
  }

  /// Reschedule all notifications
  /// Useful after:
  /// - Creating/updating/deleting events
  /// - Completing/deleting recurring instances
  /// - Modifying recurring instances
  Future<void> rescheduleAllNotifications() async {
    try {
      debugPrint(
        'SmartNotificationScheduler: Rescheduling all notifications...',
      );

      // Cancel all existing notifications
      await notificationManager.notificationService.cancelAllNotifications();

      // Schedule fresh notifications
      await scheduleUpcomingNotifications();

      debugPrint('SmartNotificationScheduler: Rescheduled successfully');
    } catch (e) {
      debugPrint('SmartNotificationScheduler: Error rescheduling - $e');
    }
  }

  /// Schedule notification for a specific event
  /// Call this immediately after creating/updating an event
  ///
  /// For recurring events: Schedules notifications for next 30 days of occurrences
  /// For one-time events: Schedules notification for the event date
  Future<void> scheduleEventNotification(Event event) async {
    try {
      if (!event.hasNotifications || event.isCompleted) return;

      if (event.isRecurring && event.recurrenceRule != null) {
        // For recurring events, schedule for next 30 days
        await _scheduleRecurringNotifications(event);
      } else {
        // For one-time events, schedule normally
        await notificationManager.scheduleEventNotifications(event);
        debugPrint(
          'SmartNotificationScheduler: Scheduled notification for "${event.title}"',
        );
      }
    } catch (e) {
      debugPrint(
        'SmartNotificationScheduler: Error scheduling event notification - $e',
      );
    }
  }

  /// Schedule notifications for recurring event's virtual instances
  Future<void> _scheduleRecurringNotifications(Event masterEvent) async {
    try {
      final now = DateTime.now();
      final lookAheadDate = now.add(const Duration(days: lookAheadDays));

      // Generate virtual instances for next 30 days
      final occurrences = masterEvent.recurrenceRule!.generateOccurrences(
        masterEvent.eventDate,
        now,
        lookAheadDate,
      );

      debugPrint(
        'SmartNotificationScheduler: Scheduling notifications for ${occurrences.length} '
        'occurrences of "${masterEvent.title}"',
      );

      int scheduledCount = 0;

      // Schedule notification for each occurrence
      for (final occurrenceDate in occurrences) {
        // Skip past dates
        if (occurrenceDate.isBefore(now)) continue;

        // Create a virtual event for this occurrence
        final virtualEvent = masterEvent.copyWith(
          eventDate: occurrenceDate,
          eventTime: masterEvent.eventTime != null
              ? DateTime(
                  occurrenceDate.year,
                  occurrenceDate.month,
                  occurrenceDate.day,
                  masterEvent.eventTime!.hour,
                  masterEvent.eventTime!.minute,
                  masterEvent.eventTime!.second,
                )
              : null,
        );

        // Schedule notifications for this specific occurrence
        await notificationManager.scheduleEventNotifications(virtualEvent);
        scheduledCount++;
      }

      debugPrint(
        'SmartNotificationScheduler: Scheduled notifications for $scheduledCount '
        'occurrences of "${masterEvent.title}"',
      );
    } catch (e) {
      debugPrint(
        'SmartNotificationScheduler: Error scheduling recurring notifications - $e',
      );
    }
  }

  /// Cancel notifications for a specific event
  /// Call this before deleting an event or completing all instances
  Future<void> cancelEventNotifications(int eventId) async {
    try {
      await notificationManager.cancelEventNotifications(eventId);
      debugPrint(
        'SmartNotificationScheduler: Cancelled notifications for event $eventId',
      );
    } catch (e) {
      debugPrint(
        'SmartNotificationScheduler: Error cancelling notifications - $e',
      );
    }
  }

  // ============================================================================
  // AUTO-REFRESH
  // ============================================================================

  /// Start automatic daily refresh of notifications
  void startAutoRefresh() {
    if (_refreshTimer != null) return;

    debugPrint('SmartNotificationScheduler: Starting auto-refresh timer');

    _refreshTimer = Timer.periodic(refreshInterval, (timer) {
      debugPrint('SmartNotificationScheduler: Auto-refresh triggered');
      rescheduleAllNotifications();
    });
  }

  /// Stop automatic refresh
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    debugPrint('SmartNotificationScheduler: Stopped auto-refresh timer');
  }

  // ============================================================================
  // RECURRING INSTANCE HANDLING
  // ============================================================================

  /// Handle notification for completing a recurring instance
  /// This should reschedule to show the next occurrence properly
  Future<void> onRecurringInstanceCompleted({
    required int masterEventId,
    required DateTime occurrenceDate,
  }) async {
    try {
      debugPrint(
        'SmartNotificationScheduler: Instance completed - rescheduling...',
      );

      // Simple approach: Reschedule all notifications
      // This ensures the next occurrence gets proper notifications
      await rescheduleAllNotifications();
    } catch (e) {
      debugPrint(
        'SmartNotificationScheduler: Error handling completed instance - $e',
      );
    }
  }

  /// Handle notification for deleting a recurring instance
  Future<void> onRecurringInstanceDeleted({
    required int masterEventId,
    required DateTime occurrenceDate,
  }) async {
    try {
      debugPrint(
        'SmartNotificationScheduler: Instance deleted - rescheduling...',
      );

      // Reschedule to remove notifications for deleted instance
      await rescheduleAllNotifications();
    } catch (e) {
      debugPrint(
        'SmartNotificationScheduler: Error handling deleted instance - $e',
      );
    }
  }

  /// Handle notification for modifying a recurring instance
  Future<void> onRecurringInstanceModified({
    required int masterEventId,
    required DateTime occurrenceDate,
  }) async {
    try {
      debugPrint(
        'SmartNotificationScheduler: Instance modified - rescheduling...',
      );

      // Reschedule to update notification with new date/time
      await rescheduleAllNotifications();
    } catch (e) {
      debugPrint(
        'SmartNotificationScheduler: Error handling modified instance - $e',
      );
    }
  }

  // ============================================================================
  // DIAGNOSTICS
  // ============================================================================

  /// Get count of scheduled notifications
  Future<int> getScheduledNotificationCount() async {
    try {
      return await notificationManager.getPendingNotificationsCount();
    } catch (e) {
      debugPrint(
        'SmartNotificationScheduler: Error getting notification count - $e',
      );
      return 0;
    }
  }

  /// Get diagnostic information
  Future<Map<String, dynamic>> getDiagnostics() async {
    final pendingCount = await getScheduledNotificationCount();

    return {
      'isInitialized': _isInitialized,
      'isAutoRefreshActive': _refreshTimer?.isActive ?? false,
      'lookAheadDays': lookAheadDays,
      'refreshIntervalHours': refreshInterval.inHours,
      'pendingNotifications': pendingCount,
    };
  }

  /// Print diagnostics to console
  Future<void> printDiagnostics() async {
    final diagnostics = await getDiagnostics();
    debugPrint('SmartNotificationScheduler Diagnostics:');
    debugPrint('  Initialized: ${diagnostics['isInitialized']}');
    debugPrint('  Auto-refresh active: ${diagnostics['isAutoRefreshActive']}');
    debugPrint('  Look-ahead days: ${diagnostics['lookAheadDays']}');
    debugPrint('  Refresh interval: ${diagnostics['refreshIntervalHours']}h');
    debugPrint(
      '  Pending notifications: ${diagnostics['pendingNotifications']}',
    );
  }
}
