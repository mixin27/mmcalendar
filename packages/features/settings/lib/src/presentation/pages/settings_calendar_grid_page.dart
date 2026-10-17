import 'package:calendar/calendar.dart' show CalendarGrid;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../widgets/settings_widgets.dart';

/// Names and one-line descriptions for each grid style.
extension CalendarGridStyleLabel on CalendarGridStyle {
  String get title => switch (this) {
    CalendarGridStyle.detailed => 'Detailed',
    CalendarGridStyle.clean => 'Clean',
    CalendarGridStyle.classic => 'Classic',
    CalendarGridStyle.detailedV2 => 'Detailed v2',
    CalendarGridStyle.lunarFirst => 'Lunar first',
    CalendarGridStyle.minimal => 'Minimal',
    CalendarGridStyle.moonStrip => 'Moon strip',
    CalendarGridStyle.agenda => 'Agenda',
    CalendarGridStyle.classicPrint => 'Classic print',
  };

  String get description => switch (this) {
    CalendarGridStyle.detailed =>
      'Lunar day, holiday name, moon and events in every day.',
    CalendarGridStyle.clean => 'Numbers first; the moon only on moon days.',
    CalendarGridStyle.classic => 'The original tiles and coloured dots.',
    CalendarGridStyle.detailedV2 =>
      'Detailed, calmer: no lines, the moon only on moon days.',
    CalendarGridStyle.lunarFirst =>
      'The lunar day large, the date small in the corner.',
    CalendarGridStyle.minimal => 'The date and one status dot.',
    CalendarGridStyle.moonStrip => 'Tonight’s moon in every day.',
    CalendarGridStyle.agenda => 'Event titles and holidays inside the days.',
    CalendarGridStyle.classicPrint => 'A ruled table like a wall calendar.',
  };
}

/// Settings › Display › Calendar grid: every style as a live preview of
/// this month, two or three to a row.
class SettingsCalendarGridPage extends StatelessWidget {
  const SettingsCalendarGridPage({super.key});

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
          LayoutBuilder(
            builder: (context, box) => GridView.count(
              crossAxisCount: box.maxWidth >= 560 ? 3 : 2,
              // The page already handles the safe area.
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .68,
              children: [
                for (final style in CalendarGridStyle.values)
                  _GridChoice(
                    key: ValueKey('grid-style-${style.name}'),
                    title: style.title,
                    description: style.description,
                    isDefault: style == CalendarGridStyle.defaultStyle,
                    selected: style == current,
                    preview: _Preview(style: style, month: month, dates: dates),
                    onTap: () => context.read<SettingsBloc>().add(
                      ChangeCalendarGridStyle(style),
                    ),
                  ),
              ],
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
    super.key,
    required this.title,
    required this.description,
    required this.isDefault,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool isDefault;
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
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColoredBox(color: t.background, child: preview),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: t.accent,
                      ),
                  ],
                ),
                Text(
                  isDefault ? 'Default · $description' : description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: t.secondaryLabel,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// This month at phone size, scaled down to fit the card, with a day
/// selected so the selection style shows.
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
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = today.day <= 20
        ? today.add(const Duration(days: 5))
        : today.subtract(const Duration(days: 5));
    return ExcludeSemantics(
      child: IgnorePointer(
        child: FittedBox(
          // The whole week must show, Sunday to Saturday.
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 360,
            height: rows * 78,
            child: MediaQuery.withNoTextScaling(
              child: CalendarGrid(
                gridDates: dates,
                currentMonth: month,
                today: today,
                selectedDate: selected,
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
