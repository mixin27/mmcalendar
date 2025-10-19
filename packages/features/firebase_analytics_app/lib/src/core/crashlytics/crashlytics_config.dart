import 'package:equatable/equatable.dart';

/// Configuration for Crashlytics Service
class CrashlyticsConfig extends Equatable {
  /// Enable crashlytics collection
  final bool enableCollection;

  /// Enable debug logging
  final bool enableDebugLogging;

  /// User ID to associate with crashes
  final String? userId;

  /// Custom keys to track
  final Map<String, dynamic> customKeys;

  /// Whether to capture platform exceptions
  final bool capturePlatformExceptions;

  const CrashlyticsConfig({
    this.enableCollection = true,
    this.enableDebugLogging = false,
    this.userId,
    this.customKeys = const {},
    this.capturePlatformExceptions = true,
  });

  CrashlyticsConfig copyWith({
    bool? enableCollection,
    bool? enableDebugLogging,
    String? userId,
    Map<String, dynamic>? customKeys,
    bool? capturePlatformExceptions,
  }) {
    return CrashlyticsConfig(
      enableCollection: enableCollection ?? this.enableCollection,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      userId: userId ?? this.userId,
      customKeys: customKeys ?? this.customKeys,
      capturePlatformExceptions:
          capturePlatformExceptions ?? this.capturePlatformExceptions,
    );
  }

  @override
  List<Object?> get props => [
    enableCollection,
    enableDebugLogging,
    userId,
    customKeys,
    capturePlatformExceptions,
  ];
}
