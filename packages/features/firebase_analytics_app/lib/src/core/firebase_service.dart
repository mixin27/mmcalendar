import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'analytics/analytics_config.dart';
import 'crashlytics/crashlytics_config.dart';

/// Main Firebase service initialization
class FirebaseService {
  static final Logger _logger = Logger();
  static FirebaseApp? _app;
  static late AnalyticsConfig _analyticsConfig;
  static late CrashlyticsConfig _crashlyticsConfig;

  /// Initialize Firebase with all required services
  static Future<void> initialize({
    required FirebaseOptions firebaseOptions,
    AnalyticsConfig analyticsConfig = const AnalyticsConfig(),
    CrashlyticsConfig crashlyticsConfig = const CrashlyticsConfig(),
    bool enableDebugLogging = !kReleaseMode,
  }) async {
    try {
      _logger.i('🔧 Initializing Firebase...');

      _logger.i('🔧 Initializing Firebase...');

      // Store configs for later use
      _analyticsConfig = analyticsConfig;
      _crashlyticsConfig = crashlyticsConfig;

      // Initialize Firebase App
      _app = await Firebase.initializeApp(options: firebaseOptions);

      // Configure Crashlytics with config
      await _configureCrashlytics(enableDebugLogging);

      // Configure Analytics with config
      await _configureAnalytics(enableDebugLogging);

      _logger.i('✅ Firebase initialized successfully');
    } catch (e, stack) {
      _logger.e('❌ Firebase initialization failed: $e', stackTrace: stack);
      rethrow;
    }
  }

  /// Configure Crashlytics service
  static Future<void> _configureCrashlytics(bool enableDebugLogging) async {
    try {
      final crashlytics = FirebaseCrashlytics.instance;

      // Use the config
      await crashlytics.setCrashlyticsCollectionEnabled(
        _crashlyticsConfig.enableCollection && kReleaseMode,
      );

      // Set user ID from config if provided
      if (_crashlyticsConfig.userId != null) {
        await crashlytics.setUserIdentifier(_crashlyticsConfig.userId!);
      }

      // Set initial custom keys from config
      for (final entry in _crashlyticsConfig.customKeys.entries) {
        crashlytics.setCustomKey(entry.key, entry.value);
      }

      // Handle Flutter errors
      FlutterError.onError = (FlutterErrorDetails details) {
        if (kReleaseMode) {
          crashlytics.recordFlutterFatalError(details);
        } else {
          FlutterError.presentError(details);
        }
      };

      if (enableDebugLogging) {
        _logger.i(
          '✅ Crashlytics configured: '
          'enabled=${_crashlyticsConfig.enableCollection}',
        );
      }
    } catch (e) {
      _logger.e('Error configuring Crashlytics: $e');
    }
  }

  /// Configure Analytics service
  static Future<void> _configureAnalytics(bool enableDebugLogging) async {
    try {
      final analytics = FirebaseAnalytics.instance;

      // IMPORTANT: Use the config
      await analytics.setAnalyticsCollectionEnabled(
        _analyticsConfig.enableCollection && kReleaseMode,
      );

      // Set user ID from config if provided
      if (_analyticsConfig.userId != null) {
        await analytics.setUserId(id: _analyticsConfig.userId);
      }

      // Set user properties from config
      for (final entry in _analyticsConfig.userProperties.entries) {
        await analytics.setUserProperty(name: entry.key, value: entry.value);
      }

      if (enableDebugLogging) {
        _logger.i(
          '✅ Analytics configured: '
          'enabled=${_analyticsConfig.enableCollection}, '
          'prefix=${_analyticsConfig.eventPrefix}',
        );
      }
    } catch (e) {
      _logger.e('Error configuring Analytics: $e');
    }
  }

  // Getter to access analytics configs
  static AnalyticsConfig get analyticsConfig => _analyticsConfig;

  /// Getter to access crashlytics configs
  static CrashlyticsConfig get crashlyticsConfig => _crashlyticsConfig;

  /// Get Firebase App instance
  static FirebaseApp? get app => _app;

  /// Get Firebase Analytics instance
  static FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  /// Get Firebase Crashlytics instance
  static FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;
}
