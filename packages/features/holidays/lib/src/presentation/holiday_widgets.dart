import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../catalog/holiday_catalog.dart';
import '../domain/holiday_search.dart';
import '../domain/holiday_year.dart';
import 'holiday_text.dart';

/// Date ranges and labels for holidays, in the calendar language.
extension HolidayFormat on CalendarFormat {
  /// "Sun 25 Oct", "25–27 Oct", "30 Apr – 2 May".
  String holidayRange(HolidayOccurrence o) {
    if (o.length == 1) return shortDate(o.start);
    if (o.start.month == o.end.month) {
      return '${westernNumber(o.start.day)}–${westernNumber(o.end.day)} ${shortMonth(o.start.month)}';
    }
    return '${dayMonth(o.start)} – ${dayMonth(o.end)}';
  }

  /// "Sunday" or "Sun – Tue".
  String holidayWeekdays(HolidayOccurrence o) => o.length == 1
      ? weekday(o.start)
      : '${weekday(o.start, short: true)} – ${weekday(o.end, short: true)}';
}

extension HolidayFilterText on HolidayFilter {
  String label(AppLocalizations l10n) => switch (this) {
    HolidayFilter.all => l10n.holidaysFilterAll,
    HolidayFilter.public => l10n.holidaysFilterPublic,
    HolidayFilter.religious => l10n.holidaysFilterReligious,
    HolidayFilter.cultural => l10n.holidaysFilterCultural,
    HolidayFilter.anniversary => l10n.holidaysFilterAnniversary,
  };
}

extension HolidayKindText on HolidayKind {
  String label(AppLocalizations l10n) => switch (this) {
    HolidayKind.national => l10n.holidaysKindNational,
    HolidayKind.religious => l10n.holidaysKindReligious,
    HolidayKind.cultural => l10n.holidaysKindCultural,
    HolidayKind.anniversary => l10n.holidaysKindAnniversary,
  };
}

/// A day number over a short month, red for days off, grey otherwise.
class HolidayDateBadge extends StatelessWidget {
  const HolidayDateBadge({super.key, required this.occurrence});

  final HolidayOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final format = context.calendarFormat;
    final o = occurrence;
    final closed = o.entry.officeClosed;
    final fg = closed ? t.holiday : t.secondaryLabel;
    final top = format.westernNumber(o.start.day);
    final bottom = o.length > 1 ? '–${format.westernNumber(o.end.day)}' : null;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: closed ? t.holidaySoft : t.fill,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            top,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: bottom == null ? 17 : 15,
              height: 1.15,
            ),
          ),
          if (bottom != null)
            Text(
              bottom,
              maxLines: 1,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
                height: 1.2,
              ),
            ),
        ],
      ),
    );
  }
}

/// One holiday in a list: badge, title, what it is and when, and how far
/// away it is. Past holidays are dimmed.
class HolidayRow extends StatelessWidget {
  const HolidayRow({
    super.key,
    required this.occurrence,
    required this.today,
    this.subtitle,
    this.showYear = false,
    this.onTap,
  });

  final HolidayOccurrence occurrence;
  final DateTime today;
  final String? subtitle;
  final bool showYear;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = context.calendarFormat;
    final o = occurrence;
    final from = o.daysFrom(today);
    final past = o.end.isBefore(DateTime(today.year, today.month, today.day));
    final kind = o.entry.officeClosed
        ? l10n.holidaysPublicHoliday
        : o.entry.kind.label(l10n);
    final when = showYear
        ? '${format.holidayRange(o)} ${format.westernNumber(o.start.year)}'
        : format.holidayRange(o);
    final value = past
        ? null
        : from <= 0
        ? l10n.holidaysNow
        : l10n.holidaysDaysShort('$from');
    return Opacity(
      opacity: past ? .45 : 1,
      child: AppRow(
        leading: HolidayDateBadge(occurrence: o),
        leadingWidth: 40,
        title: o.entry.title(l10n),
        subtitle: subtitle ?? '$kind · $when',
        value: value,
        chevron: onTap != null,
        onTap: onTap,
      ),
    );
  }
}

/// A small coloured label.
class HolidayBadge extends StatelessWidget {
  const HolidayBadge(this.text, {super.key, this.color, this.background});

  final String text;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? t.fill,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? t.secondaryLabel,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
