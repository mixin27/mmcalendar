import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart'
    show
        CalendarLanguageContext,
        showAppMyanmarDatePicker,
        showAppMyanmarMultiDatePicker;
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' hide ContextExtension;

import '../../domain/entities/recurrence_rule.dart';

/// What the repeat sheet returns: the rule (null for "Never") and, for a
/// weekly timetable, each weekday's own time (empty for one time for all).
typedef RepeatChoice = ({RecurrenceRule? rule, Map<int, DateTime> dayTimes});

/// Weekdays in the order the sheet shows them, Sunday first.
const _weekdays = [
  DateTime.sunday,
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
];

/// [type]'s name in the app language: "Weekly", "အပတ်စဉ်".
String repeatTypeName(BuildContext context, RecurrenceType type) {
  final l10n = AppLocalizations.of(context);
  return switch (type) {
    RecurrenceType.none => l10n?.never ?? 'Never',
    RecurrenceType.daily => l10n?.repeatDaily ?? 'Daily',
    RecurrenceType.weekly => l10n?.repeatWeekly ?? 'Weekly',
    RecurrenceType.monthly => l10n?.repeatMonthly ?? 'Monthly',
    RecurrenceType.yearly => l10n?.repeatYearly ?? 'Yearly',
    RecurrenceType.dates => l10n?.repeatSpecificDates ?? 'Specific dates',
  };
}

/// "Every week · Wed, Thu · until 20 Dec", in the calendar language.
String repeatSummary(
  BuildContext context,
  RecurrenceRule? rule, {
  Map<int, DateTime> dayTimes = const {},
}) {
  final l10n = AppLocalizations.of(context);
  final format = context.calendarFormat;
  if (rule == null || rule.type == RecurrenceType.none) {
    return l10n?.never ?? 'Never';
  }
  if (rule.type == RecurrenceType.dates) {
    final dates = [...?rule.dates]..sort();
    final shown = [for (final d in dates.take(3)) format.shortDate(d)];
    return [
      l10n?.repeatDatesCount(dates.length) ?? '${dates.length} dates',
      shown.join(', ') + (dates.length > 3 ? '…' : ''),
    ].join(' · ');
  }
  final parts = <String>[];
  if (rule.type == RecurrenceType.weekly) {
    parts.add(
      rule.interval > 1
          ? l10n?.repeatEveryWeeks(rule.interval) ??
                'Every ${rule.interval} weeks'
          : l10n?.repeatEveryWeek ?? 'Every week',
    );
    final days = rule.daysOfWeek ?? const <int>[];
    if (days.isNotEmpty) {
      parts.add(
        [
          for (final day in _weekdays)
            if (days.contains(day)) format.weekdayOf(day, short: true),
        ].join(', '),
      );
    }
  } else {
    parts.add(repeatTypeName(context, rule.type));
  }
  if (rule.endDate != null) {
    final end = format.shortDate(rule.endDate!);
    parts.add(l10n?.repeatUntil(end) ?? 'until $end');
  } else if (rule.occurrenceCount != null) {
    parts.add(
      l10n?.repeatTimes(rule.occurrenceCount!) ??
          '${rule.occurrenceCount} times',
    );
  }
  return parts.join(' · ');
}

enum _Ends { never, onDate, after }

/// How often an event repeats: daily to yearly; for weekly, the weekdays,
/// every how many weeks and (for a new timed event) a time for each day;
/// and when it ends.
class RepeatSheet extends StatefulWidget {
  const RepeatSheet({
    super.key,
    required this.rule,
    required this.dayTimes,
    required this.startDate,
    required this.time,
    required this.allowTimePerDay,
  });

  final RecurrenceRule? rule;
  final Map<int, DateTime> dayTimes;

  /// The event's date: the default weekday and the earliest end date.
  final DateTime startDate;

  /// The event's time; null for an all-day event, which has no per-day
  /// times.
  final DateTime? time;

  /// Whether days may have their own times (new events only: an existing
  /// series isn't split).
  final bool allowTimePerDay;

