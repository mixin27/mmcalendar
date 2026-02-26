/// SDK-agnostic analytics configuration used by feature and app layers.
class AnalyticsPortConfig {
  const AnalyticsPortConfig({
    this.enableCollection = true,
    this.enableDebugLogging = false,
    this.userId,
    this.userProperties = const <String, String>{},
    this.eventPrefix = 'app_',
  });

  final bool enableCollection;
  final bool enableDebugLogging;
  final String? userId;
  final Map<String, String> userProperties;
  final String eventPrefix;

  AnalyticsPortConfig copyWith({
    bool? enableCollection,
    bool? enableDebugLogging,
    String? userId,
    Map<String, String>? userProperties,
    String? eventPrefix,
  }) {
    return AnalyticsPortConfig(
      enableCollection: enableCollection ?? this.enableCollection,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      userId: userId ?? this.userId,
      userProperties: userProperties ?? this.userProperties,
      eventPrefix: eventPrefix ?? this.eventPrefix,
    );
  }
}

/// SDK-agnostic analytics contract used across feature packages.
abstract interface class AnalyticsPort {
  AnalyticsPortConfig get config;

  Future<void> initialize({AnalyticsPortConfig? config});

  Future<void> logCustomEvent({
    required String name,
    Map<String, Object> parameters,
  });

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  });

  Future<void> logButtonClick({
    required String buttonName,
    String? buttonLocation,
    Map<String, Object>? additionalData,
  });

  Future<void> logDateSelection({
    required String selectedDate,
    required String calendarType,
    String? dateFormat,
  });

  Future<void> logSettingsChange({
    required String settingName,
    required Object oldValue,
    required Object newValue,
  });

  Future<void> logThemeChange({
    required String themeMode,
    String? themePreset,
  });

  Future<void> logLanguageChange({
    required String languageCode,
    required String languageName,
  });

  Future<void> logFeatureToggle({
    required String featureName,
    required bool enabled,
  });

  Future<void> logShare({
    required String contentType,
    required String platform,
    Map<String, Object>? metadata,
  });

  Future<void> logException({
    required String exceptionName,
    required String description,
    String? stackTrace,
  });

  Future<void> logWidgetInteraction({
    required String widgetName,
    required String actionType,
    Map<String, Object>? metadata,
  });

  Future<void> logBackgroundMetrics({
    required int successCount,
    required String lastUpdate,
    required int lastDurationMs,
    required String healthStatus,
  });

  Future<void> logBackgroundErrors({
    required int errorCount,
    required String lastError,
    required String lastErrorTime,
  });

  Future<void> logAppStarted({
    required String backgroundHealth,
    required int backgroundSuccessCount,
    required int backgroundErrorCount,
    String? lastUpdate,
  });

  Future<void> setUserId(String userId);

  Future<void> setUserProperty({
    required String name,
    required String value,
  });

  Future<void> updateConfig(AnalyticsPortConfig newConfig);

  Future<void> reset();
}
