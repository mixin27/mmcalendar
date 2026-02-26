import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_core/shared_core.dart';

import 'crashlytics_config.dart';

/// Service for handling crash reporting and error logging
class CrashlyticsService implements CrashlyticsPort {
  final FirebaseCrashlytics _crashlytics;
  late CrashlyticsConfig _config;
  final Logger _logger = Logger();

  CrashlyticsService({
    required FirebaseCrashlytics crashlytics,
    CrashlyticsConfig? config,
  }) : _crashlytics = crashlytics {
    _config = config ?? const CrashlyticsConfig();
  }

  /// Initialize crashlytics service
  @override
  Future<void> initialize({CrashlyticsConfig? config}) async {
    try {
      if (config != null) {
        _config = config;
      }

      // Use config to control behavior
      await _crashlytics.setCrashlyticsCollectionEnabled(
        _config.enableCollection && kReleaseMode,
      );

      // Set user ID from config
      if (_config.userId != null) {
        await setUserId(_config.userId!);
      }

      // Set custom keys from config
      for (final entry in _config.customKeys.entries) {
        _crashlytics.setCustomKey(entry.key, entry.value);
      }

      _logger.i(
        '✅ Crashlytics Service initialized with config: '
        'enableCollection=${_config.enableCollection}',
      );
    } catch (e) {
      _logger.e('Error initializing Crashlytics Service: $e');
    }
  }

  /// Record a flutter error
  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (!_config.enableCollection) {
      _logger.i('Crashlytics collection disabled, skipping error');
      return;
    }

    try {
      if (_config.enableDebugLogging) {
        _logger.e('🔴 Recording Flutter error: ${details.exceptionAsString()}');
      }

      await _crashlytics.recordFlutterFatalError(details);
    } catch (e) {
      _logger.e('Error recording flutter error: $e');
    }
  }

  /// Record an exception
  @override
  Future<void> recordException({
    required Object exception,
    required StackTrace stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    if (!_config.enableCollection) {
      if (_config.enableDebugLogging) {
        _logger.e('🔴 [DISABLED] Exception: $exception');
      }
      return;
    }

    try {
      if (_config.enableDebugLogging) {
        _logger.e(
          '🔴 Recording ${fatal ? 'fatal ' : ''}exception: '
          '$exception\n$stackTrace',
        );
      }

      if (reason != null) {
        await _crashlytics.log(reason);
      }

      await _crashlytics.recordError(exception, stackTrace, fatal: fatal);
    } catch (e) {
      _logger.e('Error recording exception: $e');
    }
  }

  /// Record an error with context
  @override
  Future<void> recordError({
    required String errorName,
    required String description,
    required StackTrace stackTrace,
    Map<String, Object>? context,
  }) async {
    if (!_config.enableCollection) return;

    try {
      // Log error context
      if (context != null) {
        await _crashlytics.log('Error Context: $context');
      }

      await _crashlytics.log('Error: $errorName - $description');
      await _crashlytics.recordError(
        Exception(description),
        stackTrace,
        fatal: false,
      );

      if (_config.enableDebugLogging) {
        _logger.e('Error recorded: $errorName - $description');
      }
    } catch (e) {
      _logger.e('Error recording error: $e');
    }
  }

  /// Record a message
  @override
  Future<void> log(String message, {String? level}) async {
    if (!_config.enableCollection) return;

    try {
      final logMessage = level != null ? '[$level] $message' : message;
      await _crashlytics.log(logMessage);

      if (_config.enableDebugLogging) {
        _logger.i('📝 Crashlytics log: $logMessage');
      }
    } catch (e) {
      _logger.e('Error logging to Crashlytics: $e');
    }
  }

  /// Set user ID
  @override
  Future<void> setUserId(String userId) async {
    if (!_config.enableCollection) return;

    try {
      await _crashlytics.setUserIdentifier(userId);
      _config = _config.copyWith(userId: userId);

      if (_config.enableDebugLogging) {
        _logger.i('User ID set in Crashlytics: $userId');
      }
    } catch (e) {
      _logger.e('Error setting user ID: $e');
    }
  }

  /// Set custom key
  @override
  Future<void> setCustomKey(String key, Object value) async {
    if (!_config.enableCollection) return;

    try {
      _crashlytics.setCustomKey(key, value);
      final keys = Map<String, Object>.from(_config.customKeys)..[key] = value;
      _config = _config.copyWith(customKeys: keys);

      if (_config.enableDebugLogging) {
        _logger.i('Custom key set: $key = $value');
      }
    } catch (e) {
      _logger.e('Error setting custom key: $e');
    }
  }

  /// Get current configuration
  @override
  CrashlyticsConfig get config => _config;

  /// Update configuration
  @override
  Future<void> updateConfig(CrashlyticsConfig newConfig) async {
    _logger.i(
      '📋 Crashlytics config updated: '
      'enableCollection: ${_config.enableCollection} → '
      '${newConfig.enableCollection}',
    );

    _config = newConfig;

    // Apply to Firebase immediately
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(
        newConfig.enableCollection && kReleaseMode,
      );

      _logger.i(
        '✅ Firebase Crashlytics collection: '
        '${newConfig.enableCollection}',
      );
    } catch (e) {
      _logger.e('Error updating config in Firebase: $e');
    }
  }

  /// Check if crashlytics is enabled
  @override
  bool get isEnabled => _config.enableCollection && kReleaseMode;
}
