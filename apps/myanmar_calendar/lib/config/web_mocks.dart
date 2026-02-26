import 'package:shared_core/shared_core.dart';
import 'package:flutter/foundation.dart';

/// Mock Analytics Service for Web
class MockAnalyticsService implements AnalyticsPort {
  @override
  AnalyticsPortConfig get config =>
      const AnalyticsPortConfig(enableCollection: false);

  @override
  Future<void> initialize({AnalyticsPortConfig? config}) async {}

  @override
  Future<void> logCustomEvent({
    required String name,
    Map<String, Object> parameters = const <String, Object>{},
  }) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {}

  @override
  Future<void> logButtonClick({
    required String buttonName,
    String? buttonLocation,
    Map<String, Object>? additionalData,
  }) async {}

  @override
  Future<void> logDateSelection({
    required String selectedDate,
    required String calendarType,
    String? dateFormat,
  }) async {}

  @override
  Future<void> logSettingsChange({
    required String settingName,
    required Object oldValue,
    required Object newValue,
  }) async {}

  @override
  Future<void> logThemeChange({
    required String themeMode,
    String? themePreset,
  }) async {}

  @override
  Future<void> logLanguageChange({
    required String languageCode,
    required String languageName,
  }) async {}

  @override
  Future<void> logFeatureToggle({
    required String featureName,
    required bool enabled,
  }) async {}

  @override
  Future<void> logShare({
    required String contentType,
    required String platform,
    Map<String, Object>? metadata,
  }) async {}

  @override
  Future<void> logException({
    required String exceptionName,
    required String description,
    String? stackTrace,
  }) async {}

  @override
  Future<void> logWidgetInteraction({
    required String widgetName,
    required String actionType,
    Map<String, Object>? metadata,
  }) async {}

  @override
  Future<void> logBackgroundMetrics({
    required int successCount,
    required String lastUpdate,
    required int lastDurationMs,
    required String healthStatus,
  }) async {}

  @override
  Future<void> logBackgroundErrors({
    required int errorCount,
    required String lastError,
    required String lastErrorTime,
  }) async {}

  @override
  Future<void> logAppStarted({
    required String backgroundHealth,
    required int backgroundSuccessCount,
    required int backgroundErrorCount,
    String? lastUpdate,
  }) async {}

  @override
  Future<void> setUserId(String userId) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {}

  @override
  Future<void> updateConfig(AnalyticsPortConfig newConfig) async {}

  @override
  Future<void> reset() async {}
}

/// Mock Crashlytics Service for Web
class MockCrashlyticsService implements CrashlyticsPort {
  @override
  CrashlyticsPortConfig get config =>
      const CrashlyticsPortConfig(enableCollection: false);

  @override
  bool get isEnabled => false;

  @override
  Future<void> initialize({CrashlyticsPortConfig? config}) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}

  @override
  Future<void> recordException({
    required Object exception,
    required StackTrace stackTrace,
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  Future<void> recordError({
    required String errorName,
    required String description,
    required StackTrace stackTrace,
    Map<String, Object>? context,
  }) async {}

  @override
  Future<void> log(String message, {String? level}) async {}

  @override
  Future<void> setUserId(String userId) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}

  @override
  Future<void> updateConfig(CrashlyticsPortConfig newConfig) async {}
}
