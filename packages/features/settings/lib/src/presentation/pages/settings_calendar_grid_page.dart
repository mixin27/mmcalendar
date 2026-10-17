import 'package:calendar/calendar.dart'
    show
        CalendarColors,
        CalendarGrid,
        CalendarThemeLook,
        CalendarThemeMotif,
        CalendarThemeScope,
        CalendarThemedRegion;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

import '../../domain/entities/app_settings.dart';
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
    CalendarGridStyle.tiles => 'Tiles',
    CalendarGridStyle.moonlight => 'Moonlight',
    CalendarGridStyle.split => 'Split',
    CalendarGridStyle.poster => 'Poster',
    CalendarGridStyle.moonRing => 'Moon ring',
    CalendarGridStyle.astrology => 'Astrology',
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
    CalendarGridStyle.tiles => 'Every day a card; holidays and Sabbath tinted.',
    CalendarGridStyle.moonlight => 'Days glow brighter toward the full moon.',
    CalendarGridStyle.split => 'The date and the lunar day, split diagonally.',
    CalendarGridStyle.poster => 'Big, bold numbers you can read from afar.',
    CalendarGridStyle.moonRing =>
      'A ring around each date fills with moonlight.',
    CalendarGridStyle.astrology => 'Astrological days and holidays as tags.',
  };
}

/// Names and one-line descriptions for each grid theme.
extension CalendarGridThemeLabel on CalendarGridTheme {
  String get title => switch (this) {
    CalendarGridTheme.app => 'App colours',
    CalendarGridTheme.pagoda => 'Pagoda',
    CalendarGridTheme.jade => 'Jade',
    CalendarGridTheme.lacquer => 'Lacquer',
    CalendarGridTheme.thadingyut => 'Thadingyut',
    CalendarGridTheme.thingyan => 'Thingyan',
    CalendarGridTheme.botanical => 'Botanical',
    CalendarGridTheme.monsoon => 'Monsoon',
    CalendarGridTheme.tidewater => 'Tidewater',
    CalendarGridTheme.morningPour => 'Morning Pour',
    CalendarGridTheme.deepField => 'Deep Field',
    CalendarGridTheme.moonlight => 'Moonlight',
    CalendarGridTheme.nightChart => 'Night Chart',
  };

  String get description => switch (this) {
    CalendarGridTheme.app => 'The app’s own colours and accent.',
    CalendarGridTheme.pagoda => 'Temple cream, maroon and pagoda gold.',
    CalendarGridTheme.jade => 'Jade green on cool white, with a seal.',
    CalendarGridTheme.lacquer => 'Black lacquer, cinnabar and gold leaf.',
    CalendarGridTheme.thadingyut => 'Lantern paper by day, indigo by night.',
    CalendarGridTheme.thingyan => 'Splash blue and padauk yellow.',
    CalendarGridTheme.botanical => 'Pressed-leaf greens on herbarium paper.',
    CalendarGridTheme.monsoon => 'Rain-season slate with a rust accent.',
    CalendarGridTheme.tidewater => 'Sea glass and deep teal.',
    CalendarGridTheme.morningPour => 'Coffee and cream for early risers.',
    CalendarGridTheme.deepField => 'Lavender dusk, or deep space at night.',
    CalendarGridTheme.moonlight => 'Silver-blue and moon gold.',
    CalendarGridTheme.nightChart => 'Violet ink and antique gold.',
  };
}

enum _Tab { layout, theme }

/// Settings › Display › Calendar grid: the layout (how each day is drawn)
/// and the theme (paper, ink, typeface and motif), each as live previews
/// of this month, two or three to a row.
class SettingsCalendarGridPage extends StatefulWidget {
  const SettingsCalendarGridPage({super.key});

  @override
  State<SettingsCalendarGridPage> createState() =>
      _SettingsCalendarGridPageState();
}

class _SettingsCalendarGridPageState extends State<SettingsCalendarGridPage> {
  var _tab = _Tab.layout;

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
        final tabs = AppSegmented<_Tab>(
          segments: const {_Tab.layout: 'Layout', _Tab.theme: 'Theme'},
          value: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
        );
        if (_tab == _Tab.theme) {
          return [tabs, ..._themeChoices(context, settings, month, dates)];
        }
        return [
          tabs,
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

  List<Widget> _themeChoices(
    BuildContext context,
    AppSettingsEntity settings,
    DateTime month,
    List<CompleteDate> dates,
  ) {
    final brightness = Theme.of(context).brightness;
    return [
      LayoutBuilder(
        builder: (context, box) => GridView.count(
          crossAxisCount: box.maxWidth >= 560 ? 3 : 2,
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: .62,
          children: [
            for (final theme in CalendarGridTheme.values)
              _GridChoice(
                key: ValueKey('grid-theme-${theme.name}'),
                title: theme.title,
                description: theme.description,
                isDefault: theme == CalendarGridTheme.defaultTheme,
                selected: theme == settings.calendarGridTheme,
                swatches: switch (CalendarThemeLook.forTheme(theme)) {
                  final look? => [
                    look.of(brightness).paper,
                    look.of(brightness).accent,
                    look.of(brightness).holiday,
                    look.of(brightness).moon,
                  ],
                  null => const [],
                },
                preview: _ThemePreview(
                  theme: theme,
                  showMotif: settings.showGridMotif,
                  style: settings.calendarGridStyle,
                  month: month,
                  dates: dates,
                ),
                onTap: () => context.read<SettingsBloc>().add(
                  ChangeCalendarGridTheme(theme),
                ),
              ),
          ],
        ),
      ),
      AppGroup(
        footer:
            'A theme colours the month header, weekday row and grid, and '
            'works with every layout. The day sheet keeps the app’s colours.',
        children: [
          AppRow.toggle(
            key: const ValueKey('grid-theme-motif'),
            icon: Icons.auto_awesome_outlined,
            iconColor: SettingsIconColors.indigo,
            title: 'Show motif',
            value: settings.showGridMotif,
            onChanged: (value) => context.read<SettingsBloc>().add(
              ToggleDisplayPreference(StorageKeys.calendarGridMotif, value),
            ),
          ),
        ],
      ),
    ];
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
    this.swatches = const [],
  });

  final String title;
  final List<Color> swatches;
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
                    for (final color in swatches)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsetsDirectional.only(start: 3),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: t.separator, width: .5),
                        ),
                      ),
                    if (selected) const SizedBox(width: 4),
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

/// This month in [theme]: the month title with the theme's typeface and
/// motif over the grid in the chosen layout, scaled to fit the card.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
    required this.theme,
    required this.showMotif,
    required this.style,
    required this.month,
    required this.dates,
  });

  final CalendarGridTheme theme;
  final bool showMotif;
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
    final title = context.calendarFormat.monthYear(month);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: CalendarThemeScope(
          theme: theme,
          showMotif: showMotif,
          child: Builder(
            builder: (context) {
              final colors = CalendarColors.of(context);
              return ColoredBox(
                color: colors.paper ?? context.tokens.background,
                child: CalendarThemedRegion(
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 360,
                      height: 52 + rows * 78,
                      child: MediaQuery.withNoTextScaling(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 52,
                              child: Stack(
                                children: [
                                  const PositionedDirectional(
                                    top: 0,
                                    end: 0,
                                    child: CalendarThemeMotif(),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        start: 14,
                                      ),
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        style: colors.numberStyle(
                                          TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: colors.label,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: CalendarGrid(
                                gridDates: dates,
                                currentMonth: month,
                                today: today,
                                selectedDate: selected,
                                gridStyle: style,
                                onDateTap: (_) {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
