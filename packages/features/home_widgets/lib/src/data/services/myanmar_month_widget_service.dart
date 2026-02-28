import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:intl/intl.dart';

class MyanmarMonthWidgetService {
  /// Build month payload for timeline cache.
  static Future<MonthTimelineSnapshot> generateMonthTimelineSnapshot(
    DateTime date,
    String languageCode,
  ) async {
    final monthData = await _generateMyanmarMonthData(date, languageCode);
    return MonthTimelineSnapshot(
      monthKey: '${monthData.myanmarYear}-${monthData.myanmarMonth}',
      monthPayload: _toMap(monthData),
    );
  }

  static String monthDataToJson(Map<String, dynamic> payload) =>
      json.encode(payload);

  static String monthPayloadKeyForDate(DateTime date) {
    final myanmarDate = MyanmarCalendar.fromWestern(
      date.year,
      date.month,
      date.day,
    );
    return '${myanmarDate.myanmarYear}-${myanmarDate.myanmarMonth}';
  }

  /// Generate Myanmar month calendar data
  static Future<MyanmarMonthData> _generateMyanmarMonthData(
    DateTime date,
    String languageCode,
  ) async {
    final currentLanguage = MyanmarCalendar.currentLanguage;
    final targetLanguage = Language.fromCode(languageCode);

    try {
      if (currentLanguage != targetLanguage) {
        MyanmarCalendar.setLanguage(targetLanguage);
      }

      // Get Myanmar date for the given date
      final myanmarDate = MyanmarCalendar.fromWestern(
        date.year,
        date.month,
        date.day,
      );

      final myanmarYear = myanmarDate.myanmarYear;
      final myanmarMonth = myanmarDate.myanmarMonth;

      // Get all dates in this Myanmar month
      final myanmarDates = MyanmarCalendar.getMyanmarMonth(
        myanmarYear,
        myanmarMonth,
      );

      debugPrint('📅 Myanmar Month: $myanmarYear/$myanmarMonth');
      debugPrint('📅 Total days in month: ${myanmarDates.length}');

      // Get corresponding Western dates
      final westernDates = MyanmarCalendar.getWesternDatesForMyanmarMonth(
        myanmarYear,
        myanmarMonth,
      );

      if (myanmarDates.isEmpty || westernDates.isEmpty) {
        debugPrint(
          '⚠️ Empty Myanmar month payload for $myanmarYear/$myanmarMonth; '
          'falling back to western-month grid.',
        );
        return _generateFallbackMonthData(date, targetLanguage);
      }

      // Get first day's weekday to determine grid start
      final firstWesternDate = westernDates.first;
      final firstWeekday =
          firstWesternDate.weekday % 7; // 0=Sunday, 1=Monday, etc.

      debugPrint('📅 First weekday: $firstWeekday');

      // Build calendar grid (42 cells = 6 weeks × 7 days)
      final gridDays = <MyanmarDayData>[];

      // Add previous month days if needed
      if (firstWeekday > 0) {
        final prevMonthDays = _getPreviousMonthDays(
          myanmarYear,
          myanmarMonth,
          firstWeekday,
          languageCode,
        );
        gridDays.addAll(prevMonthDays);
      }

      // Add current month days
      for (var i = 0; i < myanmarDates.length; i++) {
        final mmDate = myanmarDates[i];
        final westernDate = westernDates[i];
        final isToday = _isToday(westernDate);
        final myanmarDateTime = MyanmarDateTime.fromMyanmarDate(mmDate);

        final year = targetLanguage == Language.shan
            ? myanmarDateTime.shanDate.year
            : mmDate.year;

        gridDays.add(
          MyanmarDayData(
            westernYear: westernDate.year,
            westernMonth: westernDate.month,
            westernDay: westernDate.day,
            myanmarYear: year,
            myanmarMonth: mmDate.month,
            myanmarMonthName: mmDate.format(pattern: '&M'),
            moonPhase: mmDate.moonPhase,
            fortnightDay: mmDate.fortnightDay,
            hasHoliday: myanmarDateTime.allHolidays.isNotEmpty,
            isToday: isToday,
            isCurrentMonth: true,
          ),
        );
      }

      // Add next month days to fill the grid to 42 cells
      final remainingCells = 42 - gridDays.length;
      if (remainingCells > 0) {
        final nextMonthDays = _getNextMonthDays(
          myanmarYear,
          myanmarMonth,
          remainingCells,
          languageCode,
        );
        gridDays.addAll(nextMonthDays);
      }

      debugPrint('📅 Total grid cells: ${gridDays.length}');

      // Get month names
      final myanmarMonthName = myanmarDate.formatMyanmar("&M");
      final westernMonthName = DateFormat('MMMM').format(firstWesternDate);

      return MyanmarMonthData(
        myanmarYear: myanmarYear,
        myanmarMonth: myanmarMonth,
        myanmarMonthName: myanmarMonthName,
        westernYear: firstWesternDate.year,
        westernMonth: firstWesternDate.month,
        westernMonthName: westernMonthName,
        days: gridDays,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating Myanmar month data: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      if (currentLanguage != targetLanguage) {
        MyanmarCalendar.setLanguage(currentLanguage);
      }
    }
  }

  /// Fallback for edge cases where getMyanmarMonth() yields empty results.
  /// Builds a stable 6x7 grid anchored to the western month containing [date].
  static MyanmarMonthData _generateFallbackMonthData(
    DateTime date,
    Language targetLanguage,
  ) {
    final firstOfMonth = DateTime(date.year, date.month, 1);
    final startOffset = firstOfMonth.weekday % 7; // Sunday-based grid
    final gridStart = firstOfMonth.subtract(Duration(days: startOffset));

    final anchorMyanmarDate = MyanmarCalendar.fromWestern(
      date.year,
      date.month,
      date.day,
    );
    final westernMonthName = DateFormat('MMMM').format(firstOfMonth);

    final days = List<MyanmarDayData>.generate(42, (index) {
      final westernDate = gridStart.add(Duration(days: index));
      final myanmarDateTime = MyanmarCalendar.fromWestern(
        westernDate.year,
        westernDate.month,
        westernDate.day,
      );
      final myanmarYear = targetLanguage == Language.shan
          ? myanmarDateTime.shanDate.year
          : myanmarDateTime.myanmarYear;

      return MyanmarDayData(
        westernYear: westernDate.year,
        westernMonth: westernDate.month,
        westernDay: westernDate.day,
        myanmarYear: myanmarYear,
        myanmarMonth: myanmarDateTime.myanmarMonth,
        myanmarMonthName: myanmarDateTime.formatMyanmar('&M'),
        moonPhase: myanmarDateTime.moonPhase,
        fortnightDay: myanmarDateTime.fortnightDay,
        hasHoliday: myanmarDateTime.allHolidays.isNotEmpty,
        isToday: _isToday(westernDate),
        isCurrentMonth:
            westernDate.year == date.year && westernDate.month == date.month,
      );
    });

    return MyanmarMonthData(
      myanmarYear: anchorMyanmarDate.myanmarYear,
      myanmarMonth: anchorMyanmarDate.myanmarMonth,
      myanmarMonthName: anchorMyanmarDate.formatMyanmar('&M'),
      westernYear: firstOfMonth.year,
      westernMonth: firstOfMonth.month,
      westernMonthName: westernMonthName,
      days: days,
    );
  }

  /// Get previous month days to fill grid
  static List<MyanmarDayData> _getPreviousMonthDays(
    int currentYear,
    int currentMonth,
    int count,
    String languageCode,
  ) {
    final currentLanguage = MyanmarCalendar.currentLanguage;
    final targetLanguage = Language.fromCode(languageCode);

    try {
      if (currentLanguage != targetLanguage) {
        MyanmarCalendar.setLanguage(targetLanguage);
      }

      // Calculate previous Myanmar month
      int prevYear = currentYear;
      int prevMonth = currentMonth - 1;

      if (prevMonth < 1) {
        prevYear--;
        prevMonth = 14; // Last month of Myanmar year
      }

      // Get previous month's dates
      final prevMonthDates = MyanmarCalendar.getMyanmarMonth(
        prevYear,
        prevMonth,
      );

      final prevWesternDates = MyanmarCalendar.getWesternDatesForMyanmarMonth(
        prevYear,
        prevMonth,
      );

      if (prevMonthDates.isEmpty || prevWesternDates.isEmpty) {
        return [];
      }

      // Get last 'count' days from previous month
      final startIndex = math.max(0, prevMonthDates.length - count);
      final days = <MyanmarDayData>[];

      for (var i = startIndex; i < prevMonthDates.length; i++) {
        final mmDate = prevMonthDates[i];
        final westernDate = prevWesternDates[i];
        final myanmarDateTime = MyanmarDateTime.fromMyanmarDate(mmDate);

        final year = targetLanguage == Language.shan
            ? myanmarDateTime.shanDate.year
            : mmDate.year;

        days.add(
          MyanmarDayData(
            westernYear: westernDate.year,
            westernMonth: westernDate.month,
            westernDay: westernDate.day,
            myanmarYear: year,
            myanmarMonth: mmDate.month,
            myanmarMonthName: mmDate.format(pattern: '&M'),
            moonPhase: mmDate.moonPhase,
            fortnightDay: mmDate.fortnightDay,
            hasHoliday: myanmarDateTime.allHolidays.isNotEmpty,
            isToday: false,
            isCurrentMonth: false,
          ),
        );
      }

      return days;
    } catch (e) {
      debugPrint('⚠️ Error getting previous month days: $e');
      return [];
    } finally {
      if (currentLanguage != targetLanguage) {
        MyanmarCalendar.setLanguage(currentLanguage);
      }
    }
  }

  /// Get next month days to fill grid
  static List<MyanmarDayData> _getNextMonthDays(
    int currentYear,
    int currentMonth,
    int count,
    String languageCode,
  ) {
    final currentLanguage = MyanmarCalendar.currentLanguage;
    final targetLanguage = Language.fromCode(languageCode);

    try {
      if (currentLanguage != targetLanguage) {
        MyanmarCalendar.setLanguage(targetLanguage);
      }

      // Calculate next Myanmar month
      int nextYear = currentYear;
      int nextMonth = currentMonth + 1;

      if (nextMonth > 14) {
        nextYear++;
        nextMonth = 1;
      }

      // Get next month's dates
      final nextMonthDates = MyanmarCalendar.getMyanmarMonth(
        nextYear,
        nextMonth,
      );

      final nextWesternDates = MyanmarCalendar.getWesternDatesForMyanmarMonth(
        nextYear,
        nextMonth,
      );

      if (nextMonthDates.isEmpty || nextWesternDates.isEmpty) {
        return [];
      }

      // Get first 'count' days from next month
      final days = <MyanmarDayData>[];

      for (var i = 0; i < count && i < nextMonthDates.length; i++) {
        final mmDate = nextMonthDates[i];
        final westernDate = nextWesternDates[i];
        final myanmarDateTime = MyanmarDateTime.fromMyanmarDate(mmDate);

        final year = targetLanguage == Language.shan
            ? myanmarDateTime.shanDate.year
            : mmDate.year;

        days.add(
          MyanmarDayData(
            westernYear: westernDate.year,
            westernMonth: westernDate.month,
            westernDay: westernDate.day,
            myanmarYear: year,
            myanmarMonth: mmDate.month,
            myanmarMonthName: mmDate.format(pattern: '&M'),
            moonPhase: mmDate.moonPhase,
            fortnightDay: mmDate.fortnightDay,
            hasHoliday: myanmarDateTime.allHolidays.isNotEmpty,
            isToday: false,
            isCurrentMonth: false,
          ),
        );
      }

      return days;
    } catch (e) {
      debugPrint('⚠️ Error getting next month days: $e');
      return [];
    } finally {
      if (currentLanguage != targetLanguage) {
        MyanmarCalendar.setLanguage(currentLanguage);
      }
    }
  }

  /// Check if date is today
  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Convert month data to map for timeline serialization.
  static Map<String, dynamic> _toMap(MyanmarMonthData monthData) {
    return {
      'myanmar_year': monthData.myanmarYear,
      'myanmar_month': monthData.myanmarMonth,
      'myanmar_month_name': monthData.myanmarMonthName,
      'western_year': monthData.westernYear,
      'western_month': monthData.westernMonth,
      'western_month_name': monthData.westernMonthName,
      'days': monthData.days
          .map(
            (day) => {
              'western_year': day.westernYear,
              'western_month': day.westernMonth,
              'western_day': day.westernDay,
              'myanmar_year': day.myanmarYear,
              'myanmar_month': day.myanmarMonth,
              'myanmar_month_name': day.myanmarMonthName,
              'moon_phase': day.moonPhase,
              'fortnight_day': day.fortnightDay,
              'has_holiday': day.hasHoliday,
              'is_today': day.isToday,
              'is_current_month': day.isCurrentMonth,
            },
          )
          .toList(),
    };
  }
}

class MonthTimelineSnapshot {
  final String monthKey;
  final Map<String, dynamic> monthPayload;

