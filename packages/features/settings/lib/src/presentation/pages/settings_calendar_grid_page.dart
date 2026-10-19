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
import 'package:shared_localizations/shared_localizations.dart';

import '../../domain/entities/app_settings.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../widgets/settings_widgets.dart';

/// Names and one-line descriptions for each grid layout.
extension CalendarGridStyleLabel on CalendarGridStyle {
  String title(AppLocalizations l10n) => switch (this) {
    CalendarGridStyle.almanac => l10n.gridLayoutAlmanacTitle,
    CalendarGridStyle.monthRegions => l10n.gridLayoutMonthRegionsTitle,
    CalendarGridStyle.focusWeek => l10n.gridLayoutFocusWeekTitle,
    CalendarGridStyle.auspice => l10n.gridLayoutAuspiceTitle,
    CalendarGridStyle.detailed => l10n.gridLayoutDetailedTitle,
    CalendarGridStyle.clean => l10n.gridLayoutCleanTitle,
    CalendarGridStyle.classic => l10n.gridLayoutClassicTitle,
    CalendarGridStyle.detailedV2 => l10n.gridLayoutDetailedV2Title,
    CalendarGridStyle.lunarFirst => l10n.gridLayoutLunarFirstTitle,
    CalendarGridStyle.minimal => l10n.gridLayoutMinimalTitle,
    CalendarGridStyle.moonStrip => l10n.gridLayoutMoonStripTitle,
    CalendarGridStyle.agenda => l10n.gridLayoutAgendaTitle,
    CalendarGridStyle.classicPrint => l10n.gridLayoutClassicPrintTitle,
    CalendarGridStyle.tiles => l10n.gridLayoutTilesTitle,
    CalendarGridStyle.moonlight => l10n.gridLayoutMoonlightTitle,
    CalendarGridStyle.split => l10n.gridLayoutSplitTitle,
    CalendarGridStyle.poster => l10n.gridLayoutPosterTitle,
    CalendarGridStyle.moonRing => l10n.gridLayoutMoonRingTitle,
    CalendarGridStyle.astrology => l10n.gridLayoutAstrologyTitle,
  };

  String description(AppLocalizations l10n) => switch (this) {
    CalendarGridStyle.almanac => l10n.gridLayoutAlmanacDescription,
    CalendarGridStyle.monthRegions => l10n.gridLayoutMonthRegionsDescription,
    CalendarGridStyle.focusWeek => l10n.gridLayoutFocusWeekDescription,
    CalendarGridStyle.auspice => l10n.gridLayoutAuspiceDescription,
    CalendarGridStyle.detailed => l10n.gridLayoutDetailedDescription,
    CalendarGridStyle.clean => l10n.gridLayoutCleanDescription,
    CalendarGridStyle.classic => l10n.gridLayoutClassicDescription,
    CalendarGridStyle.detailedV2 => l10n.gridLayoutDetailedV2Description,
    CalendarGridStyle.lunarFirst => l10n.gridLayoutLunarFirstDescription,
    CalendarGridStyle.minimal => l10n.gridLayoutMinimalDescription,
    CalendarGridStyle.moonStrip => l10n.gridLayoutMoonStripDescription,
    CalendarGridStyle.agenda => l10n.gridLayoutAgendaDescription,
    CalendarGridStyle.classicPrint => l10n.gridLayoutClassicPrintDescription,
    CalendarGridStyle.tiles => l10n.gridLayoutTilesDescription,
    CalendarGridStyle.moonlight => l10n.gridLayoutMoonlightDescription,
    CalendarGridStyle.split => l10n.gridLayoutSplitDescription,
    CalendarGridStyle.poster => l10n.gridLayoutPosterDescription,
    CalendarGridStyle.moonRing => l10n.gridLayoutMoonRingDescription,
    CalendarGridStyle.astrology => l10n.gridLayoutAstrologyDescription,
  };
}

/// Names and one-line descriptions for each grid theme.
extension CalendarGridThemeLabel on CalendarGridTheme {
  String title(AppLocalizations l10n) => switch (this) {
    CalendarGridTheme.app => l10n.gridThemeAppTitle,
    CalendarGridTheme.pagoda => l10n.gridThemePagodaTitle,
    CalendarGridTheme.jade => l10n.gridThemeJadeTitle,
    CalendarGridTheme.lacquer => l10n.gridThemeLacquerTitle,
    CalendarGridTheme.thadingyut => l10n.gridThemeThadingyutTitle,
    CalendarGridTheme.thingyan => l10n.gridThemeThingyanTitle,
    CalendarGridTheme.botanical => l10n.gridThemeBotanicalTitle,
    CalendarGridTheme.monsoon => l10n.gridThemeMonsoonTitle,
    CalendarGridTheme.tidewater => l10n.gridThemeTidewaterTitle,
    CalendarGridTheme.morningPour => l10n.gridThemeMorningPourTitle,
    CalendarGridTheme.deepField => l10n.gridThemeDeepFieldTitle,
    CalendarGridTheme.moonlight => l10n.gridThemeMoonlightTitle,
    CalendarGridTheme.nightChart => l10n.gridThemeNightChartTitle,
  };

