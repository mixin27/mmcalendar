import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mmcalendar/src/shared/shared.dart';
import 'package:table_calendar/table_calendar.dart';

class LanscapeCalendarView extends HookConsumerWidget {
  const LanscapeCalendarView({
    super.key,
    required this.selectedDay,
    required this.focusedDay,
    this.calendarFormat = CalendarFormat.month,
    this.onHeaderTapped,
    this.onFormatChanged,
    this.onPageChanged,
    this.selectedDayPredicate,
    this.onDaySelected,
  });

  final DateTime selectedDay;
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;
  final void Function(DateTime)? onHeaderTapped;
  final void Function(CalendarFormat)? onFormatChanged;
  final void Function(DateTime)? onPageChanged;
  final bool Function(DateTime)? selectedDayPredicate;
  final void Function(DateTime, DateTime)? onDaySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mmCalendar = ref.watch(mmCalendarProvider);
    final config = ref.watch(mmCalendarConfigControllerProvider);

    return TableCalendar(
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      locale: context.locale.languageCode,
      shouldFillViewport: true,
      daysOfWeekHeight: 50,
      firstDay: DateTime.utc(1900, 01, 01),
      lastDay: DateTime.utc(3000, 01, 01),
      focusedDay: focusedDay,
      calendarFormat: calendarFormat,
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary,
        ),
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      onHeaderTapped: onHeaderTapped,
      onFormatChanged: onFormatChanged,
      selectedDayPredicate: selectedDayPredicate ??
          (day) {
            return isSameDay(selectedDay, day);
          },
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      calendarBuilders: CalendarBuilders(
        dowBuilder: (context, day) {
          final text = DateFormat().add_E().format(day);

          if (day.weekday == DateTime.saturday ||
              day.weekday == DateTime.sunday) {
            return Center(
              child: Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          return Center(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          );
        },
        defaultBuilder: (context, day, focusedDay) {
          final enDay = DateFormat().add_d().format(day);

          final myanmarDate = mmCalendar.fromDateTime(day, config: config);

          final isWeekend = myanmarDate.isWeekend();

          final moonPhase = myanmarDate.format('p');
          final fortnightDay = myanmarDate.format('f');

          final mmDay = fortnightDay.isEmpty ? moonPhase : fortnightDay;

          final holidays = myanmarDate.holidays;

          return Container(
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: isWeekend
                    ? Theme.of(context).colorScheme.errorContainer
                    : null,
                border: Border.all(
                  color: isWeekend
                      ? Theme.of(context).colorScheme.error.withOpacity(0.2)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.2),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (holidays.isNotEmpty) ...[
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Center(
                      child: Text(
                        enDay,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                  if (fortnightDay.isNotEmpty) ...[
                    Expanded(
                      child: Center(
                        child: Text(
                          moonPhase,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Center(
                      child: Text(
                        mmDay,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
