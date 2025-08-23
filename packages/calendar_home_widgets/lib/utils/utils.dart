import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Calculate delay until next midnight
Duration timeUntilNextMidnight() {
  final now = DateTime.now();
  final tomorrowMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0);
  return tomorrowMidnight.difference(now);
}

bool isWeekend(DateTime date) =>
    date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

bool isHoliday(DateTime date, MyanmarDate mmDate) {
  if (isWeekend(date)) return true;

  return mmDate.holidays.isNotEmpty;
}

Future<String> getWidgetTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final theme = prefs.getString('key_theme') ?? "ThemeMode.system";
  return theme;
}