  String description(AppLocalizations l10n) => switch (this) {
    CalendarGridTheme.app => l10n.gridThemeAppDescription,
    CalendarGridTheme.pagoda => l10n.gridThemePagodaDescription,
    CalendarGridTheme.jade => l10n.gridThemeJadeDescription,
    CalendarGridTheme.lacquer => l10n.gridThemeLacquerDescription,
    CalendarGridTheme.thadingyut => l10n.gridThemeThadingyutDescription,
    CalendarGridTheme.thingyan => l10n.gridThemeThingyanDescription,
    CalendarGridTheme.botanical => l10n.gridThemeBotanicalDescription,
    CalendarGridTheme.monsoon => l10n.gridThemeMonsoonDescription,
    CalendarGridTheme.tidewater => l10n.gridThemeTidewaterDescription,
    CalendarGridTheme.morningPour => l10n.gridThemeMorningPourDescription,
    CalendarGridTheme.deepField => l10n.gridThemeDeepFieldDescription,
    CalendarGridTheme.moonlight => l10n.gridThemeMoonlightDescription,
    CalendarGridTheme.nightChart => l10n.gridThemeNightChartDescription,
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

  // This month's grid days, worked out once rather than on every rebuild.
  DateTime? _month;
  List<CompleteDate> _dates = const [];

  List<CompleteDate> _datesFor(DateTime month) {
    if (_month?.year != month.year || _month?.month != month.month) {
      _month = month;
      _dates = AppDateUtils.getCalendarGridDates(
        month,
        firstDayOfWeek: 1,
      ).map(MyanmarCalendar.getCompleteDate).toList(growable: false);
    }
    return _dates;
  }

  /// [cards] two or three to a row. Each row is its own child of the page's
  /// lazy list, so only the previews on screen are built.
  List<Widget> _rows(
    BuildContext context,
    List<Widget> cards, {
    required double aspectRatio,
  }) {
    final columns = MediaQuery.sizeOf(context).width - 32 >= 560 ? 3 : 2;
    return [
      for (var i = 0; i < cards.length; i += columns)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = i; j < i + columns; j++) ...[
              if (j > i) const SizedBox(width: 12),
              Expanded(
                child: j < cards.length
                    ? AspectRatio(aspectRatio: aspectRatio, child: cards[j])
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsSubPage(
      title: l10n.settingsCalendarGrid,
      previousTitle: l10n.display_preferences,
      spacing: 12,
      builder: (context, settings) {
        final current = settings.calendarGridStyle;
        final month = DateTime.now();
        final dates = _datesFor(month);
        final tabs = AppSegmented<_Tab>(
          segments: {
            _Tab.layout: l10n.settingsGridLayoutTab,
            _Tab.theme: l10n.settingsGridThemeTab,
          },
          value: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
        );
        if (_tab == _Tab.theme) {
          return [tabs, ..._themeChoices(context, settings, month, dates)];
        }
        return [
          tabs,
          ..._rows(context, aspectRatio: .68, [
            for (final style in CalendarGridStyle.values)
              _GridChoice(
                key: ValueKey('grid-style-${style.name}'),
                title: style.title(l10n),
                description: style.description(l10n),
                isDefault: style == CalendarGridStyle.defaultStyle,
                selected: style == current,
                preview: _Preview(style: style, month: month, dates: dates),
                onTap: () => context.read<SettingsBloc>().add(
                  ChangeCalendarGridStyle(style),
                ),
              ),
          ]),
          Text(
            l10n.settingsGridFitNote,
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
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    return [
      ..._rows(context, aspectRatio: .62, [
        for (final theme in CalendarGridTheme.values)
          _GridChoice(
            key: ValueKey('grid-theme-${theme.name}'),
            title: theme.title(l10n),
            description: theme.description(l10n),
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
      ]),
      AppGroup(
        footer: l10n.settingsGridThemeFooter,
        children: [
          AppRow.toggle(
            key: const ValueKey('grid-theme-motif'),
            icon: Icons.auto_awesome_outlined,
            iconColor: SettingsIconColors.indigo,
            title: l10n.settingsGridShowMotif,
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
                  // Its own layer: a selection change repaints the card's
                  // border, not the month inside it.
                  child: RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ColoredBox(color: t.background, child: preview),
                    ),
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
                  isDefault
                      ? AppLocalizations.of(
                          context,
                        )!.settingsGridDefault(description)
                      : description,
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
