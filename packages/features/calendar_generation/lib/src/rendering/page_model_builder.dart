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
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final offset = firstDayOfMonth.weekday % 7;
    final gridStart = firstDayOfMonth.subtract(Duration(days: offset));
    final monthDates = List<CompleteDate>.generate(
      lastDayOfMonth.day,
      (index) => MyanmarCalendar.getCompleteDate(
        DateTime(year, month, index + 1),
        language: request.language,
      ),
      growable: false,
    );

    final dayCells = List<CalendarDayCellModel>.generate(42, (index) {
      final date = gridStart.add(Duration(days: index));
      final isCurrentMonth = date.month == month;
      if (!isCurrentMonth) {
        return CalendarDayCellModel(
          westernDate: date,
          westernDayLabel: '',
          myanmarDayLabel: '',
          isCurrentMonth: false,
          isPlaceholder: true,
          isToday: false,
          isFullMoon: false,
          isNewMoon: false,
          moonPhase: 0,
          hasHoliday: false,
          hasPublicHoliday: false,
          hasAstrology: false,
        );
      }

      final completeDate = MyanmarCalendar.getCompleteDate(
        date,
        language: request.language,
      );

      final hasHoliday =
          completeDate.allHolidays.isNotEmpty ||
          completeDate.allAnniversaryDays.isNotEmpty;
      final hasPublicHoliday = completeDate.publicHolidays.isNotEmpty;
      final sabbathRaw = completeDate.sabbath.trim();
      final sabbathLabel = sabbathRaw == 'Sabbath'
          ? TranslationService.translateTo(sabbathRaw, request.language)
          : null;
      final sabbathEveLabel = sabbathRaw == 'Sabbath Eve'
          ? TranslationService.translateTo(sabbathRaw, request.language)
          : null;
      final yatyazaLabel = _translateIfNotEmpty(
        completeDate.yatyaza,
        request.language,
      );
      final pyathadaRaw = completeDate.pyathada.trim();
      final isAfternoonPyathada = pyathadaRaw.toLowerCase().contains(
        'afternoon',
      );
      final pyathadaLabel = !isAfternoonPyathada
          ? _translateIfNotEmpty(pyathadaRaw, request.language)
          : null;
      final afternoonPyathadaLabel = isAfternoonPyathada
          ? _translateIfNotEmpty(pyathadaRaw, request.language)
          : null;
      final otherAstroLabels = completeDate.astrologicalDays
          .map((day) => _translateIfNotEmpty(day, request.language))
          .whereType<String>()
          .toList(growable: false);
      final otherAstrologyLabel = otherAstroLabels.isEmpty
          ? null
          : otherAstroLabels.take(2).join(' • ');
      final hasAstrology =
          sabbathLabel != null ||
          sabbathEveLabel != null ||
          yatyazaLabel != null ||
          pyathadaLabel != null ||
          afternoonPyathadaLabel != null ||
          otherAstrologyLabel != null;

      return CalendarDayCellModel(
        westernDate: date,
        westernDayLabel: '${date.day}',
        myanmarDayLabel: _buildMyanmarDayLabel(
          completeDate: completeDate,
          language: request.language,
        ),
        isCurrentMonth: true,
        isPlaceholder: false,
        isToday: _isSameDate(date, DateTime.now()),
        isFullMoon: completeDate.isFullMoon,
        isNewMoon: completeDate.isNewMoon,
        moonPhase: completeDate.moonPhase,
        hasHoliday: hasHoliday,
        hasPublicHoliday: hasPublicHoliday,
        hasAstrology: hasAstrology,
        sabbathLabel: sabbathLabel,
        sabbathEveLabel: sabbathEveLabel,
        yatyazaLabel: yatyazaLabel,
        pyathadaLabel: pyathadaLabel,
        afternoonPyathadaLabel: afternoonPyathadaLabel,
        otherAstrologyLabel: otherAstrologyLabel,
      );
    }, growable: false);

    final weekdayLabels = List<String>.generate(7, (index) {
      final weekday = (request.firstDayOfWeek + index) % 7;
      return _weekdayHeaderLabel(weekday, request.language);
    }, growable: false);

    final westernMonthName = TranslationService.getWesternMonthName(
      month,
      request.language,
    );
    final westernTitle =
        '$westernMonthName ${translateNumbers('$year', language: request.language)}';
    final myanmarMonthLabel = _buildMyanmarMonthLabel(monthDates);
    final myanmarYearLabel = _buildMyanmarYearLabel(monthDates);
    final myanmarTitle = myanmarYearLabel.isEmpty
        ? myanmarMonthLabel
        : '$myanmarMonthLabel ${TranslationService.translateTo('Myanmar Year', request.language)} $myanmarYearLabel';

    return CalendarPageModel(
      year: year,
      month: month,
      westernTitle: westernTitle,
      myanmarTitle: myanmarTitle,
      weekdayLabels: weekdayLabels,
      dayCells: dayCells,
    );
  }

  String _weekdayHeaderLabel(int weekdayIndex, Language language) {
    if (language == Language.english ||
        language == Language.myanmar ||
        language == Language.zawgyi) {
      return _narrowWeekdayLabel(weekdayIndex, language);
    }

    final fullName = TranslationService.getWeekdayName(
      weekdayIndex,
      language,
    ).trim();
    final stripped = _stripWeekdayPrefix(fullName, language);
    return stripped.isEmpty ? fullName : stripped;
  }

  String _narrowWeekdayLabel(int weekdayIndex, Language language) {
    if (language == Language.english) {
      return switch (weekdayIndex) {
        1 => 'S',
        2 => 'M',
        3 => 'T',
        4 => 'W',
        5 => 'T',
        6 => 'F',
        _ => 'S',
      };
    }

    return switch (weekdayIndex) {
      1 => 'နွေ',
      2 => 'လာ',
      3 => 'ဂါ',
      4 => 'ဟူး',
      5 => 'ကြာ',
      6 => 'သော',
      _ => 'စ',
    };
  }

  String _stripWeekdayPrefix(String text, Language language) {
    if (language == Language.mon && text.startsWith('တ္ၚဲ')) {
      return text.replaceFirst('တ္ၚဲ', '').trim();
    }
    if (language == Language.shan && text.startsWith('ဝၼ်း')) {
      return text.replaceFirst('ဝၼ်း', '').trim();
    }
    if (language == Language.karen && text.startsWith('မုၢ်')) {
      return text.replaceFirst('မုၢ်', '').trim();
    }
    return text;
  }

  String _buildMyanmarMonthLabel(List<CompleteDate> dates) {
    final months = <String>[];
    for (final date in dates) {
      final month = MyanmarCalendar.formatMyanmar(date.myanmar, pattern: '&M');
      if (months.contains(month)) {
        continue;
      }
      months.add(month);
    }
    if (months.isEmpty) {
      return '';
    }
    if (months.length == 1) {
      return months.first;
    }
    return '${months.first} - ${months.last}';
  }

  String _buildMyanmarYearLabel(List<CompleteDate> dates) {
    final years = <String>[];
    for (final date in dates) {
      final year = MyanmarCalendar.formatMyanmar(date.myanmar, pattern: '&y');
      if (years.contains(year)) {
        continue;
      }
      years.add(year);
    }
    if (years.isEmpty) {
      return '';
    }
    if (years.length == 1) {
      return years.first;
    }
    return '${years.first} - ${years.last}';
  }

  String? _translateIfNotEmpty(String? raw, Language language) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    return TranslationService.translateTo(value, language);
  }

  String _buildMyanmarDayLabel({
    required CompleteDate completeDate,
    required Language language,
  }) {
    return MyanmarCalendar.formatMyanmar(
      completeDate.myanmar,
      pattern: '&f',
      language: language,
    );
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
