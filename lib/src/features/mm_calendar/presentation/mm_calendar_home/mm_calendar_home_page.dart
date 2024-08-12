import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:iconly/iconly.dart';
import 'package:mmcalendar/src/routes/routes.dart';
import 'package:mmcalendar/src/utils/dates.dart';
import 'package:table_calendar/table_calendar.dart';

@RoutePage()
class MmCalendarHomePage extends StatefulWidget {
  const MmCalendarHomePage({super.key});

  @override
  State<MmCalendarHomePage> createState() => _MmCalendarHomePageState();
}

class _MmCalendarHomePageState extends State<MmCalendarHomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusDay = DateTime.now();

  void _handleHeaderTap(DateTime date) async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(3000),
      initialDate: date,
    );

    if (selectedDate == null) return;

    setState(() {
      _selectedDay = selectedDate;
      _focusDay = selectedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MM Calendar'),
        actions: [
          IconButton(
            onPressed: () => context.router.push(const AppSettingsRoute()),
            icon: const Icon(IconlyLight.setting),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TableCalendar(
              locale: context.locale.languageCode,
              shouldFillViewport: true,
              daysOfWeekHeight: 50,
              firstDay: DateTime.utc(1900, 01, 01),
              lastDay: DateTime.utc(3000, 01, 01),
              focusedDay: _focusDay,
              calendarFormat: _calendarFormat,
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
              onHeaderTapped: _handleHeaderTap,
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusDay = focusedDay;
                });

                context.router.push(MmCalendarDetailRoute(date: _selectedDay));
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusDay = focusedDay;
                });
              },
              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  final text = DateFormat().add_E().format(day);

                  if (day.weekday == DateTime.saturday ||
                      day.weekday == DateTime.sunday) {
                    return Center(
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    );
                  }

                  return Center(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  );
                },
                defaultBuilder: (context, day, focusedDay) {
                  final enDay = DateFormat().add_d().format(day);

                  final moonPhase = day.mmDate.format('p');
                  final fortnightDay = day.mmDate.format('f');

                  final mmDay = fortnightDay.isEmpty ? moonPhase : fortnightDay;

                  final holidays = day.mmDate.holidays;

                  return Container(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.2),
                        ),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Column(
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
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              enDay,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Expanded(
                            child: Text(
                              mmDay,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontSize: 12),
                            ),
                          ),
                          if (fortnightDay.isNotEmpty) ...[
                            Expanded(
                              child: Text(
                                moonPhase,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(fontSize: 10),
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
