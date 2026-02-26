import 'package:calendar/calendar.dart';
import 'package:converter/converter.dart';
import 'package:events/events.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:home_widgets/home_widgets.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:integrations_firebase/integrations_firebase.dart';
import 'package:promo/promo.dart';
import 'package:settings/settings.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:views/views.dart';
import 'package:telegram_web/telegram_web.dart';
import 'package:holidays/holidays.dart';

final getIt = GetIt.instance;

/// Initialize all app dependencies
Future<void> initializeDependencies() async {
  // Initialize database
  final database = DatabaseModule.createDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Initialize Telegram Service (always registered, uses stub on non-web)
  final telegramService = TelegramServiceImpl();
  telegramService.initialize();
  getIt.registerSingleton<TelegramService>(telegramService);

  // Initialize Remote Config
  final remoteConfigService = await FirebaseRemoteConfigModule.initialize();
  getIt.registerSingleton<RemoteConfigPort>(remoteConfigService);

  // Initialize Holiday Service
  final holidayService = HolidayService(
    remoteConfigService: remoteConfigService,
  );
  getIt.registerSingleton<HolidayService>(holidayService);

  // Firebase Services (moved to separate setup function)
  await setupFirebaseServicesDependencies(getIt);
  debugPrint('✅ Firebase services registered:');

  // Initialize feature dependencies
  await initCalendarDependencies();
  await initSettingsDependencies();
  await initViewsDependencies();
  await initConverterDependencies();
  await initEventsDependencies();
  await initHomeWidgetsDependencies();
  await initializePromoDependencies();

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
