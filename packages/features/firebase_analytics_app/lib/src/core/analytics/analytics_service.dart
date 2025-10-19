import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';

import 'analytics_config.dart';
import 'analytics_event.dart';

/// Service for handling analytics events
class AnalyticsService {
  final FirebaseAnalytics _firebaseAnalytics;
  late AnalyticsConfig _config;
  final Logger _logger = Logger();

  AnalyticsService({
    required FirebaseAnalytics firebaseAnalytics,
    AnalyticsConfig? config,
  }) : _firebaseAnalytics = firebaseAnalytics {
    _config = config ?? const AnalyticsConfig();
  }

  /// Initialize analytics service
  Future<void> initialize({AnalyticsConfig? config}) async {
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
    if (!_config.enableCollection) {
      if (_config.enableDebugLogging) {
        _logger.i(
          '📊 [DISABLED] Event: ${event.name} with params: '
          '${event.parameters}',
        );
      }
      return;
    }

    try {
      final eventName = '${_config.eventPrefix}${event.name}';

      if (_config.enableDebugLogging) {
        _logger.i(
          '📊 Logging event: $eventName with params: ${event.parameters}',
        );
      }

      await _firebaseAnalytics.logEvent(
        name: eventName,
        parameters: event.parameters,
      );
    } catch (e) {
      _logger.e('Error logging event ${event.name}: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await logEvent(
      ScreenViewEvent(screenName: screenName, screenClass: screenClass),
    );
  }

  /// Log button click
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
  Future<void> logThemeChange({
    required String themeMode,
    String? themePreset,
  }) async {
    await logEvent(
      ThemeChangeEvent(themeMode: themeMode, themePreset: themePreset),
    );
  }

  /// Log language change
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
  Future<void> logFeatureToggle({
    required String featureName,
    required bool enabled,
  }) async {
    await logEvent(
      FeatureToggleEvent(featureName: featureName, enabled: enabled),
    );
  }

  /// Log share action
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

  /// Set user ID
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
  AnalyticsConfig get config => _config;

  /// Update configuration
  Future<void> updateConfig(AnalyticsConfig newConfig) async {
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
  Future<void> reset() async {
    try {
      _config = const AnalyticsConfig();
      _logger.i('Analytics reset');
    } catch (e) {
      _logger.e('Error resetting analytics: $e');
    }
  }
}
