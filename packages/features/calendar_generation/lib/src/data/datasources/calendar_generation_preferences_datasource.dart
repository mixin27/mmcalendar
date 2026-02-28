import 'dart:convert';

import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/calendar_generation_mode.dart';
import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_image_quality.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import '../../domain/entities/calendar_paper_size.dart';
import '../../domain/entities/calendar_preview_theme.dart';

class CalendarGenerationPreferencesDataSource {
  CalendarGenerationPreferencesDataSource(this._preferences);

  final SharedPreferences _preferences;

  Future<void> saveRequest(CalendarGenerationRequest request) async {
    final payload = <String, dynamic>{
      'mode': request.mode.name,
      'year': request.year,
      'month': request.month,
      'showHolidays': request.showHolidays,
      'showAstrology': request.showAstrology,
      'showWesternDates': request.showWesternDates,
      'showMyanmarDates': request.showMyanmarDates,
      'firstDayOfWeek': request.firstDayOfWeek,
      'paperSize': request.paperSize.name,
      'pageOrientation': request.pageOrientation.name,
      'imageQuality': request.imageQuality.name,
      'theme': <String, dynamic>{
        'backgroundColorValue': request.theme.backgroundColorValue,
        'foregroundColorValue': request.theme.foregroundColorValue,
        'accentColorValue': request.theme.accentColorValue,
        'backgroundImageUrl': request.theme.backgroundImageUrl,
        'backgroundImageUrlsByMonth': request.theme.backgroundImageUrlsByMonth
            .map((key, value) => MapEntry('$key', value)),
      },
    };

    await _preferences.setString(
      StorageKeys.calendarGenerationSettings,
      jsonEncode(payload),
    );
  }

  CalendarGenerationRequest restoreRequest(CalendarGenerationRequest fallback) {
    final raw = _preferences.getString(StorageKeys.calendarGenerationSettings);
    if (raw == null || raw.isEmpty) {
      return fallback;
    }

    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) {
        return fallback;
      }

      final mode = _parseMode(map['mode']) ?? fallback.mode;
      final year = _parseInt(map['year']) ?? fallback.year;
      final month = _parseInt(map['month']) ?? fallback.month;
      final paperSize = _parsePaperSize(map['paperSize']) ?? fallback.paperSize;
      final orientation =
          _parseOrientation(map['pageOrientation']) ?? fallback.pageOrientation;
      final quality =
          _parseImageQuality(map['imageQuality']) ?? fallback.imageQuality;
      final theme = _parseTheme(map['theme'], fallback.theme);

      return fallback.copyWith(
        mode: mode,
        year: year,
        month: month,
        showHolidays: _parseBool(map['showHolidays']) ?? fallback.showHolidays,
        showAstrology:
            _parseBool(map['showAstrology']) ?? fallback.showAstrology,
        showWesternDates:
            _parseBool(map['showWesternDates']) ?? fallback.showWesternDates,
        showMyanmarDates:
            _parseBool(map['showMyanmarDates']) ?? fallback.showMyanmarDates,
        firstDayOfWeek:
            _parseInt(map['firstDayOfWeek']) ?? fallback.firstDayOfWeek,
        paperSize: paperSize,
        pageOrientation: orientation,
        imageQuality: quality,
        theme: theme,
      );
    } catch (_) {
      return fallback;
    }
  }

  CalendarPreviewTheme _parseTheme(
    Object? rawTheme,
    CalendarPreviewTheme fallback,
  ) {
    if (rawTheme is! Map<String, dynamic>) {
      return fallback;
    }

    final monthlyImages = <int, String>{};
    final rawMonthly = rawTheme['backgroundImageUrlsByMonth'];
    if (rawMonthly is Map<String, dynamic>) {
      for (final entry in rawMonthly.entries) {
        final month = int.tryParse(entry.key);
        final value = entry.value?.toString();
        if (month != null &&
            month >= 1 &&
            month <= 12 &&
            value != null &&
            value.trim().isNotEmpty) {
          monthlyImages[month] = value.trim();
        }
      }
    }

    return fallback.copyWith(
      backgroundColorValue:
          _parseInt(rawTheme['backgroundColorValue']) ??
          fallback.backgroundColorValue,
      foregroundColorValue:
          _parseInt(rawTheme['foregroundColorValue']) ??
          fallback.foregroundColorValue,
      accentColorValue:
          _parseInt(rawTheme['accentColorValue']) ?? fallback.accentColorValue,
      backgroundImageUrl:
          rawTheme['backgroundImageUrl']?.toString() ??
          fallback.backgroundImageUrl,
      backgroundImageUrlsByMonth: monthlyImages,
    );
  }

  CalendarGenerationMode? _parseMode(Object? raw) {
    final name = raw?.toString();
    return _firstWhereOrNull<CalendarGenerationMode>(
      CalendarGenerationMode.values,
      (value) => value.name == name,
    );
  }

  CalendarPaperSize? _parsePaperSize(Object? raw) {
    final name = raw?.toString();
    return _firstWhereOrNull<CalendarPaperSize>(
      CalendarPaperSize.values,
      (value) => value.name == name,
    );
  }

  CalendarPageOrientation? _parseOrientation(Object? raw) {
    final name = raw?.toString();
    return _firstWhereOrNull<CalendarPageOrientation>(
      CalendarPageOrientation.values,
      (value) => value.name == name,
    );
  }

  CalendarImageQuality? _parseImageQuality(Object? raw) {
    final name = raw?.toString();
    return _firstWhereOrNull<CalendarImageQuality>(
      CalendarImageQuality.values,
      (value) => value.name == name,
    );
  }

  int? _parseInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    return int.tryParse(raw?.toString() ?? '');
  }

  bool? _parseBool(Object? raw) {
    if (raw is bool) {
      return raw;
    }

    final value = raw?.toString().toLowerCase();
    if (value == 'true') {
      return true;
    }
    if (value == 'false') {
      return false;
    }
    return null;
  }

  T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T) test) {
    for (final value in values) {
      if (test(value)) {
        return value;
      }
    }
    return null;
  }
}
