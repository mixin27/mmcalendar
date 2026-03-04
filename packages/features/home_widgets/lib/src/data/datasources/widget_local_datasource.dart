import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:home_widget/home_widget.dart';
import 'package:home_widgets/src/domain/entities/widget_data.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../domain/entities/widget_config.dart';
import '../services/myanmar_month_widget_service.dart';
import '../services/widget_update_service.dart';

class WidgetLocalDataSource {
  static const String _configKey = 'widget_config';
  static const String _periodicTaskName = 'widget_periodic_task';
  static const String _timelineGeneratedAtKey = 'widget_timeline_generated_at';
  static const String _timelineLanguageKey = 'widget_timeline_language';
  static const String _timelineEndDateKey = 'widget_timeline_end_date';
  static const int _timelineHorizonDays = 180;
  static const int _timelineMinimumRemainingDays = 30;

  final SharedPreferences sharedPreferences;

  WidgetLocalDataSource(this.sharedPreferences);

  /// Update widget with custom configuration
  Future<void> updateWidgetWithConfig(
    WidgetData data,
    WidgetConfig config,
  ) async {
    final effectiveConfig = config.copyWith(
      language: resolveCalendarLanguageCode(),
    );
    await WidgetUpdateService.updateAllWidgets(data, effectiveConfig);
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
      final myanmarDate = myanmarDateTime.formatMyanmar(
        '&y &M &P &f &Yat',
        targetLanguage,
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
      final moonPhaseEmoji = _getMoonPhaseEmoji(myanmarDateTime.moonPhase);

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
        moonPhaseEmoji: moonPhaseEmoji,
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

  /// Build a timeline cache used by native widget providers to serve daily
  /// data changes even when Dart background tasks do not run.
  Future<void> warmupTimeline(WidgetConfig config, {bool force = false}) async {
    final effectiveConfig = config.copyWith(
      language: resolveCalendarLanguageCode(),
    );
    final shouldRegenerate =
        force || _shouldRegenerateTimeline(effectiveConfig);
    if (!shouldRegenerate) {
      debugPrint('Widget timeline is still fresh');
      return;
    }

    final today = _dateOnly(DateTime.now());
    final entries = <String, Map<String, Object?>>{};
    final monthKeyByDate = <String, String>{};
    final monthEntries = <String, Map<String, dynamic>>{};
    final largeMoonImageCache = <String, String?>{};
    final smallMoonImageCache = <String, String?>{};

    debugPrint('Generating widget timeline for $_timelineHorizonDays days...');

    for (var i = 0; i < _timelineHorizonDays; i++) {
      final date = today.add(Duration(days: i));
      final data = await generateWidgetDataWithLanguage(
        date,
        effectiveConfig.language,
      );
      final dateKey = _dateKey(date);
      final moonKey = '${data.moonPhaseValue}_${data.fortnightDay}';
      final monthKey = MyanmarMonthWidgetService.monthPayloadKeyForDate(date);

      monthKeyByDate[dateKey] = monthKey;
      if (!monthEntries.containsKey(monthKey)) {
        final monthSnapshot =
            await MyanmarMonthWidgetService.generateMonthTimelineSnapshot(
              date,
              effectiveConfig.language,
            );
        monthEntries[monthSnapshot.monthKey] = monthSnapshot.monthPayload;
      }

      if (!largeMoonImageCache.containsKey(moonKey)) {
        largeMoonImageCache[moonKey] =
            await WidgetUpdateService.renderMoonPhaseImage(
              data.moonPhaseValue,
              data.fortnightDay,
              storageKey: 'moon_phase_large_$moonKey',
            );
      }
      if (!smallMoonImageCache.containsKey(moonKey)) {
        smallMoonImageCache[moonKey] =
            await WidgetUpdateService.renderMoonPhaseImage(
              data.moonPhaseValue,
              data.fortnightDay,
              size: 90,
              storageKey: 'moon_phase_small_$moonKey',
            );
      }

      entries[dateKey] = {
        'myanmar_date': data.myanmarDate,
        'western_date': data.westernDate,
        'moon_phase': data.moonPhase,
        'moon_phase_value': data.moonPhaseValue,
        'moon_phase_emoji': data.moonPhaseEmoji,
        'fortnight_day': data.fortnightDay.toString(),
        'fortnight_day_text': data.fortnightDayText,
        'holidays': data.holidays.join(', '),
        'sabbath_info': data.sabbathInfo ?? '',
        'yatyaza_info': data.yatyazaInfo ?? '',
        'pyathada_info': data.pyathadaInfo ?? '',
        'astrological_days': data.astrologicalDays.join(', '),
        'next_moon_phase': data.nextMoonPhase,
        'moon_phase_image_path': smallMoonImageCache[moonKey] ?? '',
        'full_moon_phase_image_path': largeMoonImageCache[moonKey] ?? '',
      };
    }

    final timelinePayload = json.encode({
      'version': 1,
      'language': effectiveConfig.language,
      'generated_at': DateTime.now().toIso8601String(),
      'entries': entries,
    });

    await WidgetUpdateService.saveTimelinePayload(timelinePayload);

    final monthTimelinePayload = json.encode({
      'version': 1,
      'language': effectiveConfig.language,
      'generated_at': DateTime.now().toIso8601String(),
      'date_to_month_key': monthKeyByDate,
      'month_entries': monthEntries,
    });
    await WidgetUpdateService.saveMonthTimelinePayload(monthTimelinePayload);

    final todayKey = _dateKey(today);
    final todayMonthKey = monthKeyByDate[todayKey];
    if (todayMonthKey != null && monthEntries.containsKey(todayMonthKey)) {
      await HomeWidget.saveWidgetData<String>(
        'myanmar_month_data',
        MyanmarMonthWidgetService.monthDataToJson(monthEntries[todayMonthKey]!),
      );
    }

    final timelineEndDate = today.add(
      const Duration(days: _timelineHorizonDays - 1),
    );
    await sharedPreferences.setString(
      _timelineGeneratedAtKey,
      DateTime.now().toIso8601String(),
    );
    await sharedPreferences.setString(
      _timelineLanguageKey,
      effectiveConfig.language,
    );
    await sharedPreferences.setString(
      _timelineEndDateKey,
      timelineEndDate.toIso8601String(),
    );

    debugPrint('Widget timeline generated successfully');
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
        existingWorkPolicy: ExistingWorkPolicy.update,
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

  bool _shouldRegenerateTimeline(WidgetConfig config) {
    final generatedAtRaw = sharedPreferences.getString(_timelineGeneratedAtKey);
    final languageRaw = sharedPreferences.getString(_timelineLanguageKey);
    final endDateRaw = sharedPreferences.getString(_timelineEndDateKey);

    if (generatedAtRaw == null || languageRaw == null || endDateRaw == null) {
      return true;
    }

    if (languageRaw != config.language) {
      return true;
    }

    final endDate = DateTime.tryParse(endDateRaw);
    if (endDate == null) {
      return true;
    }

    final remainingDays = _dateOnly(
      endDate,
    ).difference(_dateOnly(DateTime.now())).inDays;
    if (remainingDays < _timelineMinimumRemainingDays) {
      return true;
    }

    final generatedAt = DateTime.tryParse(generatedAtRaw);
    if (generatedAt == null) {
      return true;
    }

    return DateTime.now().difference(generatedAt) > const Duration(days: 14);
  }

  DateTime _dateOnly(DateTime input) =>
      DateTime(input.year, input.month, input.day);

  String _dateKey(DateTime date) {
    final d = _dateOnly(date);
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

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

  String _getMoonPhaseEmoji(int moonPhase) {
    switch (moonPhase) {
      case 0:
        return '🌒'; // Waxing crescent
      case 1:
        return '🌕'; // Full moon
      case 2:
        return '🌘'; // Waning crescent
      case 3:
        return '🌑'; // New moon
      default:
        return '🌙';
    }
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
