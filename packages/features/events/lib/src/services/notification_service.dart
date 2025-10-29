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
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
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

    // Android 13+ permission
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS permissions
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

    final notificationId = _generateNotificationId(
      event.id!,
      setting.minutesBefore,
    );
    final notificationTime = setting.getNotificationTime(event.eventDateTime);

    // Don't schedule past notifications
    if (notificationTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'events_channel',
      'Event Notifications',
      channelDescription: 'Notifications for calendar events',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      event.title,
      _buildNotificationBody(event, setting),
      _convertToTZDateTime(notificationTime),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'event_${event.id}',
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

  int _generateNotificationId(int eventId, int minutesBefore) {
    // Generate unique ID combining event ID and minutes before
    return (eventId * 10000) + minutesBefore;
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
    // Handle notification tap
    final payload = response.payload;
    if (payload != null && payload.startsWith('event_')) {
      final eventId = int.tryParse(payload.substring(6));
      if (eventId != null) {
        // Navigate to event details
        // This will be handled by the presentation layer
      }
    }
  }
}
