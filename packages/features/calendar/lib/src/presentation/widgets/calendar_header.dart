import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

class CalendarHeader extends StatelessWidget {
  final DateTime currentMonth;
  final List<CompleteDate>? monthDates;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onTodayTap;
  final VoidCallback onMonthYearTap;
  final Language language;
  final bool showShanCalendar;

  const CalendarHeader({
    super.key,
    required this.currentMonth,
    this.monthDates,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTodayTap,
    required this.onMonthYearTap,
    this.language = Language.english,
    this.showShanCalendar = true,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filled(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: onPreviousMonth,
                tooltip:
                    AppLocalizations.of(context)?.previous_month ??
                    'Previous Month',
                style: IconButton.styleFrom(
                  backgroundColor: context.colorScheme.surfaceContainerHighest,
                  foregroundColor: context.colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onMonthYearTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  MyanmarCalendar.currentLanguage ==
                                              Language.shan &&
                                          showShanCalendar
                                      ? '$monthLabel $shanYearLabel'
                                      : '$monthLabel $myanmarYearLabel',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 20,
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentMonth.format('MMMM yyyy'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton.filled(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: onNextMonth,
                tooltip:
                    AppLocalizations.of(context)?.next_month ?? 'Next Month',
                style: IconButton.styleFrom(
                  backgroundColor: context.colorScheme.surfaceContainerHighest,
                  foregroundColor: context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: onTodayTap,
              icon: const Icon(Icons.today, size: 16),
              label: Text(AppLocalizations.of(context)?.today ?? 'Today'),
            ),
          ),
        ],
      ),
    );
  }

  String _buildMyanmarMonthLabel(List<CompleteDate> dates) {
    final months = <String>[];
    for (final date in dates) {
      final month = date.formatMyanmar(pattern: '&M');
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
      final year = date.formatMyanmar(pattern: '&y');
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

    final firstYear = FormatService().translateNumbers(
      years.first.toString(),
      language: Language.shan,
    );
    if (years.length == 1) {
      return firstYear;
    }

    final lastYear = FormatService().translateNumbers(
      years.last.toString(),
      language: Language.shan,
    );
    return '$firstYear - $lastYear';
  }
}
