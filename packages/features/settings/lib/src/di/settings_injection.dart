import 'package:integrations_database/integrations_database.dart';
import 'package:get_it/get_it.dart';
import 'package:home_widgets/home_widgets.dart';
import 'package:shared_core/shared_core.dart';

import '../data/datasources/settings_local_datasource.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/services/database_display_preferences_port.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/usecases/get_settings.dart';
import '../domain/usecases/mark_as_consent_dialog_shown.dart';
import '../domain/usecases/reset_settings.dart';
import '../domain/usecases/update_calendar_config.dart';
import '../domain/usecases/update_display_preferences.dart';
import '../domain/usecases/update_language.dart';
import '../domain/usecases/update_theme.dart';
import '../presentation/bloc/settings_bloc.dart';

final getIt = GetIt.instance;

/// Register all settings feature dependencies
Future<void> initSettingsDependencies() async {
  // Data sources
  getIt.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(getIt<AppDatabase>()),
  );

  // Repositories
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      getIt<SettingsLocalDataSource>(),
      getIt<AppDatabase>(),
    ),
  );

  if (!getIt.isRegistered<DisplayPreferencesPort>()) {
    final port = DatabaseDisplayPreferencesPort(getIt<AppDatabase>());
    getIt.registerSingleton<DisplayPreferencesPort>(port);

    if (!getIt.isRegistered<CalendarDisplayConfigPort>()) {
      getIt.registerSingleton<CalendarDisplayConfigPort>(port);
    }
  } else if (!getIt.isRegistered<CalendarDisplayConfigPort>()) {
    final existing = getIt<DisplayPreferencesPort>();
    if (existing is CalendarDisplayConfigPort) {
      getIt.registerSingleton<CalendarDisplayConfigPort>(
        existing as CalendarDisplayConfigPort,
      );
    } else {
      getIt.registerSingleton<CalendarDisplayConfigPort>(
        DatabaseDisplayPreferencesPort(getIt<AppDatabase>()),
      );
    }
  }

  // Use cases
  getIt.registerLazySingleton(() => GetSettings(getIt<SettingsRepository>()));
  getIt.registerLazySingleton(() => UpdateTheme(getIt<SettingsRepository>()));
  getIt.registerLazySingleton(
    () => UpdateLanguage(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateCalendarConfig(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateDisplayPreferences(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton(() => ResetSettings(getIt<SettingsRepository>()));
  getIt.registerLazySingleton(
    () => MarkAsConsentDialogShown(getIt<SettingsRepository>()),
  );

  // BLoC
  getIt.registerFactory(
    () => SettingsBloc(
      getSettings: getIt<GetSettings>(),
      updateTheme: getIt<UpdateTheme>(),
      updateLanguage: getIt<UpdateLanguage>(),
      updateCalendarConfig: getIt<UpdateCalendarConfig>(),
      updateDisplayPreferences: getIt<UpdateDisplayPreferences>(),
      resetSettings: getIt<ResetSettings>(),
      markAsConsentDialogShown: getIt<MarkAsConsentDialogShown>(),
      widgetRepository: getIt<WidgetRepository>(),
      analyticsService: getIt<AnalyticsPort>(),
      crashlyticsService: getIt<CrashlyticsPort>(),
      holidayOverridesPort: getIt<HolidayOverridesPort>(),
    ),
  );
}
