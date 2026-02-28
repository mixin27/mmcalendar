import 'package:flutter/foundation.dart';

/// SDK-agnostic crash reporting configuration for feature/app layers.
class CrashlyticsPortConfig {
  const CrashlyticsPortConfig({
    this.enableCollection = true,
    this.enableDebugLogging = false,
    this.userId,
    this.customKeys = const <String, Object>{},
    this.capturePlatformExceptions = true,
  });

  final bool enableCollection;
  final bool enableDebugLogging;
  final String? userId;
  final Map<String, Object> customKeys;
  final bool capturePlatformExceptions;

  CrashlyticsPortConfig copyWith({
    bool? enableCollection,
    bool? enableDebugLogging,
    String? userId,
    Map<String, Object>? customKeys,
    bool? capturePlatformExceptions,
  }) {
    return CrashlyticsPortConfig(
      enableCollection: enableCollection ?? this.enableCollection,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      userId: userId ?? this.userId,
      customKeys: customKeys ?? this.customKeys,
      capturePlatformExceptions:
          capturePlatformExceptions ?? this.capturePlatformExceptions,
    );
  }
}

/// SDK-agnostic crash reporting contract used across feature packages.
abstract interface class CrashlyticsPort {
  CrashlyticsPortConfig get config;
  bool get isEnabled;

  Future<void> initialize({CrashlyticsPortConfig? config});

  Future<void> recordFlutterError(FlutterErrorDetails details);

  Future<void> recordException({
    required Object exception,
    required StackTrace stackTrace,
    String? reason,
    bool fatal = false,
  });

  Future<void> recordError({
    required String errorName,
    required String description,
    required StackTrace stackTrace,
    Map<String, Object>? context,
  });

  Future<void> log(String message, {String? level});

  Future<void> setUserId(String userId);

  Future<void> setCustomKey(String key, Object value);

  Future<void> updateConfig(CrashlyticsPortConfig newConfig);
}
