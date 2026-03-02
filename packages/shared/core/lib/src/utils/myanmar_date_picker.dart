import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart' as flutter_mmcal;
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

Future<DateTime?> showAppMyanmarDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  bool showHolidays = true,
  bool showAstrology = false,
  bool showWesternDates = true,
  bool showMyanmarDates = true,
}) async {
  final selectedDate = await flutter_mmcal.showMyanmarDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    language: MyanmarCalendar.currentLanguage,
    theme: flutter_mmcal.MyanmarCalendarTheme.fromColor(
      Theme.of(context).colorScheme.primary,
      isDark: Theme.of(context).brightness == Brightness.dark,
    ),
    showHolidays: showHolidays,
    showAstrology: showAstrology,
    showWesternDates: showWesternDates,
    showMyanmarDates: showMyanmarDates,
  );

  return selectedDate?.western.toDateTime();
}
