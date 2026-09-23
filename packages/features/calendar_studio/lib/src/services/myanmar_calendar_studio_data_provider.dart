import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:flutter/material.dart' show DateUtils;

import '../models/calendar_studio_types.dart';
import 'calendar_studio_contracts.dart';

/// Canonical Studio data adapter backed by `myanmar_calendar_dart`.
///
/// Presentation receives immutable labels only; it cannot edit Myanmar dates,
/// moon phases, holidays, or astrology data.
class MyanmarCalendarStudioDataProvider implements CalendarStudioDataProvider {
  const MyanmarCalendarStudioDataProvider();

  @override
  Future<List<CalendarStudioDayData>> daysFor(
    CalendarStudioSource source, {
    required int month,
  }) async {
    final days = DateUtils.getDaysInMonth(source.year, month);
    return List.generate(days, (index) {
      final date = DateTime(source.year, month, index + 1);
      final complete = MyanmarCalendar.getCompleteDate(date);
      return CalendarStudioDayData(
        date: date,
        gregorianLabel: '${date.day}',
        myanmarLabel: source.showMyanmarDate
            ? MyanmarCalendar.formatMyanmar(
                complete.myanmar,
                pattern: '&P &f',
                language: Language.myanmar,
              )
            : null,
        moonLabel: null,
        holidayLabel: source.showHolidays && complete.publicHolidays.isNotEmpty
            ? complete.publicHolidays.first
            : null,
        astrologyLabel: source.showAstrology && complete.hasAstrologicalDays
            ? complete.astrologicalDays.join(', ')
            : null,
        moonPhase: complete.moonPhase,
        fortnightDay: complete.fortnightDay,
        isSabbath: complete.isSabbath,
        isSabbathEve: complete.isSabbathEve,
        hasAstrology: complete.hasAstrologicalDays,
      );
    });
  }
}
