import 'dart:async';

import 'package:calendar/calendar.dart';
import 'package:converter/converter.dart';
import 'package:events/events.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:home_widgets/home_widgets.dart';
import 'package:holidays/holidays.dart';
import 'package:integrations_app_update/integrations_app_update.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:integrations_firebase/integrations_firebase.dart';
import 'package:promo/promo.dart';
import 'package:settings/settings.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telegram_web/telegram_web.dart';
import 'package:views/views.dart';

final getIt = GetIt.instance;

/// Initialize all app dependencies
Future<void> initializeDependencies({bool firebaseInitialized = true}) async {
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

  // Initialize Remote Config (non-blocking fetch to speed up startup)
  final remoteConfigService = _initializeRemoteConfig(
    firebaseInitialized: firebaseInitialized,
  );
  getIt.registerSingleton<RemoteConfigPort>(remoteConfigService);
  getIt.registerSingleton<AppUpdatePort>(
    RemoteConfigAppUpdatePort(
      remoteConfigPort: remoteConfigService,
      playStoreId: 'dev.mixin27.mmcalendar',
    ),
  );
  getIt.registerSingleton<HolidayConfigPort>(
    HolidayConfigService(remoteConfigPort: remoteConfigService),
  );

  // Initialize Holiday Service
  final holidayService = HolidayService(
    holidayConfigPort: getIt<HolidayConfigPort>(),
  );
  getIt.registerSingleton<HolidayService>(holidayService);
  getIt.registerSingleton<HolidayOverridesPort>(holidayService);

  // Firebase analytics/crashlytics registration with graceful fallback.
  if (firebaseInitialized) {
    try {
      await setupFirebaseServicesDependencies(getIt);
      debugPrint('✅ Firebase services registered');
    } catch (error, stackTrace) {
      debugPrint(
        '⚠️ Firebase service registration failed, using no-op ports: '
        '$error\n$stackTrace',
      );
      _registerNoopTelemetryPorts();
    }
  } else {
    _registerNoopTelemetryPorts();
  }

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

RemoteConfigPort _initializeRemoteConfig({required bool firebaseInitialized}) {
  if (!firebaseInitialized) {
    debugPrint('⚠️ Firebase unavailable, using fallback Remote Config');
    return const _FallbackRemoteConfigPort();
  }

  try {
    final remoteConfigService = RemoteConfigService();
    unawaited(remoteConfigService.initialize());
    return remoteConfigService;
  } catch (error, stackTrace) {
    debugPrint(
      '⚠️ Remote Config initialization failed, using fallback values: '
      '$error\n$stackTrace',
    );
    return const _FallbackRemoteConfigPort();
  }
}

void _registerNoopTelemetryPorts() {
  if (!getIt.isRegistered<AnalyticsPort>()) {
    getIt.registerSingleton<AnalyticsPort>(_NoopAnalyticsPort());
  }
  if (!getIt.isRegistered<CrashlyticsPort>()) {
    getIt.registerSingleton<CrashlyticsPort>(_NoopCrashlyticsPort());
  }
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

class _NoopAnalyticsPort implements AnalyticsPort {
  AnalyticsPortConfig _config = const AnalyticsPortConfig(
    enableCollection: false,
  );

  @override
  AnalyticsPortConfig get config => _config;

  @override
  Future<void> initialize({AnalyticsPortConfig? config}) async {
    if (config != null) {
      _config = config;
    }
  }

  @override
  Future<void> logAppStarted({
    required String backgroundHealth,
    required int backgroundSuccessCount,
    required int backgroundErrorCount,
    String? lastUpdate,
  }) async {}

  @override
  Future<void> logBackgroundErrors({
    required int errorCount,
    required String lastError,
    required String lastErrorTime,
  }) async {}

  @override
  Future<void> logBackgroundMetrics({
    required int successCount,
    required String lastUpdate,
    required int lastDurationMs,
    required String healthStatus,
  }) async {}

  @override
  Future<void> logButtonClick({
    required String buttonName,
    String? buttonLocation,
    Map<String, Object>? additionalData,
  }) async {}

  @override
  Future<void> logCustomEvent({
    required String name,
    Map<String, Object> parameters = const <String, Object>{},
  }) async {}

  @override
  Future<void> logDateSelection({
    required String selectedDate,
    required String calendarType,
    String? dateFormat,
  }) async {}

  @override
  Future<void> logException({
    required String exceptionName,
    required String description,
    String? stackTrace,
  }) async {}

  @override
  Future<void> logFeatureToggle({
    required String featureName,
    required bool enabled,
  }) async {}

  @override
  Future<void> logLanguageChange({
    required String languageCode,
    required String languageName,
  }) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {}

  @override
  Future<void> logSettingsChange({
    required String settingName,
    required Object oldValue,
    required Object newValue,
  }) async {}

  @override
  Future<void> logShare({
    required String contentType,
    required String platform,
    Map<String, Object>? metadata,
  }) async {}

  @override
  Future<void> logThemeChange({
    required String themeMode,
    String? themePreset,
  }) async {}

  @override
  Future<void> logWidgetInteraction({
    required String widgetName,
    required String actionType,
    Map<String, Object>? metadata,
  }) async {}

  @override
  Future<void> reset() async {
    _config = const AnalyticsPortConfig(enableCollection: false);
  }

  @override
  Future<void> setUserId(String userId) async {
    _config = _config.copyWith(userId: userId);
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    final userProperties = Map<String, String>.from(_config.userProperties);
    userProperties[name] = value;
    _config = _config.copyWith(userProperties: userProperties);
  }

  @override
  Future<void> updateConfig(AnalyticsPortConfig newConfig) async {
    _config = newConfig;
  }
}

class _NoopCrashlyticsPort implements CrashlyticsPort {
  CrashlyticsPortConfig _config = const CrashlyticsPortConfig(
    enableCollection: false,
  );

  @override
  CrashlyticsPortConfig get config => _config;

  @override
  bool get isEnabled => _config.enableCollection;

  @override
  Future<void> initialize({CrashlyticsPortConfig? config}) async {
    if (config != null) {
      _config = config;
    }
  }

  @override
  Future<void> log(String message, {String? level}) async {}

  @override
  Future<void> recordError({
    required String errorName,
    required String description,
    required StackTrace stackTrace,
    Map<String, Object>? context,
  }) async {}

  @override
  Future<void> recordException({
    required Object exception,
    required StackTrace stackTrace,
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}

  @override
  Future<void> setUserId(String userId) async {
    _config = _config.copyWith(userId: userId);
  }

  @override
  Future<void> updateConfig(CrashlyticsPortConfig newConfig) async {
    _config = newConfig;
  }
}

class _FallbackRemoteConfigPort implements RemoteConfigPort {
  const _FallbackRemoteConfigPort();

  @override
  Future<void> initialize() async {}

  @override
  Future<RemoteFetchResult> fetchAndActivate() async =>
      RemoteFetchResult.failed;

  @override
  bool getBool(String key) => false;

  @override
  double getDouble(String key) => 0;

  @override
  Map<String, Object> getAll() => const <String, Object>{};

  @override
  int getInt(String key) => 0;

  @override
  String getString(String key) => '';
}
