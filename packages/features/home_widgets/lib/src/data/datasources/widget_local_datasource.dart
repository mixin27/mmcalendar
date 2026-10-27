import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:home_widget/home_widget.dart';
import 'package:home_widgets/src/domain/entities/widget_data.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' show MoonPhaseState;
import 'package:workmanager/workmanager.dart';

import '../../domain/entities/widget_config.dart';
import '../../home_widget_configuration.dart';
import '../payload/widget_palettes.dart';
import '../payload/widget_payload_builder.dart';
import '../services/widget_update_service.dart';

/// Loads the next two weeks of events for the Agenda widget.
typedef WidgetEventsLoader =
    Future<List<WidgetAgendaEvent>> Function(DateTime start, DateTime end);

class WidgetLocalDataSource {
  static const String _configKey = 'widget_config';
  static const String _periodicTaskName = homeWidgetPeriodicTaskId;
  static const String _payloadEndKey = 'widget_payload_end_date';
  static const String _legacyClearedKey = 'widget_legacy_cleared_v2';

  final SharedPreferences sharedPreferences;

  /// Null in the background isolate, where the events database isn't open;
  /// the last written events are kept instead.
  final WidgetEventsLoader? loadEvents;

  WidgetLocalDataSource(this.sharedPreferences, {this.loadEvents});

  /// Builds and saves the widgets' data (see [WidgetPayloadBuilder]) and
  /// redraws every widget.
  Future<void> writePayload({WidgetConfig? config}) async {
    final effective = (config ?? await getWidgetConfig()).copyWith(
      language: resolveCalendarLanguageCode(),
    );
    final today = _dateOnly(DateTime.now());
    final events = await _events(today);
    final payload = WidgetPayloadBuilder.build(
      today: today,
      language: Language.fromCode(effective.language),
      events: events,
      styles: WidgetPalettes.all(app: _appPalette()),
      prefs: effective.toPayload(),
      preferShanYear: resolvePreferShanYear(),
      englishWesternDigits: resolveEnglishWesternDigits(),
    );
    await WidgetUpdateService.savePayload(payload);
    await sharedPreferences.setString(
      _payloadEndKey,
      today
          .add(const Duration(days: WidgetPayloadBuilder.horizonDays - 1))
          .toIso8601String(),
    );
    if (!(sharedPreferences.getBool(_legacyClearedKey) ?? false)) {
      await WidgetUpdateService.clearLegacyData();
      await sharedPreferences.setBool(_legacyClearedKey, true);
    }
    await WidgetUpdateService.reloadAll();
  }

  /// Days of data left before the widgets run out.
  int remainingPayloadDays() {
    final end = DateTime.tryParse(
      sharedPreferences.getString(_payloadEndKey) ?? '',
    );
    if (end == null) return 0;
    return _dateOnly(end).difference(_dateOnly(DateTime.now())).inDays;
  }

  /// Saves the app's light and dark look for the "Follow app" style, so a
  /// background refresh keeps it.
  Future<void> saveAppPalette(WidgetPalette light, WidgetPalette dark) =>
      sharedPreferences.setString(
        WidgetPalettes.appPaletteKey,
        json.encode({'light': light.toJson(), 'dark': dark.toJson()}),
      );

