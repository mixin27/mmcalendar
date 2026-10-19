import 'dart:math' as math;

import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'calendar_colors.dart';
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
        // Rows start at the grid's first week, so a cell's index is
        // row * 7 + column.
        final places = MyanmarMonthPlace.of(gridDates);
        final focus = gridStyle == CalendarGridStyle.focusWeek;
        var rowHeight = rowHeightFor(
          size: constraints.biggest,
          rows: rows.length,
          horizontalPadding: padding.horizontal,
          maxRowHeightFactor: maxRowHeightFactor,
          fallbackRatio: gridStyle == CalendarGridStyle.classic ? 1.33 : 1.25,
        );
        // Focus week keeps the days compact; the open week's panel takes
        // what it needs of the rest and scrolls when that is not enough.
        final focusRow = focus ? _focusRow(rows) : -1;
        final bounded = constraints.maxHeight.isFinite;
        if (focus) {
          final cellWidth = (constraints.maxWidth - padding.horizontal) / 7;
          rowHeight = math.min(rowHeight, math.max(44, cellWidth * 1.05));
        }
        Widget panel() {
          final info = rows[focusRow].firstWhere(
            (d) => _isSameDay(d, _focusDate),
          );
          final date = DateTime(
            info.westernYear,
            info.westernMonth,
            info.westernDay,
          );
          return FocusWeekPanel(
            data: _data(
              info,
              date,
              eventsByDate[date] ?? const <CalendarEventItem>[],
              options,
              const MyanmarMonthPlace(),
            ),
            onTap: () => onDateTap(date),
          );
        }

        Widget cells(int r, List<CompleteDate> week) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (c, info) in week.indexed)
              Expanded(child: _cell(info, options, places[r * 7 + c])),
          ],
        );
        DayCellData dayData(CompleteDate info) {
          final date = DateTime(
            info.westernYear,
            info.westernMonth,
            info.westernDay,
          );
          return _data(
            info,
            date,
            eventsByDate[date] ?? const <CalendarEventItem>[],
            options,
            const MyanmarMonthPlace(),
          );
        }

        Widget row(int r, List<CompleteDate> week) => switch (gridStyle) {
          // The week's moon as a band under its days.
          CalendarGridStyle.moonBand => Column(
            children: [
              Expanded(child: cells(r, week)),
              SizedBox(
                height: 20,
                child: MoonBand(days: [for (final d in week) dayData(d)]),
              ),
            ],
          ),
          // Each week a card: its days, then its events on a timeline.
          CalendarGridStyle.weekRibbons => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: CalendarColors.of(context).fill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: math.max(36, math.min(46, rowHeight - 6 - 18)),
                    child: cells(r, week),
                  ),
                  Expanded(
                    child: WeekTimeline(
                      days: [for (final d in week) dayData(d)],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _ => cells(r, week),
        };

        if (gridStyle == CalendarGridStyle.heroToday) {
          final cellWidth = (constraints.maxWidth - padding.horizontal) / 7;
          Widget month(double height) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (r, week) in rows.indexed)
                SizedBox(height: height, child: row(r, week)),
            ],
          );
          if (!bounded) {
            return Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [_heroCard(rows, options), month(cellWidth)],
              ),
            );
          }
          // The month stays quiet but readable: rows no taller than the
          // cells are wide, and at least 34 high. The card takes the rest
          // and scrolls when that is not enough.
          final rowHeight = math.min(
            cellWidth * 1.05,
            math.max(34.0, constraints.maxHeight * .6 / rows.length),
          );
          return Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(child: _heroCard(rows, options)),
                ),
                month(rowHeight),
              ],
            ),
          );
        }

        return Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (r, week) in rows.indexed) ...[
                SizedBox(height: rowHeight, child: row(r, week)),
                if (r == focusRow) bounded ? Flexible(child: panel()) : panel(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _cell(
    CompleteDate info,
    DayCellOptions options,
    MyanmarMonthPlace place,
  ) {
    final date = DateTime(info.westernYear, info.westernMonth, info.westernDay);
    final events = eventsByDate[date] ?? const <CalendarEventItem>[];
    void onTap() => onDateTap(date);
    DayCellData data() => _data(info, date, events, options, place);
    final cell = switch (gridStyle) {
      CalendarGridStyle.almanac => AlmanacDayCell(data: data(), onTap: onTap),
      CalendarGridStyle.auspice => AuspiceDayCell(data: data(), onTap: onTap),
      CalendarGridStyle.weekRibbons => FocusWeekDayCell(
        data: data(),
        onTap: onTap,
        dots: false,
      ),
      CalendarGridStyle.heroToday => FocusWeekDayCell(
        data: data(),
        onTap: onTap,
      ),
      CalendarGridStyle.moonBand => FocusWeekDayCell(
        data: data(),
        onTap: onTap,
        dots: false,
      ),
      CalendarGridStyle.focusWeek => FocusWeekDayCell(
        data: data(),
        onTap: onTap,
      ),
      CalendarGridStyle.monthRegions => MonthRegionsDayCell(
        data: data(),
        onTap: onTap,
      ),
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
      CalendarGridStyle.detailed => DetailedDayCell(data: data(), onTap: onTap),
      CalendarGridStyle.clean => CleanDayCell(data: data(), onTap: onTap),
      CalendarGridStyle.detailedV2 => DetailedV2DayCell(
        data: data(),
        onTap: onTap,
      ),
      CalendarGridStyle.lunarFirst => LunarFirstDayCell(
        data: data(),
        onTap: onTap,
      ),
      CalendarGridStyle.minimal => MinimalDayCell(data: data(), onTap: onTap),
      CalendarGridStyle.moonStrip => MoonStripDayCell(
        data: data(),
        onTap: onTap,
      ),
      CalendarGridStyle.agenda => AgendaDayCell(data: data(), onTap: onTap),
      CalendarGridStyle.classicPrint => ClassicPrintDayCell(
        data: data(),
        onTap: onTap,
      ),
      CalendarGridStyle.tiles => TilesDayCell(data: data(), onTap: onTap),
      CalendarGridStyle.moonlight => MoonlightDayCell(
        data: data(),
        onTap: onTap,
      ),
      CalendarGridStyle.split => SplitDayCell(data: data(), onTap: onTap),
      CalendarGridStyle.poster => PosterDayCell(data: data(), onTap: onTap),
      CalendarGridStyle.moonRing => MoonRingDayCell(data: data(), onTap: onTap),
      CalendarGridStyle.astrology => AstrologyDayCell(
        data: data(),
        onTap: onTap,
      ),
    };
    // No Hero: nothing flies to a day, and many grids of the same month
    // (Settings previews, the month switcher, the year view) would share tags.
    return cell;
  }

  DayCellData _data(
    CompleteDate info,
    DateTime date,
    List<CalendarEventItem> events,
    DayCellOptions options,
    MyanmarMonthPlace place,
  ) => DayCellData(
    info: info,
    isToday: _isToday(date),
    isSelected: _isSelected(date),
    isInMonth: _isInCurrentMonth(date),
    options: options,
    events: events,
    monthPlace: place,
  );

  /// The Hero today card for the day the grid opens, with the next
  /// holiday after it in the month.
  Widget _heroCard(List<List<CompleteDate>> rows, DayCellOptions options) {
    final days = rows.expand((week) => week).toList();
    final i = days.indexWhere((d) => _isSameDay(d, _focusDate));
    final info = days[i < 0 ? 0 : i];
    final date = DateTime(info.westernYear, info.westernMonth, info.westernDay);
    (CompleteDate, int)? next;
    if (showHolidays) {
      for (var j = i + 1; j < days.length; j++) {
        if (days[j].allHolidays.isNotEmpty) {
          next = (days[j], j - i);
          break;
        }
      }
    }
    return HeroDayCard(
      data: _data(
        info,
        date,
        eventsByDate[date] ?? const <CalendarEventItem>[],
        options,
        const MyanmarMonthPlace(),
      ),
      nextHoliday: next,
      onTap: () => onDateTap(date),
    );
  }

  /// The day a Focus week grid opens: the selection, else today when it
  /// is in this month, else the 1st.
  DateTime get _focusDate {
    if (selectedDate != null && _isInCurrentMonth(selectedDate!)) {
      return selectedDate!;
    }
    if (_isInCurrentMonth(today)) return today;
    return DateTime(currentMonth.year, currentMonth.month);
  }

  int _focusRow(List<List<CompleteDate>> rows) {
    final row = rows.indexWhere(
      (week) => week.any((d) => _isSameDay(d, _focusDate)),
    );
    return row < 0 ? 0 : row;
  }

  static bool _isSameDay(CompleteDate d, DateTime date) =>
      d.westernYear == date.year &&
      d.westernMonth == date.month &&
      d.westernDay == date.day;

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
