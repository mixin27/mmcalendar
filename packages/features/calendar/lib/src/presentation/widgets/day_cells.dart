import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import 'calendar_colors.dart';

part 'day_cells_set1.dart';
part 'day_cells_set2.dart';

/// Which optional details the user wants in the grid (Settings › Display).
@immutable
class DayCellOptions {
  const DayCellOptions({
    this.showHolidays = true,
    this.showAnniversaryDays = true,
    this.showSabbaths = true,
    this.showAstrology = true,
    this.showWesternDates = true,
    this.showMyanmarDates = true,
  });

  final bool showHolidays;
  final bool showAnniversaryDays;
  final bool showSabbaths;
  final bool showAstrology;
  final bool showWesternDates;
  final bool showMyanmarDates;
}

/// Everything a grid cell draws, resolved once per day.
@immutable
class DayCellData {
  DayCellData({
    required this.info,
    required this.isToday,
    required this.isSelected,
    required this.isInMonth,
    required this.options,
    this.events = const <CalendarEventItem>[],
  }) : date = DateTime(info.westernYear, info.westernMonth, info.westernDay),
       moon = MoonPhaseState.evening(
         DateTime(info.westernYear, info.westernMonth, info.westernDay),
       );

  final CompleteDate info;
  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool isInMonth;
  final DayCellOptions options;
  final List<CalendarEventItem> events;

  final MoonPhaseState moon;

  /// Myanmar weekday index 1 is Sunday.
  bool get isSunday => info.weekday == 1;
  bool get showsHoliday => options.showHolidays && info.hasHolidays;
  bool get showsAnniversary =>
      options.showAnniversaryDays && info.hasAnniversaryDays;
  bool get showsSabbath => options.showSabbaths && info.isSabbath;
  bool get showsAstrology => options.showAstrology && info.hasAstrologicalDays;
  bool get isMoonDay => info.isFullMoon || info.isNewMoon;

  String get holidayName => info.allHolidays.isEmpty
      ? ''
      : TranslationService.translateTo(
          info.allHolidays.first,
          MyanmarCalendar.currentLanguage,
        );

  /// "ဆန်း" / "Waxing", or the moon day's name ("လပြည့်", "Full Moon").
  String get lunarPhase {
    final language = MyanmarCalendar.currentLanguage;
    var phase = TranslationService.getMoonPhaseName(info.moonPhase, language);
    if (!isMoonDay && language == Language.myanmar && phase.startsWith('လ')) {
      phase = phase.substring(1);
    }
    return phase;
  }

  /// The day of the fortnight in the calendar language's digits ("၅").
  String get lunarNumber => translateNumbers('${info.fortnightDay}');

  /// "ဥပုသ်" / "Sabbath".
  String get sabbathName => TranslationService.translateTo(
    'Sabbath',
    MyanmarCalendar.currentLanguage,
  );

  /// The full Myanmar date, "သီတင်းကျွတ် လဆန်း ၅".
  String get myanmarDate => MyanmarCalendar.formatMyanmar(
    info.myanmar,
    pattern: '&P &f',
    language: MyanmarCalendar.currentLanguage,
  );

  /// "ဆန်း ၅", "Waxing 5", or the moon day's name.
  String get lunarLabel {
    final language = MyanmarCalendar.currentLanguage;
    var phase = TranslationService.getMoonPhaseName(info.moonPhase, language);
    if (isMoonDay) return phase;
    if (language == Language.myanmar && phase.startsWith('လ')) {
      phase = phase.substring(1);
    }
    return '$phase ${translateNumbers('${info.fortnightDay}')}';
  }

