import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

class CalendarAppBar extends StatelessWidget {
  final Language language;
  final DateTime displayedMonth;
  final VoidCallback onStudioTap;
  final VoidCallback onSearchTap;
  final VoidCallback onCalendarTap;

  const CalendarAppBar({
    super.key,
    required this.onStudioTap,
    required this.onSearchTap,
    required this.onCalendarTap,
    required this.displayedMonth,
    this.language = Language.myanmar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complete = MyanmarCalendar.getCompleteDate(
      DateTime(displayedMonth.year, displayedMonth.month, 1),
    );
    final myanmarTitle = MyanmarCalendar.formatMyanmar(
      complete.myanmar,
      pattern: '&M · &y',
      language: language,
    );
    final myanmarYear = MyanmarCalendar.formatMyanmar(
      complete.myanmar,
      pattern: '&y',
      language: language,
    );
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onCalendarTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                myanmarTitle,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontFamily: 'Noto Sans Myanmar',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 22),
                          ],
                        ),
                        Text(
                          '${MaterialLocalizations.of(context).formatMonthYear(displayedMonth)} · မြန်မာနှစ် $myanmarYear',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, size: 27),
                onPressed: onSearchTap,
                tooltip: 'Search date',
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined, size: 25),
                onPressed: onCalendarTap,
                tooltip: 'Choose month',
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                icon: const Icon(Icons.edit_calendar_outlined, size: 25),
                onPressed: onStudioTap,
                tooltip: 'Open Calendar Studio',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
