import 'package:events/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'date_cell.dart';

class CalendarGrid extends StatelessWidget {
  final List<CompleteDate> gridDates;
  final DateTime currentMonth;
  final DateTime? selectedDate;
  final DateTime today;
  final Function(DateTime) onDateTap;
  final bool showHolidays;
  final bool showAnniversaryDays;
  final bool showSabbaths;
  final bool showAstrology;
  final bool showWesternDates;
  final bool showMyanmarDates;
  final Map<DateTime, List<Event>> eventsByDate;

  const CalendarGrid({
    super.key,
    required this.gridDates,
    required this.currentMonth,
    this.selectedDate,
    required this.today,
    required this.onDateTap,
    this.showHolidays = true,
    this.showAnniversaryDays = true,
    this.showSabbaths = true,
    this.showAstrology = true,
    this.showWesternDates = true,
    this.showMyanmarDates = true,
    this.eventsByDate = const {},
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      crossAxisCount: 7,
      childAspectRatio: 0.75,
      children: gridDates.map((dateInfo) {
        final date = dateInfo.western.toDateTime();
        final dateKey = DateTime(date.year, date.month, date.day);
        final events = eventsByDate[dateKey] ?? [];

        return Hero(
          tag: 'date_${date.toIso8601String()}',
          child: DateCell(
            dateInfo: dateInfo,
            isSelected: _isSelected(date),
            isToday: _isToday(date),
            isInCurrentMonth: _isInCurrentMonth(date),
            showHolidays: showHolidays,
            showAnniversaryDays: showAnniversaryDays,
            showSabbaths: showSabbaths,
            showAstrology: showAstrology,
            showWesternDates: showWesternDates,
            showMyanmarDates: showMyanmarDates,
            showEvents: true,
            onTap: () => onDateTap(date),
            events: events,
          ),
        );
      }).toList(),
    );
  }

  bool _isToday(DateTime date) =>
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;

  bool _isSelected(DateTime date) {
    if (selectedDate == null) return false;
    return date.year == selectedDate!.year &&
        date.month == selectedDate!.month &&
        date.day == selectedDate!.day;
  }

  bool _isInCurrentMonth(DateTime date) =>
      date.year == currentMonth.year && date.month == currentMonth.month;
}
