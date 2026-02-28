import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

Future<DateTime?> showMyanmarDatePickerDialog({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  Language? language,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => MyanmarDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(1900, 1, 1),
      lastDate: lastDate ?? DateTime(2100, 12, 31),
      language: language ?? MyanmarCalendar.currentLanguage,
    ),
  );
}

class MyanmarDatePickerDialog extends StatefulWidget {
  const MyanmarDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.language,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Language language;

  @override
  State<MyanmarDatePickerDialog> createState() =>
      _MyanmarDatePickerDialogState();
}

class _MyanmarDatePickerDialogState extends State<MyanmarDatePickerDialog> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gridDates = AppDateUtils.getCalendarGridDates(
      _visibleMonth,
      firstDayOfWeek: 1,
    );
    final monthAnchor = MyanmarCalendar.getCompleteDate(
      DateTime(_visibleMonth.year, _visibleMonth.month, 15),
    );
    final myanmarMonthLabel = MyanmarCalendar.formatMyanmar(
      monthAnchor.myanmar,
      pattern: '&M &y',
      language: widget.language,
    );
    final canGoPrevious = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    ).isAfter(DateTime(widget.firstDate.year, widget.firstDate.month, 1));
    final canGoNext = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    ).isBefore(DateTime(widget.lastDate.year, widget.lastDate.month, 1));

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: canGoPrevious ? _previousMonth : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _visibleMonth.format('MMMM yyyy'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          myanmarMonthLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: canGoNext ? _nextMonth : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(7, (index) {
                  final weekday = (1 + index) % 7;
                  return Expanded(
                    child: Text(
                      TranslationService.getShortWeekdayName(
                        weekday,
                        widget.language,
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gridDates.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.95,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final date = gridDates[index];
                  final completeDate = MyanmarCalendar.getCompleteDate(date);
                  final isInMonth = date.month == _visibleMonth.month;
                  final isSelected = date.isSameDay(widget.initialDate);
                  final isToday = date.isSameDay(DateTime.now());
                  final isDisabled = !_isSelectable(date);
                  final dayStyle = Theme.of(context).textTheme.bodyMedium;
                  final myanmarDay = MyanmarCalendar.formatMyanmar(
                    completeDate.myanmar,
                    pattern: '&f',
                    language: widget.language,
                  );

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: isDisabled
                        ? null
                        : () => Navigator.of(context).pop(date.startOfDay),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        border: isToday
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 4,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${date.day}',
                            style: dayStyle?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDisabled
                                  ? Theme.of(context).disabledColor
                                  : isInMonth
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 2),
                          CompactMoonPhaseIndicator(
                            moonPhase: completeDate.moonPhase,
                            fortnightDay: completeDate.fortnightDay,
                            size: 10,
                          ),
                          Text(
                            myanmarDay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 9,
                                  color: isDisabled
                                      ? Theme.of(context).disabledColor
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(DateTime.now().startOfDay),
                    child: const Text('Today'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSelectable(DateTime date) {
    return !date.isBefore(widget.firstDate.startOfDay) &&
        !date.isAfter(widget.lastDate.endOfDay);
  }

  void _previousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    });
  }
}
