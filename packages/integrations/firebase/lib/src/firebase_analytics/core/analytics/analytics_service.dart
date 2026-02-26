import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';
import 'package:shared_core/shared_core.dart';

import 'analytics_event.dart';

/// Service for handling analytics events
class AnalyticsService implements AnalyticsPort {
  final FirebaseAnalytics _firebaseAnalytics;
  late AnalyticsPortConfig _config;
  final Logger _logger = Logger();

  AnalyticsService({
    required FirebaseAnalytics firebaseAnalytics,
    AnalyticsPortConfig? config,
  }) : _firebaseAnalytics = firebaseAnalytics {
    _config = config ?? const AnalyticsPortConfig();
  }

  /// Initialize analytics service
  @override
  Future<void> initialize({AnalyticsPortConfig? config}) async {
    try {
      if (config != null) {
        _config = config;
      }

      // Set user ID if provided in config
      if (_config.userId != null) {
        await setUserId(_config.userId!);
      }

      // Set user properties from config
      for (final entry in _config.userProperties.entries) {
        await setUserProperty(name: entry.key, value: entry.value);
      }

      _logger.i(
        '✅ Analytics Service initialized with config: '
        'enableCollection=${_config.enableCollection}, '
        'enableDebugLogging=${_config.enableDebugLogging}, '
        'eventPrefix=${_config.eventPrefix}',
      );
    } catch (e) {
      _logger.e('Error initializing Analytics Service: $e');
    }
  }

  /// Log an analytics event
  Future<void> logEvent(AnalyticsEvent event) async {
    await _logEvent(event.name, event.parameters);
  }

  @override
  Future<void> logCustomEvent({
    required String name,
    Map<String, Object> parameters = const <String, Object>{},
  }) async {
    await _logEvent(name, parameters);
  }

  Future<void> _logEvent(
    String eventName,
    Map<String, Object> parameters,
  ) async {
    if (!_config.enableCollection) {
      if (_config.enableDebugLogging) {
        _logger.i('📊 [DISABLED] Event: $eventName with params: $parameters');
      }
      return;
    }

    try {
      final prefixedEventName = '${_config.eventPrefix}$eventName';

      if (_config.enableDebugLogging) {
        _logger.i(
          '📊 Logging event: $prefixedEventName with params: $parameters',
        );
      }

      await _firebaseAnalytics.logEvent(
        name: prefixedEventName,
        parameters: parameters,
      );
    } catch (e) {
      _logger.e('Error logging event $eventName: $e');
    }
  }

