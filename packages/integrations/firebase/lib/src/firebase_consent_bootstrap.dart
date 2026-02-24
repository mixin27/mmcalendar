import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:integrations_database/integrations_database.dart';

import 'package:firebase_analytics_app/firebase_analytics_app.dart';

/// Consent values used to configure Firebase collection behavior.
final class FirebaseConsentSettings {
  const FirebaseConsentSettings({
    required this.enableAnalytics,
    required this.enableCrashlytics,
  });

  final bool enableAnalytics;
  final bool enableCrashlytics;
}

/// Handles Firebase setup with persisted consent.
final class FirebaseConsentBootstrap {
  const FirebaseConsentBootstrap();

  static const String _analyticsConsentKey = 'enable_analytics';
  static const String _crashlyticsConsentKey = 'enable_crashlytics';

  Future<FirebaseConsentSettings> loadConsent({
    AppDatabase? database,
  }) async {
    final appDatabase = database ?? DatabaseModule.createDatabase();
    final settingsDao = appDatabase.settingsDao;

    final analyticsConsent =
        await settingsDao.getSetting(_analyticsConsentKey) ?? 'true';
    final crashlyticsConsent =
        await settingsDao.getSetting(_crashlyticsConsentKey) ?? 'true';

    return FirebaseConsentSettings(
      enableAnalytics: analyticsConsent.toLowerCase() == 'true',
      enableCrashlytics: crashlyticsConsent.toLowerCase() == 'true',
    );
  }

  Future<void> initialize({
    required FirebaseOptions options,
    AppDatabase? database,
    bool enableDebugLogging = !kReleaseMode,
    String analyticsEventPrefix = 'app_',
  }) async {
    final consent = await loadConsent(database: database);

    await FirebaseService.initialize(
      firebaseOptions: options,
      analyticsConfig: AnalyticsConfig(
        enableCollection: consent.enableAnalytics,
        enableDebugLogging: enableDebugLogging,
        eventPrefix: analyticsEventPrefix,
      ),
      crashlyticsConfig: CrashlyticsConfig(
        enableCollection: consent.enableCrashlytics,
        enableDebugLogging: enableDebugLogging,
      ),
      enableDebugLogging: enableDebugLogging,
    );
  }

  /// Registers global Flutter/Platform error forwarding to Crashlytics.
  void registerCrashHandlers() {
    final crashlytics = FirebaseService.crashlytics;

    FlutterError.onError = (FlutterErrorDetails details) {
      if (kReleaseMode) {
        crashlytics.recordFlutterFatalError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (kReleaseMode) {
        crashlytics.recordError(error, stack, fatal: true);
      } else {
        debugPrint('Platform error: $error\n$stack');
      }

      return true;
    };
  }
}
