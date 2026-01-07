import 'package:calendar/calendar.dart';
import 'package:converter/converter.dart';
import 'package:events/events.dart';
import 'package:firebase_analytics_app/firebase_analytics_app.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:data/data.dart';
import 'package:home_widgets/home_widgets.dart';
import 'package:settings/settings.dart';
import 'package:views/views.dart';

import '../telegram/telegram_service.dart';
import 'web_mocks.dart';

final getIt = GetIt.instance;

/// Initialize all app dependencies
Future<void> initializeDependencies() async {
  // Initialize database
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  // Initialize Telegram Service (always registered, uses stub on non-web)
  final telegramService = TelegramServiceImpl();
  telegramService.initialize();
  getIt.registerSingleton<TelegramService>(telegramService);

  // Firebase Services (moved to separate setup function)
  if (!kIsWeb) {
    await setupFirebaseServicesDependencies(getIt);

    final analyticsService = getIt<AnalyticsService>();
    final crashlyticsService = getIt<CrashlyticsService>();
    debugPrint('✅ Firebase services registered:');
    debugPrint(
      '  Analytics enabled: ${analyticsService.config.enableCollection}',
    );
    debugPrint(
      '  Crashlytics enabled: ${crashlyticsService.config.enableCollection}',
    );
  } else {
    debugPrint('⚠️ Registering mock Firebase services on Web');
    getIt.registerSingleton<AnalyticsService>(MockAnalyticsService());
    getIt.registerSingleton<CrashlyticsService>(MockCrashlyticsService());
  }

  // Initialize feature dependencies
  await initCalendarDependencies();
  await initSettingsDependencies();
  await initViewsDependencies();
  await initConverterDependencies();
  await initEventsDependencies();
  await initHomeWidgetsDependencies();

  // Initialize notification scheduler
  final scheduler = getIt<SmartNotificationScheduler>();
  await scheduler.initialize();

  debugPrint('✅ All dependencies initialized');
}

/// Reset dependencies (for testing or restart)
Future<void> resetDependencies() async {
  // Close database
  if (getIt.isRegistered<AppDatabase>()) {
    await getIt<AppDatabase>().close();
  }

  // Reset GetIt
  await getIt.reset();
}
