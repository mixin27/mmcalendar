class AppDateUtils {
  /// Get list of dates between two dates
  static List<DateTime> getDatesBetween(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var currentDate = start;
    while (!currentDate.isAfter(end) && dates.length < 42) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Ensure we always have exactly 42 dates for a 6×7 grid
    while (dates.length < 42) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Get list of months between two dates
  static List<DateTime> getMonthsBetween(DateTime start, DateTime end) {
    final months = <DateTime>[];
    var current = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);

    while (current.isBefore(endMonth) || current.isAtSameMomentAs(endMonth)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }

    return months;
  }

  /// Get week number of year
  static int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }

  /// Get dates in a week
  static List<DateTime> getWeekDates(DateTime date, {int firstDayOfWeek = 1}) {
    // firstDayOfWeek: 1=Monday, 7=Sunday (ISO 8601)
    final weekday = date.weekday;
    final difference = (weekday - firstDayOfWeek + 7) % 7;
    final monday = date.subtract(Duration(days: difference));

    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  /// Get dates in a month
  static List<DateTime> getMonthDates(DateTime date) {
    // final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);

    return List.generate(
      lastDay.day,
      (index) => DateTime(date.year, date.month, index + 1),
    );
  }

  /// Get calendar grid dates (including previous and next month)
  static List<DateTime> getCalendarGridDates(
    DateTime month, {
    int firstDayOfWeek = 0, // default: Saturday
  }) {
    final firstDayOfMonth = DateTime(month.year, month.month);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // Convert Dart weekday (1=Mon…7=Sun) to Myanmar weekday (0=Sat…6=Fri)
    int toMyanmarWeekday(int dartWeekday) => (dartWeekday + 1) % 7;
    final firstDayMyanmar = toMyanmarWeekday(firstDayOfMonth.weekday);
    final lastDayMyanmar = toMyanmarWeekday(lastDayOfMonth.weekday);

    // Step back to the start of the first grid row
    final daysBack = (firstDayMyanmar - firstDayOfWeek + 7) % 7;
    final startDate = firstDayOfMonth.subtract(Duration(days: daysBack));

    // Step forward to the end of the last grid row
    final daysForward = (firstDayOfWeek + 6 - lastDayMyanmar) % 7;
    final endDate = lastDayOfMonth.add(Duration(days: daysForward));

    return getDatesBetween(startDate, endDate);
  }

  /// Check if two dates are in same week
  static bool isSameWeek(DateTime date1, DateTime date2) {
    return getWeekNumber(date1) == getWeekNumber(date2) &&
        date1.year == date2.year;
  }

  /// Get quarter of year (1-4)
  static int getQuarter(DateTime date) {
    return ((date.month - 1) / 3).floor() + 1;
  }

  /// Get first date of quarter
  static DateTime getFirstDateOfQuarter(DateTime date) {
    final quarter = getQuarter(date);
    final firstMonth = (quarter - 1) * 3 + 1;
    return DateTime(date.year, firstMonth, 1);
  }

  /// Get last date of quarter
  static DateTime getLastDateOfQuarter(DateTime date) {
    final quarter = getQuarter(date);
    final lastMonth = quarter * 3;
    return DateTime(date.year, lastMonth + 1, 0);
  }

  /// Parse date string with multiple formats
  static DateTime? parseFlexible(String dateString) {
    // Try ISO 8601 format first
    var date = DateTime.tryParse(dateString);
    if (date != null) return date;

    // Try common formats
    final formats = [
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'), // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'), // MM-DD-YYYY or DD-MM-YYYY
      RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})'), // YYYY/MM/DD
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'), // YYYY-MM-DD
    ];

    for (final format in formats) {
      final match = format.firstMatch(dateString);
      if (match != null) {
        try {
          final parts = [
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
          ];

          // Try to determine if it's year-month-day or day-month-year
          if (parts[0] > 31) {
            // First part is year
            return DateTime(parts[0], parts[1], parts[2]);
          } else if (parts[2] > 31) {
            // Last part is year
            return DateTime(parts[2], parts[0], parts[1]);
          }
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }
}