  @override
  State<RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<RepeatSheet> {
  late var _type = widget.rule?.type ?? RecurrenceType.none;
  late var _days = {...?widget.rule?.daysOfWeek};
  late var _interval = widget.rule?.interval ?? 1;
  late var _ends = widget.rule?.endDate != null
      ? _Ends.onDate
      : widget.rule?.occurrenceCount != null
      ? _Ends.after
      : _Ends.never;
  late var _endDate =
      widget.rule?.endDate ??
      DateTime(
        widget.startDate.year,
        widget.startDate.month + 3,
        widget.startDate.day,
      );
  late var _count = widget.rule?.occurrenceCount ?? 10;
  late final _dayTimes = {...widget.dayTimes};
  late var _dates = [...?widget.rule?.dates]..sort();
  late var _perDay = widget.dayTimes.isNotEmpty;

  bool get _weekly => _type == RecurrenceType.weekly;
  bool get _onDates => _type == RecurrenceType.dates;
  bool get _canTimePerDay =>
      widget.allowTimePerDay &&
      widget.time != null &&
      _weekly &&
      _days.length > 1;

  RepeatChoice get _choice {
    if (_type == RecurrenceType.none) {
      return (rule: null, dayTimes: const <int, DateTime>{});
    }
    if (_onDates) {
      return (
        rule: RecurrenceRule(type: RecurrenceType.dates, dates: _dates),
        dayTimes: const <int, DateTime>{},
      );
    }
    final rule = RecurrenceRule(
      type: _type,
      interval: _weekly ? _interval : 1,
      daysOfWeek: _weekly ? ([..._days]..sort()) : null,
      endDate: _ends == _Ends.onDate ? _endDate : null,
      occurrenceCount: _ends == _Ends.after ? _count : null,
    );
    return (
      rule: rule,
      dayTimes: _canTimePerDay && _perDay
          ? {for (final day in _days) day: _dayTimes[day] ?? widget.time!}
          : const <int, DateTime>{},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = context.calendarFormat;
    final t = context.tokens;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppGroup(
            children: [
              for (final type in RecurrenceType.values)
                AppRow(
                  key: ValueKey('repeat-type-${type.name}'),
                  title: repeatTypeName(context, type),
                  selected: _type == type,
                  onTap: () {
                    setState(() {
                      _type = type;
                      if (_weekly && _days.isEmpty) {
                        _days = {widget.startDate.weekday};
                      }
                    });
                    // Straight to the calendar the first time.
                    if (_onDates && _dates.isEmpty) _pickDates();
                  },
                ),
            ],
          ),
          if (_weekly) ...[
            const SizedBox(height: 18),
            AppGroupLabel(l10n?.repeatOn ?? 'On'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final day in _weekdays)
                  AppChip(
                    key: ValueKey('repeat-day-$day'),
                    label: format.weekdayOf(day, short: true),
                    selected: _days.contains(day),
                    // A weekly event needs at least one day.
                    onSelected: (on) => setState(() {
                      if (on) {
                        _days.add(day);
                      } else if (_days.length > 1) {
                        _days.remove(day);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AppGroup(
              children: [
                AppRow(
                  title: _interval > 1
                      ? l10n?.repeatEveryWeeks(_interval) ??
                            'Every $_interval weeks'
                      : l10n?.repeatEveryWeek ?? 'Every week',
                  trailing: _Stepper(
                    keyPrefix: 'repeat-interval',
                    onMinus: _interval > 1
                        ? () => setState(() => _interval--)
                        : null,
                    onPlus: _interval < 8
                        ? () => setState(() => _interval++)
                        : null,
                  ),
                ),
              ],
            ),
          ],
          if (_onDates) ...[
            const SizedBox(height: 18),
            AppGroup(
              children: [
                AppRow(
                  key: const ValueKey('repeat-choose-dates'),
                  icon: Icons.date_range_outlined,
                  iconColor: t.accent,
                  title: l10n?.repeatChooseDates ?? 'Choose dates',
                  value: _dates.isEmpty
                      ? null
                      : l10n?.repeatDatesCount(_dates.length) ??
                            '${_dates.length} dates',
                  chevron: true,
                  onTap: _pickDates,
                ),
              ],
            ),
            if (_dates.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final date in _dates)
                    InputChip(
                      key: ValueKey('repeat-date-${date.toIso8601String()}'),
                      label: Text(
                        '${format.weekday(date, short: true)} '
                        '${format.shortDate(date)}',
                      ),
                      onDeleted: () => setState(() => _dates.remove(date)),
                    ),
                ],
              ),
            ],
          ],
          if (_type != RecurrenceType.none && !_onDates) ...[
            const SizedBox(height: 18),
            AppGroupLabel(l10n?.repeatEnds ?? 'Ends'),
            AppSegmented<_Ends>(
              segments: {
                _Ends.never: l10n?.never ?? 'Never',
                _Ends.onDate: l10n?.repeatEndsOnDate ?? 'On a date',
                _Ends.after: l10n?.repeatEndsAfter ?? 'After',
              },
              value: _ends,
              onChanged: (value) => setState(() => _ends = value),
            ),
            if (_ends != _Ends.never) ...[
              const SizedBox(height: 12),
              AppGroup(
                children: [
                  if (_ends == _Ends.onDate)
                    AppRow(
                      key: const ValueKey('repeat-end-date'),
                      icon: Icons.event_busy_outlined,
                      iconColor: t.holiday,
                      title: l10n?.repeatEnds ?? 'Ends',
                      value:
                          '${format.shortDate(_endDate)} '
                          '${format.number(_endDate.year)}',
                      chevron: true,
                      onTap: _pickEndDate,
                    )
                  else
                    AppRow(
                      title: l10n?.repeatTimes(_count) ?? '$_count times',
                      trailing: _Stepper(
                        keyPrefix: 'repeat-count',
                        onMinus: _count > 1
                            ? () => setState(() => _count--)
                            : null,
                        onPlus: _count < 500
                            ? () => setState(() => _count++)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ],
          if (_canTimePerDay) ...[
            const SizedBox(height: 18),
            AppGroup(
              footer: _perDay
                  ? l10n?.repeatTimePerDayNote ??
                        'Days with different times are saved as one weekly '
                            'event per time.'
                  : null,
              children: [
                AppRow.toggle(
                  key: const ValueKey('repeat-time-per-day'),
                  icon: Icons.schedule,
                  iconColor: t.accent,
                  title: l10n?.repeatTimePerDay ?? 'A time for each day',
                  value: _perDay,
                  onChanged: (on) => setState(() => _perDay = on),
                ),
                if (_perDay)
                  for (final day in _weekdays)
                    if (_days.contains(day))
                      AppRow(
                        key: ValueKey('repeat-day-time-$day'),
                        title: format.weekdayOf(day),
                        value: TimeOfDay.fromDateTime(
                          _dayTimes[day] ?? widget.time!,
                        ).format(context),
                        chevron: true,
                        onTap: () => _pickDayTime(day),
                      ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          AppButton(
            key: const ValueKey('repeat-done'),
            label: l10n?.done ?? 'Done',
            // Specific dates need at least one date.
            onPressed: _onDates && _dates.isEmpty
                ? null
                : () => Navigator.pop(context, _choice),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDates() async {
    final picked = await showAppMyanmarMultiDatePicker(
      context: context,
      initialDates: _dates.isEmpty ? [widget.startDate] : _dates,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _dates = [...picked]..sort());
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showAppMyanmarDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: widget.startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _endDate = picked);
  }

  Future<void> _pickDayTime(int day) async {
    final current = _dayTimes[day] ?? widget.time!;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked != null && mounted) {
      setState(
        () => _dayTimes[day] = DateTime(
          current.year,
          current.month,
          current.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.keyPrefix, this.onMinus, this.onPlus});

  final String keyPrefix;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        key: ValueKey('$keyPrefix-minus'),
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: onMinus,
      ),
      IconButton(
        key: ValueKey('$keyPrefix-plus'),
        icon: const Icon(Icons.add_circle_outline),
        onPressed: onPlus,
      ),
    ],
  );
}