  String get semanticsLabel {
    final language = MyanmarCalendar.currentLanguage;
    return <String>[
      if (isToday) TranslationService.translateTo('Today', language),
      if (isSelected) TranslationService.translateTo('Selected', language),
      '${TranslationService.getWeekdayName(info.weekday, language)}, '
          '${TranslationService.getWesternMonthName(info.westernMonth, language)} '
          '${info.westernDay}, ${info.westernYear}',
      MyanmarCalendar.formatMyanmar(info.myanmar, language: language),
      ...info.allHolidays.map(
        (h) => TranslationService.translateTo(h, language),
      ),
      ...info.allAnniversaryDays.map(
        (d) => TranslationService.translateTo(d, language),
      ),
      if (events.isNotEmpty) events.map((e) => e.title).join(', '),
    ].where((segment) => segment.isNotEmpty).join('. ');
  }
}

Color eventColor(CalendarEventItem event, CalendarColors colors) =>
    switch (event.priority) {
      CalendarEventPriority.urgent => colors.holiday,
      CalendarEventPriority.high => const Color(0xFFF08A1C),
      _ => Color(event.effectiveColor),
    };

/// Shared tap target and semantics for every cell style.
class _CellShell extends StatelessWidget {
  const _CellShell({
    required this.data,
    required this.onTap,
    required this.child,
  });

  final DayCellData data;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: data.isInMonth,
    selected: data.isSelected,
    label: data.semanticsLabel,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: data.isInMonth ? onTap : null,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
        child: child,
      ),
    ),
  );
}

const _labelSize = 8.5;
const _labelLine = 11.5;

TextStyle _small(BuildContext context, Color color, {FontWeight? weight}) =>
    TextStyle(
      fontSize: _labelSize,
      height: 1.3,
      color: color,
      fontWeight: weight ?? FontWeight.w500,
    );

