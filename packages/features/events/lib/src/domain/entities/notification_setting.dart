import 'package:equatable/equatable.dart';

/// Notification setting for events
class NotificationSetting extends Equatable {
  final int minutesBefore;
  final NotificationChannel channel;

  const NotificationSetting({
    required this.minutesBefore,
    this.channel = NotificationChannel.local,
  });

  /// Get notification time for a specific event date
  DateTime getNotificationTime(DateTime eventDateTime) {
    return eventDateTime.subtract(Duration(minutes: minutesBefore));
  }

  /// Check if notification should be triggered
  bool shouldTrigger(DateTime eventDateTime, DateTime currentTime) {
    final notificationTime = getNotificationTime(eventDateTime);
    return currentTime.isAfter(notificationTime) &&
        currentTime.isBefore(eventDateTime);
  }

  /// Predefined notification settings
  static NotificationSetting get atEventTime =>
      const NotificationSetting(minutesBefore: 0);
  static NotificationSetting get fiveMinutesBefore =>
      const NotificationSetting(minutesBefore: 5);
  static NotificationSetting get fifteenMinutesBefore =>
      const NotificationSetting(minutesBefore: 15);
  static NotificationSetting get thirtyMinutesBefore =>
      const NotificationSetting(minutesBefore: 30);
  static NotificationSetting get oneHourBefore =>
      const NotificationSetting(minutesBefore: 60);
  static NotificationSetting get oneDayBefore =>
      const NotificationSetting(minutesBefore: 1440);

  static List<NotificationSetting> get defaultSettings => [
    fiveMinutesBefore,
    fifteenMinutesBefore,
    thirtyMinutesBefore,
    oneHourBefore,
    oneDayBefore,
  ];

  String get displayName {
    if (minutesBefore == 0) return 'At time of event';
    if (minutesBefore < 60) return '$minutesBefore minutes before';
    if (minutesBefore < 1440) {
      final hours = minutesBefore ~/ 60;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} before';
    }
    final days = minutesBefore ~/ 1440;
    return '$days ${days == 1 ? 'day' : 'days'} before';
  }

  NotificationSetting copyWith({
    int? minutesBefore,
    NotificationChannel? channel,
  }) {
    return NotificationSetting(
      minutesBefore: minutesBefore ?? this.minutesBefore,
      channel: channel ?? this.channel,
    );
  }

  @override
  List<Object?> get props => [minutesBefore, channel];
}

/// Notification channel enum
enum NotificationChannel {
  local,
  push,
  email;

  String get displayName {
    switch (this) {
      case NotificationChannel.local:
        return 'App Notification';
      case NotificationChannel.push:
        return 'Push Notification';
      case NotificationChannel.email:
        return 'Email';
    }
  }
}
