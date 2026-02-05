import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/entities/event.dart';
import '../domain/entities/notification_setting.dart';

/// Abstract notification service
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> scheduleNotification(Event event, NotificationSetting setting);
  Future<void> cancelNotification(int notificationId);
  Future<void> cancelAllNotifications();
  Future<List<PendingNotificationRequest>> getPendingNotifications();
}

/// Implementation of notification service using flutter_local_notifications
class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  @override
  Future<void> scheduleNotification(
    Event event,
    NotificationSetting setting,
  ) async {
    if (!_isInitialized) await initialize();
    if (event.id == null) return;

    // Generate unique ID using occurrence date
    // This ensures each occurrence of a recurring event has a unique notification
    final notificationId = _generateNotificationId(
      event.id!,
      event.eventDate, // Uses the specific occurrence date
      setting.minutesBefore,
    );

    final notificationTime = setting.getNotificationTime(event.eventDateTime);

    // Don't schedule past notifications
    if (notificationTime.isBefore(DateTime.now())) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'events_channel',
      'Event Notifications',
      channelDescription: 'Notifications for calendar events',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      event.title,
      _buildNotificationBody(event, setting),
      _convertToTZDateTime(notificationTime),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'event_${event.id}_${event.eventDate.millisecondsSinceEpoch}',
    );
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
    if (!_isInitialized) await initialize();
    await _notificationsPlugin.cancel(notificationId);
  }

  @override
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();
    await _notificationsPlugin.cancelAll();
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) await initialize();
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// ✅ UPDATED: Generate unique notification ID for recurring events
  /// Format: eventId * 10000000 + daysSinceEpoch * 10000 + minutesBefore
  ///
  /// This ensures:
  /// - Each event has unique IDs
  /// - Each occurrence date has unique IDs
  /// - Each notification time has unique IDs
  int _generateNotificationId(
    int eventId,
    DateTime occurrenceDate,
    int minutesBefore,
  ) {
    // Calculate days since epoch for this occurrence
    final epoch = DateTime(1970, 1, 1);
    final daysSinceEpoch = occurrenceDate.difference(epoch).inDays;

    // Generate unique ID
    // Example: eventId=1, date=2024-01-15, minutes=15
    // Result: 1 * 10000000 + 19737 * 10000 + 15 = 10197370015
    return (eventId * 10000000) + (daysSinceEpoch * 10000) + minutesBefore;
  }

  String _buildNotificationBody(Event event, NotificationSetting setting) {
    final buffer = StringBuffer();

    if (setting.minutesBefore == 0) {
      buffer.write('Event is happening now');
    } else if (setting.minutesBefore < 60) {
      buffer.write('Event starts in ${setting.minutesBefore} minutes');
    } else if (setting.minutesBefore < 1440) {
      final hours = setting.minutesBefore ~/ 60;
      buffer.write('Event starts in $hours hour${hours > 1 ? 's' : ''}');
    } else {
      final days = setting.minutesBefore ~/ 1440;
      buffer.write('Event starts in $days day${days > 1 ? 's' : ''}');
    }

    if (event.location != null && event.location!.isNotEmpty) {
      buffer.write(' • ${event.location}');
    }

    return buffer.toString();
  }

  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    final location = tz.local;
    return tz.TZDateTime.from(dateTime, location);
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.startsWith('event_')) {
      // Parse: event_123_1704067200000
      final parts = payload.split('_');
      if (parts.length >= 3) {
        final eventId = int.tryParse(parts[1]);
        final timestamp = int.tryParse(parts[2]);

        if (eventId != null && timestamp != null) {
          final occurrenceDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
          debugPrint(
            "[NotificationService]: _onNotificationTapped() => ${occurrenceDate.toIso8601String()}",
          );
          // todo(mixin27): Navigate to event details
          // You can use a global navigator key or event bus here
        }
      }
    }
  }
}