/// Ruled cells that keep the lunar day, holiday name, the real moon and
/// events in every day, stacked from the top so they read with the date. Content is dropped, least important first, when a
/// row is short: event titles, then the holiday name, then the event bar.
class DetailedDayCell extends StatelessWidget {
  const DetailedDayCell({super.key, required this.data, this.onTap});

  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    return _CellShell(
      data: data,
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final line = _labelLine * scale;
          var budget = box.maxHeight - 8 - 22;
          bool take(double height) {
            if (budget < height) return false;
            budget -= height;
            return true;
          }

          final inMonth = data.isInMonth;
          // Width beside the 22 px number for the moon and marker dots.
          final room =
              box.maxWidth - 6 - (data.options.showWesternDates ? 22 : 0);
          final lunar = inMonth && data.options.showMyanmarDates && take(line);
          final eventBar = inMonth && data.events.isNotEmpty && take(5);
          final holiday = inMonth && data.showsHoliday && take(line);
          final eventTitle = eventBar && take(line - 3);

          final numberColor = data.isToday
              ? colors.onAccent
              : (data.showsHoliday || data.isSunday)
              ? colors.holiday
              : colors.label;

          return Container(
            decoration: BoxDecoration(
              color: inMonth && data.showsHoliday ? colors.holidaySoft : null,
              border: Border(
                top: BorderSide(color: colors.separator, width: .5),
              ),
            ),
            child: _SelectedTint(
              selected: data.isSelected,
              color: colors.accentSoft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
                child: Opacity(
                  opacity: inMonth ? 1 : .3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 22,
                        child: Row(
                          children: [
                            if (data.options.showWesternDates)
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: data.isToday
                                    ? BoxDecoration(
                                        color: colors.accent,
                                        shape: BoxShape.circle,
                                      )
                                    : null,
                                child: Text(
                                  '${data.info.westernDay}',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1,
                                    fontWeight: FontWeight.w600,
                                    color: numberColor,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            const Spacer(),
                            if (inMonth && room >= 18 && data.showsAnniversary)
                              _Dot(color: colors.anniversary),
                            if (inMonth && room >= 24 && data.showsAstrology)
                              _Dot(color: colors.astrology),
                            if (inMonth && room >= 12) ...[
                              const SizedBox(width: 2),
                              MoonGlyph(state: data.moon, size: 10),
                            ],
                          ],
                        ),
                      ),
                      if (lunar)
                        Text(
                          data.lunarLabel,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: _small(
                            context,
                            data.showsSabbath
                                ? colors.sabbath
                                : colors.secondaryLabel,
                            weight: data.showsSabbath ? FontWeight.w700 : null,
                          ),
                        ),
                      if (holiday)
                        Text(
                          data.holidayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _small(
                            context,
                            colors.holiday,
                            weight: FontWeight.w600,
                          ),
                        ),
                      if (eventBar)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: eventTitle
                              ? _EventChip(events: data.events, colors: colors)
                              : _EventBars(events: data.events, colors: colors),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Calm cells: a number in a disc, the lunar day beneath, one dot row.
/// The moon is drawn only on full and new moon days.
class CleanDayCell extends StatelessWidget {
  const CleanDayCell({super.key, required this.data, this.onTap});

  final DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColors.of(context);
    return _CellShell(
      data: data,
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final disc = (box.maxHeight * .5).clamp(22.0, 32.0);
          var budget = box.maxHeight - 6 - disc;
          final inMonth = data.isInMonth;
          final lunar =
              inMonth &&
              data.options.showMyanmarDates &&
              budget >= _labelLine * scale;
          if (lunar) budget -= _labelLine * scale;
          final marks = inMonth && budget >= 6;

          final filled = data.isToday;
          final numberColor = filled
              ? colors.onAccent
              : (data.showsHoliday || data.isSunday)
              ? colors.holiday
              : colors.label;

          return _SelectedTint(
            selected: data.isSelected,
            color: colors.accentSoft,
            radius: 10,
            child: Opacity(
              opacity: inMonth ? 1 : .28,
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Column(
                  children: [
                    Container(
                      width: disc,
                      height: disc,
                      alignment: Alignment.center,
                      decoration: filled
                          ? BoxDecoration(
                              color: colors.accent,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: data.options.showWesternDates
                          ? Text(
                              '${data.info.westernDay}',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: disc * .53,
                                height: 1,
                                fontWeight: filled
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: numberColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            )
                          : null,
                    ),
                    if (lunar)
                      SizedBox(
                        height: _labelLine * scale,
                        child: Center(
                          child: data.isMoonDay
                              ? MoonGlyph(state: data.moon, size: 10)
                              : Text(
                                  data.lunarLabel,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.fade,
                                  style: _small(
                                    context,
                                    data.showsSabbath
                                        ? colors.sabbath
                                        : colors.tertiaryLabel,
                                    weight: data.showsSabbath
                                        ? FontWeight.w700
                                        : null,
                                  ),
                                ),
                        ),
                      ),
                    if (marks)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (data.events.isNotEmpty)
                              _Dot(color: colors.accent),
                            if (data.showsAnniversary)
                              _Dot(color: colors.anniversary),
                            if (data.showsAstrology)
                              _Dot(color: colors.astrology),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 4,
    height: 4,
    margin: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _EventBars extends StatelessWidget {
  const _EventBars({required this.events, required this.colors});
  final List<CalendarEventItem> events;
  final CalendarColors colors;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 3,
    child: Row(
      children: [
        for (final (i, event) in events.take(3).indexed) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: eventColor(event, colors),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _EventChip extends StatelessWidget {
  const _EventChip({required this.events, required this.colors});
  final List<CalendarEventItem> events;
  final CalendarColors colors;

  @override
  Widget build(BuildContext context) {
    final color = eventColor(events.first, colors);
    final more = events.length - 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        more > 0 ? '${events.first.title} +$more' : events.first.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _small(context, color, weight: FontWeight.w600),
      ),
    );
  }
}

/// The selected day: a soft accent tint over the whole cell, replacing
/// outlines and filled discs. Today keeps its solid accent circle.
class _SelectedTint extends StatelessWidget {
  const _SelectedTint({
    required this.selected,
    required this.color,
    required this.child,
    this.radius = 8,
  });

  final bool selected;
  final Color color;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => selected
      ? DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        )
      : child;
}