  ({WidgetPalette light, WidgetPalette dark})? _appPalette() {
    final raw = sharedPreferences.getString(WidgetPalettes.appPaletteKey);
    if (raw == null) return null;
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return (
        light: WidgetPalette.fromJson(map['light'] as Map<String, dynamic>),
        dark: WidgetPalette.fromJson(map['dark'] as Map<String, dynamic>),
      );
    } catch (_) {
      return null;
    }
  }

  static const _eventsCacheKey = 'widget_events_cache_v2';

  Future<List<WidgetAgendaEvent>> _events(DateTime today) async {
    final loader = loadEvents;
    if (loader == null) return _cachedEvents(today);
    try {
      final events = await loader(today, today.add(const Duration(days: 14)));
      await sharedPreferences.setString(
        _eventsCacheKey,
        json.encode([
          for (final e in events)
            {
              'id': e.id,
              'd': e.date.toIso8601String(),
              'ti': e.title,
              'c': e.color,
              't': e.time?.toIso8601String(),
              'done': e.done,
            },
        ]),
      );
      return events;
    } catch (e) {
      debugPrint('Widget events unavailable: $e');
      return _cachedEvents(today);
    }
  }

  List<WidgetAgendaEvent> _cachedEvents(DateTime today) {
    final raw = sharedPreferences.getString(_eventsCacheKey);
    if (raw == null) return const [];
    try {
      return [
        for (final e in json.decode(raw) as List)
          WidgetAgendaEvent(
            id: e['id'] as int?,
            date: DateTime.parse(e['d'] as String),
            title: e['ti'] as String,
            color: e['c'] as int,
            time: e['t'] == null ? null : DateTime.parse(e['t'] as String),
            done: e['done'] as bool? ?? false,
          ),
      ].where((e) => !e.date.isBefore(today)).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Generate widget data with specific language
  Future<WidgetData> generateWidgetDataWithLanguage(
    DateTime date,
    String languageCode,
  ) async {
    try {
      final targetLanguage = Language.fromCode(languageCode);

      // Get Myanmar calendar date info
      final myanmarDateTime = MyanmarCalendar.fromWestern(
        date.year,
        date.month,
        date.day,
      );

      // Format dates with correct language
      final myanmarDate = formatMyanmarDate(
        myanmarDateTime.myanmarDate,
        pattern: '&y &M &P &f &Yat',
        language: targetLanguage,
        preferShanYear: resolvePreferShanYear(),
      );
      final westernDate = myanmarDateTime.formatWestern(
        '%d %M %yyyy',
        targetLanguage,
      );

      // Get moon phase
      final moonPhase = _getMoonPhaseName(
        myanmarDateTime.moonPhase,
        targetLanguage,
      );
      final moon = MoonPhaseState.evening(date);

      // Get holidays
      final allHolidays = [
        ...myanmarDateTime.allHolidays,
        ...myanmarDateTime.allAnniversaryDays,
      ];
      final holidays = allHolidays
          .map((h) => TranslationService.translateTo(h, targetLanguage))
          .toList();

      final astrologicalDays = myanmarDateTime.astrologicalDays
          .map((a) => TranslationService.translateTo(a, targetLanguage))
          .toList();

      // Get astrology info
      String? sabbathInfo;
      String? yatyazaInfo;
      String? pyathadaInfo;

      if (myanmarDateTime.isSabbath || myanmarDateTime.isSabbathEve) {
        sabbathInfo = TranslationService.translateTo(
          myanmarDateTime.sabbath,
          targetLanguage,
        );
      }

      if (myanmarDateTime.isYatyaza) {
        yatyazaInfo = TranslationService.translateTo(
          myanmarDateTime.yatyaza,
          targetLanguage,
        );
      }

      if (myanmarDateTime.hasPyathada) {
        pyathadaInfo = TranslationService.translateTo(
          myanmarDateTime.pyathada,
          targetLanguage,
        );
      }

      final weekdayNames = _getWeekdayNames(targetLanguage);
      final moonPhaseNames = _getMoonPhaseNames(targetLanguage);

      final nextMoonPhase = _findNextMoonPhase(myanmarDateTime, targetLanguage);
      final fortnightDayText = myanmarDateTime.formatMyanmar(
        "&ff",
        targetLanguage,
      );

      return WidgetData(
        myanmarDate: myanmarDate,
        westernDate: westernDate,
        moonPhase: moonPhase,
        moonPhaseValue: myanmarDateTime.moonPhase,
        moonIllumination: moon.illumination,
        moonIsWaxing: moon.isWaxing,
        fortnightDay: myanmarDateTime.fortnightDay,
        fortnightDayText: fortnightDayText,
        holidays: holidays,
        astrologicalDays: astrologicalDays,
        sabbathInfo: sabbathInfo,
        yatyazaInfo: yatyazaInfo,
        pyathadaInfo: pyathadaInfo,
        lastUpdated: DateTime.now(),
        weekdayNames: weekdayNames,
        moonPhaseNames: moonPhaseNames,
        nextMoonPhase: nextMoonPhase,
        completeDate: myanmarDateTime.completeDate,
      );
    } catch (e, stackTrace) {
      debugPrint('Error generating widget data with language: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get widget configuration
  Future<WidgetConfig> getWidgetConfig() async {
    final language = resolveCalendarLanguageCode();
    final configJson = sharedPreferences.getString(_configKey);
    if (configJson == null) {
      debugPrint('No saved config found, using defaults');
      return const WidgetConfig.defaults().copyWith(language: language);
    }

    try {
      final config = json.decode(configJson) as Map<String, dynamic>;
      return WidgetConfig.fromJson(config).copyWith(language: language);
    } catch (e) {
      debugPrint('Error loading config, using defaults: $e');
      return const WidgetConfig.defaults().copyWith(language: language);
    }
  }

  /// Save widget configuration
  Future<void> saveWidgetConfig(WidgetConfig config) async {
    final normalizedConfig = config.copyWith(
      language: resolveCalendarLanguageCode(),
    );
    final configJson = json.encode(normalizedConfig.toJson());
    await sharedPreferences.setString(_configKey, configJson);
    debugPrint('Widget config saved');
  }

  /// Schedule periodic best-effort background refreshes. Daily date rollover is
  /// primarily handled natively by Android receivers + timeline cache.
  Future<void> scheduleUpdates() async {
    try {
      debugPrint('Scheduling initial widget update...');

      // Cancel any existing tasks
      await cancelUpdates();

      // Calculate initial delay to reach 12:01 AM
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 1);
      final initialDelay = tomorrow.difference(now);

      debugPrint('Initial update will run at: $tomorrow');
      debugPrint('Initial delay: ${initialDelay.inMinutes} minutes');
      await schedulePeriodicTask(initialDelay);

      debugPrint('Initial widget update scheduled successfully');
    } catch (e, stackTrace) {
      debugPrint('Failed to schedule initial update: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Schedule a 24h periodic fallback background refresh task.
  Future<void> schedulePeriodicTask([Duration? initialDelay]) async {
    try {
      debugPrint('Scheduling periodic 24h widget updates...');

      await Workmanager().registerPeriodicTask(
        _periodicTaskName,
        _periodicTaskName,
        frequency: const Duration(hours: 24),
        initialDelay: initialDelay,
        flexInterval: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
      debugPrint('Periodic widget updates scheduled successfully');
    } catch (e) {
      debugPrint('Failed to schedule periodic updates: $e');
    }
  }

  /// Cancel scheduled updates
  Future<void> cancelUpdates() async {
    try {
      await Workmanager().cancelByUniqueName(_periodicTaskName);
      debugPrint('Widget updates cancelled');
    } catch (e) {
      debugPrint('Error cancelling updates: $e');
    }
  }

  DateTime _dateOnly(DateTime input) =>
      DateTime(input.year, input.month, input.day);

  /// Check if widget is active on home screen
  Future<bool> isWidgetActive() async {
    try {
      final widgetIds = await HomeWidget.getInstalledWidgets();

      final isActive = widgetIds.isNotEmpty;
      debugPrint('Widget active: $isActive (${widgetIds.length} instances)');
      return isActive;
    } catch (e) {
      debugPrint('Error checking widget status: $e');
      return false;
    }
  }

  /// Check if automatic updates are scheduled
  Future<bool> isUpdateScheduled() async {
    try {
      // WorkManager doesn't provide a direct way to check if a task is scheduled
      // We'll store this info in SharedPreferences
      return sharedPreferences.getBool('widget_updates_scheduled') ?? false;
    } catch (e) {
      debugPrint('Error checking update schedule: $e');
      return false;
    }
  }

  /// Mark updates as scheduled
  Future<void> markUpdatesScheduled(bool scheduled) async {
    await sharedPreferences.setBool('widget_updates_scheduled', scheduled);
  }

  /// Settings › Prefer Shan Year, mirrored here by the settings feature so
  /// background refreshes can read it.
  bool resolvePreferShanYear() =>
      sharedPreferences.getBool(StorageKeys.showShanCalendar) ?? true;

  /// Settings › English numbers for Western dates, mirrored like
  /// [resolvePreferShanYear].
  bool resolveEnglishWesternDigits() =>
      sharedPreferences.getBool(StorageKeys.englishWesternDigits) ?? false;

  /// Widget language always follows app calendar language.
  String resolveCalendarLanguageCode() {
    final language = sharedPreferences.getString(StorageKeys.calendarLanguage);
    if (language != null && language.isNotEmpty) {
      return language;
    }

    final configuredLanguage = MyanmarCalendar.currentLanguage.code;
    if (configuredLanguage.isNotEmpty) {
      return configuredLanguage;
    }

    return Language.myanmar.code;
  }

  // Helper methods
  String _getMoonPhaseName(int moonPhase, Language language) {
    return TranslationService.getMoonPhaseName(moonPhase, language);
  }

  List<String> _getWeekdayNames(Language language) {
    List<String> items = List.empty(growable: true);
    for (var i = 0; i < 7; i++) {
      final myanmarWeekdayIndex = (1 + i) % 7;
      final weekdayName = TranslationService.getShortWeekdayName(
        myanmarWeekdayIndex,
        language,
      );
      items.add(weekdayName);
    }

    return items;
  }

  List<String> _getMoonPhaseNames(Language language) {
    List<String> items = List.empty(growable: true);
    for (var i = 0; i < 4; i++) {
      final name = _getMoonPhaseName(i, language);
      items.add(name);
    }
    return items;
  }

  String _findNextMoonPhase(MyanmarDateTime date, Language language) {
    final nextFullMoonPhaseDate = MyanmarCalendar.findNextMoonPhase(date, 1);

    final nextNewMoonPhaseDate = MyanmarCalendar.findNextMoonPhase(date, 3);

    // Calculate days from start
    var daysFromStart = 0;
    var moonPhaseName = TranslationService.translateTo("Full Moon", language);
    if (date.moonPhase == 0) {
      daysFromStart = MyanmarCalendar.daysBetween(date, nextFullMoonPhaseDate);
    } else if (date.moonPhase == 2) {
      daysFromStart = MyanmarCalendar.daysBetween(date, nextNewMoonPhaseDate);
      moonPhaseName = TranslationService.translateTo('New Moon', language);
    }

    return "$moonPhaseName in ${daysFromStart}d";
  }
}
