import 'dart:math' as math;

import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'date_cell.dart';
import 'day_cells.dart';

/// The month as rows of seven days.
///
/// Row height comes from the layout, not an aspect ratio: with a bounded
/// height the rows split it evenly (capped at [maxRowHeightFactor] × the
/// cell width), so the whole month always fits. Unbounded, rows fall back
/// to a width-based height.
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
  final Map<DateTime, List<CalendarEventItem>> eventsByDate;
  final CalendarGridStyle gridStyle;
  final double maxRowHeightFactor;
  final EdgeInsets padding;

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
    this.eventsByDate = const <DateTime, List<CalendarEventItem>>{},
    this.gridStyle = CalendarGridStyle.defaultStyle,
    this.maxRowHeightFactor = 1.6,
    this.padding = const EdgeInsets.symmetric(horizontal: 6),
  });

  int get rowCount => visibleRows(gridDates, currentMonth).length;

  /// Week rows that contain at least one day of [month]. The grid data is
  /// always six weeks; trailing weeks wholly in the next month are skipped
  /// so the month takes four to six rows.
  static List<List<CompleteDate>> visibleRows(
    List<CompleteDate> gridDates,
    DateTime month,
  ) =>
      [
            for (var i = 0; i < gridDates.length; i += 7)
              gridDates.sublist(i, math.min(i + 7, gridDates.length)),
          ]
          .where(
            (week) => week.any(
              (d) =>
                  d.westernYear == month.year && d.westernMonth == month.month,
            ),
          )
          .toList();

  /// Row height for a grid of [rows] in a box of [size].
  static double rowHeightFor({
    required Size size,
    required int rows,
    double horizontalPadding = 12,
    double maxRowHeightFactor = 1.6,
    double fallbackRatio = 1.3,
  }) {
    final cellWidth = (size.width - horizontalPadding) / 7;
    if (!size.height.isFinite) return cellWidth * fallbackRatio;
    return math.min(size.height / rows, cellWidth * maxRowHeightFactor);
  }

  @override
  Widget build(BuildContext context) {
    final options = DayCellOptions(
      showHolidays: showHolidays,
      showAnniversaryDays: showAnniversaryDays,
      showSabbaths: showSabbaths,
      showAstrology: showAstrology,
      showWesternDates: showWesternDates,
      showMyanmarDates: showMyanmarDates,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = visibleRows(gridDates, currentMonth);
        final rowHeight = rowHeightFor(
          size: constraints.biggest,
          rows: rows.length,
          horizontalPadding: padding.horizontal,
          maxRowHeightFactor: maxRowHeightFactor,
          fallbackRatio: gridStyle == CalendarGridStyle.classic ? 1.33 : 1.25,
        );
        return Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final week in rows)
                SizedBox(
                  height: rowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final info in week)
                        Expanded(child: _cell(info, options)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _cell(CompleteDate info, DayCellOptions options) {
    final date = DateTime(info.westernYear, info.westernMonth, info.westernDay);
    final events = eventsByDate[date] ?? const <CalendarEventItem>[];
    void onTap() => onDateTap(date);
    final cell = switch (gridStyle) {
      CalendarGridStyle.classic => DateCell(
        dateInfo: info,
        isSelected: _isSelected(date),
        isToday: _isToday(date),
        isInCurrentMonth: _isInCurrentMonth(date),
        showHolidays: showHolidays,
        showAnniversaryDays: showAnniversaryDays,
        showSabbaths: showSabbaths,
        showAstrology: showAstrology,
        showWesternDates: showWesternDates,
        showMyanmarDates: showMyanmarDates,
        eventsForDate: events,
        onTap: onTap,
      ),
      CalendarGridStyle.detailed => DetailedDayCell(
        data: _data(info, date, events, options),
        onTap: onTap,
      ),
      CalendarGridStyle.clean => CleanDayCell(
        data: _data(info, date, events, options),
        onTap: onTap,
      ),
    };
    return Hero(tag: 'date_${date.toIso8601String()}', child: cell);
  }

  DayCellData _data(
    CompleteDate info,
    DateTime date,
    List<CalendarEventItem> events,
    DayCellOptions options,
  ) => DayCellData(
    info: info,
    isToday: _isToday(date),
    isSelected: _isSelected(date),
    isInMonth: _isInCurrentMonth(date),
    options: options,
    events: events,
  );

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
