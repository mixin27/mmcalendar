import 'package:calendar/calendar.dart';
import 'package:converter/converter.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:data/data.dart';
import 'package:settings/settings.dart';
import 'package:views/views.dart';

final getIt = GetIt.instance;

/// Initialize all app dependencies
Future<void> initializeDependencies() async {
  // Initialize database
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  // Initialize feature dependencies
  await initCalendarDependencies();
  await initSettingsDependencies();
  await initViewsDependencies();
  await initConverterDependencies();

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
