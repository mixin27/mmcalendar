import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_core/shared_core.dart';

import '../core/analytics/analytics_service.dart';
import '../core/crashlytics/crashlytics_service.dart';
import '../core/firebase_service.dart';

/// Initialize Firebase services in service locator
Future<void> setupFirebaseServicesDependencies(GetIt getIt) async {
  // Verify Firebase was initialized
  if (FirebaseService.app == null) {
    throw Exception(
      'FirebaseService.initialize() must be called before setupFirebaseServicesDependencies()',
    );
  }

  // Register Firebase instances
  getIt.registerSingleton<FirebaseApp>(FirebaseService.app!);

  getIt.registerSingleton<FirebaseAnalytics>(FirebaseAnalytics.instance);

  getIt.registerSingleton<FirebaseCrashlytics>(FirebaseCrashlytics.instance);

  // Register Analytics Service + SDK-agnostic port
  final analyticsService = AnalyticsService(
    firebaseAnalytics: getIt<FirebaseAnalytics>(),
    config: FirebaseService.analyticsConfig,
  );
  getIt.registerSingleton<AnalyticsService>(analyticsService);
  getIt.registerSingleton<AnalyticsPort>(analyticsService);

  // Register Crashlytics Service + SDK-agnostic port
  final crashlyticsService = CrashlyticsService(
    crashlytics: getIt<FirebaseCrashlytics>(),
    config: FirebaseService.crashlyticsConfig,
  );
  getIt.registerSingleton<CrashlyticsService>(crashlyticsService);
  getIt.registerSingleton<CrashlyticsPort>(crashlyticsService);
}
