import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

import '../domain/entities/calendar_generation_mode.dart';
import '../domain/entities/calendar_generation_request.dart';
import '../domain/entities/calendar_page_model.dart';

class CalendarPageModelBuilder {
  List<CalendarPageModel> build(CalendarGenerationRequest request) {
    applyMyanmarCalendarRuntimeConfig(
      baseConfig: request.calendarConfig,
      language: request.language,
      useDeviceTimezone: request.useDeviceTimezone,
      cacheProfile: MyanmarCalendarCacheProfile.highPerformance,
    );

    if (request.mode == CalendarGenerationMode.month) {
      return [
        _buildMonthPage(
          year: request.year,
          month: request.month ?? DateTime.now().month,
          request: request,
        ),
      ];
    }

    return List<CalendarPageModel>.generate(
      12,
      (index) => _buildMonthPage(
        year: request.year,
        month: index + 1,
        request: request,
      ),
      growable: false,
    );
  }

  CalendarPageModel _buildMonthPage({
    required int year,
    required int month,
    required CalendarGenerationRequest request,
  }) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final offset = firstDayOfMonth.weekday % 7;
    final gridStart = firstDayOfMonth.subtract(Duration(days: offset));

    final dayCells = List<CalendarDayCellModel>.generate(42, (index) {
      final date = gridStart.add(Duration(days: index));
      final completeDate = MyanmarCalendar.getCompleteDate(
        date,
        language: request.language,
      );

      final hasHoliday =
          completeDate.allHolidays.isNotEmpty ||
          completeDate.allAnniversaryDays.isNotEmpty;
      final hasAstrology = completeDate.astrologicalDays.isNotEmpty;

      return CalendarDayCellModel(
        westernDate: date,
        westernDayLabel: translateNumbers(
          '${date.day}',
          language: request.language,
        ),
        myanmarDayLabel: MyanmarCalendar.formatMyanmar(
          completeDate.myanmar,
          pattern: '&f',
          language: request.language,
        ),
        isCurrentMonth: date.month == month,
        isToday: _isSameDate(date, DateTime.now()),
        hasHoliday: hasHoliday,
        hasAstrology: hasAstrology,
      );
    }, growable: false);

    final weekdayLabels = List<String>.generate(7, (index) {
      final weekday = (request.firstDayOfWeek + index) % 7;
      return TranslationService.getShortWeekdayName(weekday, request.language);
    }, growable: false);

    final monthName = TranslationService.getWesternMonthName(
      month,
      request.language,
    );
    final title =
        '$monthName ${translateNumbers('$year', language: request.language)}';

    return CalendarPageModel(
      year: year,
      month: month,
      title: title,
      weekdayLabels: weekdayLabels,
      dayCells: dayCells,
    );
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
