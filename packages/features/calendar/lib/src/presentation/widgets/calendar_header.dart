import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import 'calendar_colors.dart';
import 'calendar_grid_themes.dart';

/// One compact row above the grid: the month title (tap for the month
/// picker, long-press for today) with the Myanmar months and year beneath,
/// then previous / next and Calendar Studio. Everything here is calendar
/// data, so it follows [language]. Swiping the grid also changes the month.
class CalendarHeader extends StatelessWidget {
  final DateTime currentMonth;
  final List<CompleteDate>? monthDates;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onMonthYearTap;
  final Language language;
  final bool showShanCalendar;

  /// Shown only when it would move somewhere (another month or day).
  final VoidCallback? onToday;
  final VoidCallback? onStudioTap;

  const CalendarHeader({
    super.key,
    required this.currentMonth,
    this.monthDates,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onMonthYearTap,
    this.language = Language.english,
    this.showShanCalendar = true,
    this.onToday,
    this.onStudioTap,
  });

  @override
  Widget build(BuildContext context) {
    final dates = (monthDates != null && monthDates!.isNotEmpty)
        ? monthDates!
        : <CompleteDate>[
            MyanmarCalendar.getCompleteDate(
              DateTime(currentMonth.year, currentMonth.month, 1),
            ),
          ];

    final monthLabel = _buildMyanmarMonthLabel(dates);
    final myanmarYearLabel = _buildMyanmarYearLabel(dates);
    final shanYearLabel = _buildShanYearLabel(dates);

    final yearLabel = language == Language.shan && showShanCalendar
        ? shanYearLabel
        : myanmarYearLabel;
    final l10n = AppLocalizations.of(context);
    final colors = context.colorScheme;
    final format = CalendarFormat(language);
    final myanmarScript = language != Language.english;
    final calendarColors = CalendarColors.of(context);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 6, 2),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: l10n?.calendarChooseMonth ?? 'Choose month',
              child: InkWell(
                onTap: onMonthYearTap,
                // Long-press jumps back to today.
                onLongPress: onToday,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LayoutBuilder(
                        builder: (context, box) => _Title(
                          // Narrow phones get "Nov 2026" rather than "…".
                          text: box.maxWidth < 220
                              ? format.shortMonthYear(currentMonth)
                              : format.monthYear(currentMonth),
                          myanmarScript: myanmarScript,
                          arrowColor: colors.primary,
                          colors: calendarColors,
                        ),
                      ),
                      Text(
                        '$monthLabel · $yearLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _MonthStepper(
            onPrevious: onPreviousMonth,
            onNext: onNextMonth,
            previousLabel: l10n?.previous_month ?? 'Previous Month',
            nextLabel: l10n?.next_month ?? 'Next Month',
          ),
          if (onStudioTap != null)
            IconButton(
              icon: const Icon(Icons.edit_calendar_outlined),
              onPressed: onStudioTap,
              color: colors.primary,
              visualDensity: VisualDensity.compact,
              tooltip: l10n?.calendarStudio ?? 'Calendar Studio',
            ),
        ],
      ),
    );
    if (calendarColors.paper == null) return header;
    // A grid theme's motif sits faintly behind the header's trailing corner.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Partly past the edge, so it reads as decoration, not a control.
        const PositionedDirectional(
          top: -14,
          end: -26,
          child: CalendarThemeMotif(),
        ),
        header,
      ],
    );
  }

  String _buildMyanmarMonthLabel(List<CompleteDate> dates) {
    final months = <String>[];
    for (final date in dates) {
      final month = MyanmarCalendar.formatMyanmar(
        date.myanmar,
        pattern: '&M',
        language: language,
      );
      if (!months.contains(month)) {
        months.add(month);
      }
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
      final year = MyanmarCalendar.formatMyanmar(
        date.myanmar,
        pattern: '&y',
        language: language,
      );
      if (!years.contains(year)) {
        years.add(year);
      }
    }

    if (years.isEmpty) {
      return '';
    }
    if (years.length == 1) {
      return years.first;
    }
    return '${years.first} - ${years.last}';
  }

  String _buildShanYearLabel(List<CompleteDate> dates) {
    final years = <int>[];
    for (final date in dates) {
      final year = MyanmarDateTime.fromMyanmarDate(date.myanmar).shanDate.year;
      if (!years.contains(year)) {
        years.add(year);
      }
    }

    if (years.isEmpty) {
      return '';
    }

    final firstYear = translateNumbers(
      years.first.toString(),
      language: Language.shan,
    );
    if (years.length == 1) {
      return firstYear;
    }

    final lastYear = translateNumbers(
      years.last.toString(),
      language: Language.shan,
    );
    return '$firstYear - $lastYear';
  }
}

/// The month title, shrinking to fit before it ever truncates.
class _Title extends StatelessWidget {
  const _Title({
    required this.text,
    required this.myanmarScript,
    required this.arrowColor,
    required this.colors,
  });

  final String text;
  final bool myanmarScript;
  final Color arrowColor;
  final CalendarColors colors;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          maxLines: 1,
          style: colors.numberStyle(
            context.textTheme.titleLarge!.copyWith(
              // Myanmar script is taller; a smaller size keeps the row
              // height.
              fontSize: myanmarScript ? 19 : 22,
              fontWeight: myanmarScript ? FontWeight.w700 : FontWeight.w800,
              letterSpacing: myanmarScript ? 0 : -.3,
              height: myanmarScript ? 1.45 : 1.25,
              color: colors.paper == null ? null : colors.label,
            ),
          ),
        ),
        Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: arrowColor),
      ],
    ),
  );
}

/// Previous and next month as one compact control.
class _MonthStepper extends StatelessWidget {
  const _MonthStepper({
    required this.onPrevious,
    required this.onNext,
    required this.previousLabel,
    required this.nextLabel,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final String previousLabel;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final colors = CalendarColors.of(context);
    Widget button(IconData icon, VoidCallback onTap, String label) => Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 34,
          child: Icon(icon, size: 22, color: colors.accent),
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: t.isClear ? colors.fill : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.chevron_left_rounded, onPrevious, previousLabel),
          button(Icons.chevron_right_rounded, onNext, nextLabel),
        ],
      ),
    );
  }
}
