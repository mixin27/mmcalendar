import 'package:calendar/calendar.dart' show CalendarGrid;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../widgets/settings_widgets.dart';

/// Settings › Display › Calendar grid: pick how the month looks, with a
/// live preview of this month in each style.
class SettingsCalendarGridPage extends StatelessWidget {
  const SettingsCalendarGridPage({super.key});

  static const _choices = [
    (
      CalendarGridStyle.detailed,
      'Detailed',
      'Default. Lunar day, holiday name, moon and event titles in every day.',
    ),
    (
      CalendarGridStyle.clean,
      'Clean',
      'Calm. Numbers first; the moon only on full and new moon days.',
    ),
    (
      CalendarGridStyle.classic,
      'Classic',
      'The original tiles and coloured dots.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsSubPage(
      title: 'Calendar grid',
      previousTitle: 'Display',
      builder: (context, settings) {
        final current = settings.calendarGridStyle;
        final month = DateTime.now();
        final dates = AppDateUtils.getCalendarGridDates(
          month,
          firstDayOfWeek: 1,
        ).map(MyanmarCalendar.getCompleteDate).toList(growable: false);
        return [
          for (final (style, title, description) in _choices)
            _GridChoice(
              title: title,
              description: description,
              selected: style == current,
              preview: _Preview(style: style, month: month, dates: dates),
              onTap: () => context.read<SettingsBloc>().add(
                ChangeCalendarGridStyle(style),
              ),
            ),
          Text(
            'Every style fits the screen: rows take the height that is '
            'left above the day sheet.',
            style: TextStyle(
              fontSize: 12.5,
              color: context.tokens.secondaryLabel,
            ),
          ),
        ];
      },
    );
  }
}

class _GridChoice extends StatelessWidget {
  const _GridChoice({
    required this.title,
    required this.description,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      selected: selected,
      button: true,
      label: '$title. $description',
      excludeSemantics: true,
      child: Material(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.groupRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(t.groupRadius),
              border: Border.all(
                color: selected ? t.accent : Colors.transparent,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 132, child: preview),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: t.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_rounded, color: t.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// This month at phone size, scaled down to fit the row.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.style,
    required this.month,
    required this.dates,
  });

  final CalendarGridStyle style;
  final DateTime month;
  final List<CompleteDate> dates;

  @override
  Widget build(BuildContext context) {
    final rows = CalendarGrid.visibleRows(dates, month).length;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 360,
            height: rows * 68,
            child: MediaQuery.withNoTextScaling(
              child: CalendarGrid(
                gridDates: dates,
                currentMonth: month,
                today: DateUtils.dateOnly(DateTime.now()),
                gridStyle: style,
                onDateTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
  }
}
