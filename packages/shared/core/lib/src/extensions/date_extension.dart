import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  /// Check if this date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if this date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if this date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Check if this date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Check if this date is in the future
  bool get isFuture => isAfter(DateTime.now());

  /// Get the start of the day (00:00:00)
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get the end of the day (23:59:59)
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Get the start of the month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Get the end of the month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// Get the start of the year
  DateTime get startOfYear => DateTime(year, 1, 1);

  /// Get the end of the year
  DateTime get endOfYear => DateTime(year, 12, 31, 23, 59, 59, 999);

  /// Get the number of days in this month
  int get daysInMonth => DateTime(year, month + 1, 0).day;

  /// Check if this is the same day as another date
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Check if this is the same month as another date
  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  /// Check if this is the same year as another date
  bool isSameYear(DateTime other) => year == other.year;

  /// Add months to this date
  DateTime addMonths(int months) {
    int newMonth = month + months;
    int newYear = year;

    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }

    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }

    // Handle day overflow (e.g., Jan 31 + 1 month = Feb 28/29)
    int newDay = day;
    int daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    if (newDay > daysInNewMonth) {
      newDay = daysInNewMonth;
    }

    return DateTime(newYear, newMonth, newDay, hour, minute, second);
  }

  /// Subtract months from this date
  DateTime subtractMonths(int months) => addMonths(-months);

  /// Format date with pattern
  String format(String pattern) => DateFormat(pattern).format(this);

  /// Format as "Jan 15, 2024"
  String get formatMedium => DateFormat.yMMMd().format(this);

  /// Format as "January 15, 2024"
  String get formatLong => DateFormat.yMMMMd().format(this);

  /// Format as "01/15/2024"
  String get formatShort => DateFormat.yMd().format(this);

  /// Format as "15 Jan"
  String get formatDayMonth => DateFormat('d MMM').format(this);

  /// Format as "Mon, Jan 15"
  String get formatWeekdayDayMonth => DateFormat('E, MMM d').format(this);

  /// Get relative time string (e.g., "2 hours ago", "in 3 days")
  String get relativeTime {
    final now = DateTime.now();
    final difference = this.difference(now);

    if (difference.inDays > 0) {
      return 'in ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    } else if (difference.inDays < 0) {
      final days = -difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
    } else if (difference.inHours < 0) {
      final hours = -difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else if (difference.inMinutes < 0) {
      final minutes = -difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }

  /// Get human-readable date string
  String get humanReadable {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';

    final now = DateTime.now();
    final difference = this.difference(now).inDays.abs();

    if (difference < 7) {
      return DateFormat('EEEE').format(this); // Day name
    } else if (difference < 365) {
      return DateFormat('MMM d').format(this); // Month and day
    } else {
      return DateFormat('MMM d, yyyy').format(this); // Full date
    }
  }

  /// Copy with different date components
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }
}
