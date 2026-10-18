import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:home_widgets/home_widgets.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:settings/settings.dart';
import 'package:settings/src/domain/usecases/mark_as_consent_dialog_shown.dart';
import 'package:settings/src/domain/usecases/update_app_icon.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

/// Records what the pages write instead of touching a database.
class RecordingSettingsRepository implements SettingsRepository {
  AppSettingsEntity settings = AppSettingsEntity(
    themeMode: ThemeMode.system,
    themePreset: 'modern',
    appLanguage: 'en',
    calendarLanguage: Language.myanmar,
    calendarConfig: const CalendarConfig(),
    showHolidays: true,
    showAnniversaryDays: true,
    showSabbaths: true,
    showAstrology: true,
    showWesternDates: true,
    showMyanmarDates: true,
    firstDayOfWeek: 1,
  );
  final preferences = <String, bool>{};
  int resets = 0;
  AppStyle? appStyle;
  ThemeMode? themeMode;
  String? preset;
  Language? calendarLanguage;

  static const _ok = Right<Failure, void>(null);

  @override
  Future<Either<Failure, AppSettingsEntity>> getSettings() async =>
      Right(settings);

  @override
  Future<Either<Failure, void>> updateDisplayPreference(
    String key,
    bool value,
  ) async {
    preferences[key] = value;
    return _ok;
  }

  CalendarGridStyle? gridStyle;
  CalendarGridTheme? gridTheme;

  @override
  Future<Either<Failure, void>> updateCalendarGridTheme(
    CalendarGridTheme theme,
  ) async {
    gridTheme = theme;
    return _ok;
  }

  @override
  Future<Either<Failure, void>> updateCalendarGridStyle(
    CalendarGridStyle style,
  ) async {
    gridStyle = style;
    return _ok;
  }

  @override
  Future<Either<Failure, void>> resetSettings() async {
    resets++;
    return _ok;
  }

  @override
  Future<Either<Failure, void>> updateAppStyle(AppStyle style) async {
    appStyle = style;
    return _ok;
  }

  @override
  Future<Either<Failure, void>> updateThemeMode(ThemeMode mode) async {
    themeMode = mode;
    return _ok;
  }

  @override
  Future<Either<Failure, void>> updateThemePreset(String presetId) async {
    preset = presetId;
    return _ok;
  }

  @override
  Future<Either<Failure, void>> updateCalendarLanguage(
    Language language,
  ) async {
    calendarLanguage = language;
    return _ok;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(_ok);
}

class _Analytics implements AnalyticsPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _Crashlytics implements CrashlyticsPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _NoOverrides implements HolidayOverridesPort {
  @override
  List<CustomHoliday> getCustomHolidayRules() => const [];
  @override
  List<HolidayId> getDisabledHolidays() => const [];
  @override
  Map<int, List<HolidayId>> getDisabledHolidaysByYear() => const {};
  @override
  Map<String, List<HolidayId>> getDisabledHolidaysByDate() => const {};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Widgets implements WidgetRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future.value(const Right(null));
}

class _Icons implements AppIconPort {
  @override
  List<AppIconOption> get availableIcons => const [];
  @override
  Future<String> getCurrentIcon() async => 'default';
  @override
  Future<bool> isSupported() async => false;
  @override
  Future<bool> setIcon(String iconId) async => false;
}

class _RemoteConfig implements RemoteConfigPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Updates implements AppUpdatePort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SettingsHarness {
  SettingsHarness._(this.repository, this.bloc);
  final RecordingSettingsRepository repository;
  final SettingsBloc bloc;

  static Future<SettingsHarness> pump(
    WidgetTester tester, {
    required AppStyle style,
    required Widget page,
    Brightness brightness = Brightness.light,
  }) async {
    final getIt = GetIt.instance;
    await getIt.reset();
    final analytics = _Analytics();
    getIt
      ..registerSingleton<AnalyticsPort>(analytics)
      ..registerSingleton<AppIconPort>(_Icons())
      ..registerSingleton<RemoteConfigPort>(_RemoteConfig())
      ..registerSingleton<AppUpdatePort>(_Updates());

    final repository = RecordingSettingsRepository();
    final bloc = SettingsBloc(
      getSettings: GetSettings(repository),
      updateTheme: UpdateTheme(repository),
      updateLanguage: UpdateLanguage(repository),
      updateCalendarConfig: UpdateCalendarConfig(repository),
      updateDisplayPreferences: UpdateDisplayPreferences(repository),
      updateAppIcon: UpdateAppIcon(repository),
      resetSettings: ResetSettings(repository),
      markAsConsentDialogShown: MarkAsConsentDialogShown(repository),
      widgetRepository: _Widgets(),
      analyticsService: analytics,
      crashlyticsService: _Crashlytics(),
      holidayOverridesPort: _NoOverrides(),
    )..add(const LoadSettings());
    addTearDown(bloc.close);

    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          style: style,
          colorScheme: brightness == Brightness.dark
              ? AppColorSchemes.modernDark
              : AppColorSchemes.modernLight,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(value: bloc, child: page),
      ),
    );
    await tester.pumpAndSettle();
    return SettingsHarness._(repository, bloc);
  }
}
