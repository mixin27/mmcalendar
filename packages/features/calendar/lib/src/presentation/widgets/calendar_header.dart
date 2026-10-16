import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

/// One compact row above the grid: the month title (tap for the month
/// picker) with the Myanmar months and year beneath, then Today, previous /
/// next and Calendar Studio. Swiping the grid also changes the month.
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Choose month',
              child: InkWell(
                onTap: onMonthYearTap,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              MaterialLocalizations.of(
                                context,
                              ).formatMonthYear(currentMonth),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.3,
                                height: 1.25,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: colors.primary,
                          ),
                        ],
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
          if (onToday != null)
            TextButton(
              onPressed: onToday,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: colors.onSurface.withValues(alpha: .06),
                shape: const StadiumBorder(),
              ),
              child: Text(l10n?.today ?? 'Today'),
            ),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPreviousMonth,
            color: colors.primary,
            visualDensity: VisualDensity.compact,
            tooltip: l10n?.previous_month ?? 'Previous Month',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onNextMonth,
            color: colors.primary,
            visualDensity: VisualDensity.compact,
            tooltip: l10n?.next_month ?? 'Next Month',
          ),
          if (onStudioTap != null)
            IconButton(
              icon: const Icon(Icons.edit_calendar_outlined),
              onPressed: onStudioTap,
              color: colors.primary,
              visualDensity: VisualDensity.compact,
              tooltip: 'Calendar Studio',
            ),
        ],
      ),
    );
  }

  String _buildMyanmarMonthLabel(List<CompleteDate> dates) {
    final months = <String>[];
    for (final date in dates) {
      final month = MyanmarCalendar.formatMyanmar(date.myanmar, pattern: '&M');
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
      final year = MyanmarCalendar.formatMyanmar(date.myanmar, pattern: '&y');
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
