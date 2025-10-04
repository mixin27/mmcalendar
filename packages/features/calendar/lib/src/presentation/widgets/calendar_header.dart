import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

class CalendarHeader extends StatelessWidget {
  final DateTime currentMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onTodayTap;
  final VoidCallback onMonthYearTap;
  final Language language;

  const CalendarHeader({
    super.key,
    required this.currentMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTodayTap,
    required this.onMonthYearTap,
    this.language = Language.english,
  });

  @override
  Widget build(BuildContext context) {
    final myanmarDate = MyanmarCalendar.fromWestern(
      currentMonth.year,
      currentMonth.month,
      1,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          // Navigation buttons
          IconButton.filled(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: onPreviousMonth,
            tooltip: 'Previous Month',
            style: IconButton.styleFrom(
              backgroundColor: context.colorScheme.surfaceContainerHighest,
              foregroundColor: context.colorScheme.onSurface,
            ),
          ),

          // Month and year display (tappable)
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onMonthYearTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      // Myanmar month and year
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            myanmarDate.formatMyanmar('&M &y'),
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 20,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Western month and year
                      Text(
                        currentMonth.format('MMMM yyyy'),
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
            tooltip: 'Next Month',
            style: IconButton.styleFrom(
              backgroundColor: context.colorScheme.surfaceContainerHighest,
              foregroundColor: context.colorScheme.onSurface,
            ),
          ),

          const SizedBox(width: 4),

          // Today button
          IconButton.filledTonal(
            icon: const Icon(Icons.today, size: 20),
            onPressed: onTodayTap,
            tooltip: 'Go to Today',
          ),
        ],
      ),
    );
  }
}