  const MonthTimelineSnapshot({
    required this.monthKey,
    required this.monthPayload,
  });
}

// ============================================
// DATA CLASSES
// ============================================

class MyanmarMonthData {
  final int myanmarYear;
  final int myanmarMonth;
  final String myanmarMonthName;
  final int westernYear;
  final int westernMonth;
  final String westernMonthName;
  final List<MyanmarDayData> days;

  MyanmarMonthData({
    required this.myanmarYear,
    required this.myanmarMonth,
    required this.myanmarMonthName,
    required this.westernYear,
    required this.westernMonth,
    required this.westernMonthName,
    required this.days,
  });
}

class MyanmarDayData {
  final int westernYear;
  final int westernMonth;
  final int westernDay;
  final int myanmarYear;
  final int myanmarMonth;
  final String myanmarMonthName;
  final int moonPhase;
  final int fortnightDay;
  final bool hasHoliday;
  final bool isToday;
  final bool isCurrentMonth;

  MyanmarDayData({
    required this.westernYear,
    required this.westernMonth,
    required this.westernDay,
    required this.myanmarYear,
    required this.myanmarMonth,
    required this.myanmarMonthName,
    required this.moonPhase,
    required this.fortnightDay,
    required this.hasHoliday,
    required this.isToday,
    required this.isCurrentMonth,
  });
}