  /// Log screen view
  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await logEvent(
      ScreenViewEvent(screenName: screenName, screenClass: screenClass),
    );
  }

  /// Log button click
  @override
  Future<void> logButtonClick({
    required String buttonName,
    String? buttonLocation,
    Map<String, Object>? additionalData,
  }) async {
    await logEvent(
      ButtonClickEvent(
        buttonName: buttonName,
        buttonLocation: buttonLocation,
        additionalData: additionalData,
      ),
    );
  }

  /// Log date selection
  @override
  Future<void> logDateSelection({
    required String selectedDate,
    required String calendarType,
    String? dateFormat,
  }) async {
    await logEvent(
      DateSelectionEvent(
        selectedDate: selectedDate,
        calendarType: calendarType,
        dateFormat: dateFormat,
      ),
    );
  }

  /// Log settings change
  @override
  Future<void> logSettingsChange({
    required String settingName,
    required Object oldValue,
    required Object newValue,
  }) async {
    await logEvent(
      SettingsChangeEvent(
        settingName: settingName,
        oldValue: oldValue,
        newValue: newValue,
      ),
    );
  }

  /// Log theme change
  @override
  Future<void> logThemeChange({
    required String themeMode,
    String? themePreset,
  }) async {
    await logEvent(
      ThemeChangeEvent(themeMode: themeMode, themePreset: themePreset),
    );
  }

  /// Log language change
  @override
  Future<void> logLanguageChange({
    required String languageCode,
    required String languageName,
  }) async {
    await logEvent(
      LanguageChangeEvent(
        languageCode: languageCode,
        languageName: languageName,
      ),
    );
  }

  /// Log feature toggle
  @override
  Future<void> logFeatureToggle({
    required String featureName,
    required bool enabled,
  }) async {
    await logEvent(
      FeatureToggleEvent(featureName: featureName, enabled: enabled),
    );
  }

  /// Log share action
  @override
  Future<void> logShare({
    required String contentType,
    required String platform,
    Map<String, Object>? metadata,
  }) async {
    await logEvent(
      ShareEvent(
        contentType: contentType,
        platform: platform,
        metadata: metadata,
      ),
    );
  }

  /// Log exception/error
  @override
  Future<void> logException({
    required String exceptionName,
    required String description,
    String? stackTrace,
  }) async {
    await logEvent(
      ExceptionEvent(
        exceptionName: exceptionName,
        description: description,
        stackTrace: stackTrace,
      ),
    );
  }

  /// Log widget interaction
  @override
  Future<void> logWidgetInteraction({
    required String widgetName,
    required String actionType,
    Map<String, Object>? metadata,
  }) async {
    await logEvent(
      WidgetInteractionEvent(
        widgetName: widgetName,
        actionType: actionType,
        metadata: metadata,
      ),
    );
  }

  /// Log background task metrics
  @override
  Future<void> logBackgroundMetrics({
    required int successCount,
    required String lastUpdate,
    required int lastDurationMs,
    required String healthStatus,
  }) async {
    await logEvent(
      BackgroundMetricsEvent(
        successCount: successCount,
        lastUpdate: lastUpdate,
        lastDurationMs: lastDurationMs,
        healthStatus: healthStatus,
      ),
    );
  }

  /// Log background error metrics
  @override
  Future<void> logBackgroundErrors({
    required int errorCount,
    required String lastError,
    required String lastErrorTime,
  }) async {
    await logEvent(
      BackgroundErrorMetricsEvent(
        errorCount: errorCount,
        lastError: lastError,
        lastErrorTime: lastErrorTime,
      ),
    );
  }

  /// Log app started with background health
  @override
  Future<void> logAppStarted({
    required String backgroundHealth,
    required int backgroundSuccessCount,
    required int backgroundErrorCount,
    String? lastUpdate,
  }) async {
    await logEvent(
      AppStartedEvent(
        backgroundHealth: backgroundHealth,
        backgroundSuccessCount: backgroundSuccessCount,
        backgroundErrorCount: backgroundErrorCount,
        lastUpdate: lastUpdate,
      ),
    );
  }

  /// Set user ID
  @override
  Future<void> setUserId(String userId) async {
    if (!_config.enableCollection) {
      _logger.i('User ID not set (collection disabled)');
      return;
    }

    try {
      await _firebaseAnalytics.setUserId(id: userId);
      _config = _config.copyWith(userId: userId);
      _logger.i('User ID set: $userId');
    } catch (e) {
      _logger.e('Error setting user ID: $e');
    }
  }

  /// Set user property
  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!_config.enableCollection) {
      _logger.i('User property not set (collection disabled): $name');
      return;
    }

    try {
      await _firebaseAnalytics.setUserProperty(name: name, value: value);
      final props = Map<String, String>.from(_config.userProperties)
        ..[name] = value;
      _config = _config.copyWith(userProperties: props);
      _logger.i('User property set: $name = $value');
    } catch (e) {
      _logger.e('Error setting user property: $e');
    }
  }

  /// Get current configuration
  @override
  AnalyticsPortConfig get config => _config;

  /// Update configuration
  @override
  Future<void> updateConfig(AnalyticsPortConfig newConfig) async {
    _logger.i(
      '📋 Analytics config updated: '
      'enableCollection: ${_config.enableCollection} → '
      '${newConfig.enableCollection}',
    );

    _config = newConfig;

    // Apply to Firebase immediately
    try {
      await _firebaseAnalytics.setAnalyticsCollectionEnabled(
        newConfig.enableCollection,
      );

      // Update user ID if changed
      if (_config.userId != newConfig.userId && newConfig.userId != null) {
        await _firebaseAnalytics.setUserId(id: newConfig.userId);
      }

      _logger.i(
        '✅ Firebase Analytics collection: '
        '${newConfig.enableCollection}',
      );
    } catch (e) {
      _logger.e('Error updating config in Firebase: $e');
    }
  }

  /// Reset analytics
  @override
  Future<void> reset() async {
    try {
      _config = const AnalyticsPortConfig();
      _logger.i('Analytics reset');
    } catch (e) {
      _logger.e('Error resetting analytics: $e');
    }
  }
}
