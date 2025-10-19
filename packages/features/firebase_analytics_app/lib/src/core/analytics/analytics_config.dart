import 'package:equatable/equatable.dart';

/// Configuration for Analytics Service
class AnalyticsConfig extends Equatable {
  /// Enable analytics collection
  final bool enableCollection;

  /// Enable analytics debugging (shows events in Logcat)
  final bool enableDebugLogging;

  /// User ID to associate with events (optional)
  final String? userId;

  /// User properties to track
  final Map<String, String> userProperties;

  /// Custom event name prefixes for organization
  final String eventPrefix;

  const AnalyticsConfig({
    this.enableCollection = true,
    this.enableDebugLogging = false,
    this.userId,
    this.userProperties = const {},
    this.eventPrefix = 'app_',
  });

  AnalyticsConfig copyWith({
    bool? enableCollection,
    bool? enableDebugLogging,
    String? userId,
    Map<String, String>? userProperties,
    String? eventPrefix,
  }) {
    return AnalyticsConfig(
      enableCollection: enableCollection ?? this.enableCollection,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      userId: userId ?? this.userId,
      userProperties: userProperties ?? this.userProperties,
      eventPrefix: eventPrefix ?? this.eventPrefix,
    );
  }

  @override
  List<Object?> get props => [
    enableCollection,
    enableDebugLogging,
    userId,
    userProperties,
    eventPrefix,
  ];
}
