import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../catalog/holiday_catalog.dart';
import '../domain/holiday_year.dart';
import '../reminders/holiday_reminder_widgets.dart';
import 'holiday_text.dart';
import 'holiday_widgets.dart';

/// One holiday: each of its days with the Myanmar date, what it marks, and
/// the same holiday in other years.
class HolidayDetailPage extends StatelessWidget {
  const HolidayDetailPage({
    super.key,
    required this.id,
    required this.year,
    this.previousTitle,
  });

  final String id;
  final int year;

  final String? previousTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.tokens;
    final format = context.calendarFormat;
    final language = context.calendarLanguage;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final occurrence = HolidayYears.find(id, year, language);
    final entry =
        occurrence?.entry ??
        HolidayCatalog.byId(id) ??
        HolidayCatalog.custom(
          id.replaceFirst(HolidayCatalog.customPrefix, ''),
          kind: HolidayKind.national,
          officeClosed: false,
        );
    final title = entry.title(l10n);
    final about = entry.about(l10n);
    final base = GoRouterState.of(context).uri.path;

    final localNames =
        <String>{
              for (final d in occurrence?.days ?? const <HolidayDay>[])
                ...d.labels,
            }
            .where(
              (n) =>
                  n != title &&
                  n != HolidayCatalog.bridgeName &&
                  n != format.translate(HolidayCatalog.bridgeName) &&
                  n != l10n.holidaysPublicHoliday,
            )
            .toList();

    final days = occurrence?.daysFrom(today);
    final badges = <Widget>[
      if (entry.officeClosed)
        HolidayBadge(
          l10n.holidaysPublicHoliday,
          color: t.holiday,
          background: t.holidaySoft,
        )
      else
        HolidayBadge(l10n.holidaysObservance),
      HolidayBadge(entry.kind.label(l10n)),
      if (occurrence != null)
        HolidayBadge(
          [
            if (occurrence.length > 1) l10n.holidaysDayCount(occurrence.length),
            if (days != null && days >= 0) l10n.holidaysInDays(days),
          ].join(' · '),
        ),
    ].where((w) => w is! HolidayBadge || w.text.isNotEmpty).toList();

    final otherYears = [
      for (var y = year - 2; y <= year + 3; y++)
        if (y != year &&
            y >= HolidayYears.firstYear &&
            y <= HolidayYears.lastYear)
          (y, HolidayYears.find(id, y, language)),
    ];

    return AppPage(
      title: title,
      previousTitle: previousTitle ?? l10n.holidays,
      actions: [
        if (occurrence != null)
          IconButton(
            key: const ValueKey('holiday-share'),
            tooltip: MaterialLocalizations.of(context).shareButtonLabel,
            icon: Icon(Icons.ios_share, color: t.accent),
            onPressed: () => share(
              title: title,
              content:
                  '$title · ${format.holidayRange(occurrence)} ${format.number(occurrence.start.year)}'
                  '${about == null ? '' : '\n\n$about'}',
            ),
          ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (localNames.isNotEmpty)
                Text(
                  localNames.join(' · '),
                  style: TextStyle(
                    color: t.secondaryLabel,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: badges),
            ],
          ),
        ),
        if (occurrence == null)
          AppGroup(children: [AppRow(title: l10n.holidaysNotThisYear('$year'))])
        else
          AppGroup(
            children: [
              for (final d in occurrence.days)
                AppRow(
                  key: ValueKey('holiday-day-${d.date.toIso8601String()}'),
                  leading: _Weekday(date: d.date),
                  leadingWidth: 40,
                  title: d.labels.join(' · '),
                  subtitle: format.myanmar(
                    MyanmarCalendar.fromWestern(
                      d.date.year,
                      d.date.month,
                      d.date.day,
                    ).myanmarDate,
                    '&P &f',
                  ),
                  chevron: true,
                  onTap: () => GoRouter.of(context).push(
                    '${RoutePaths.home}/${RoutePaths.dayDetails}?date=${d.date.toIso8601String().substring(0, 10)}',
                  ),
                ),
            ],
          ),
        if (occurrence != null) HolidayReminderGroup(entry: entry),
        if (about != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              about,
              style: TextStyle(color: t.label, fontSize: 15, height: 1.6),
            ),
          ),
        if (otherYears.isNotEmpty)
          AppGroup(
            label: l10n.holidaysOtherYears,
            children: [
              for (final (y, o) in otherYears)
                AppRow(
                  key: ValueKey('holiday-year-$y'),
                  title: format.number(y),
                  value: o == null
                      ? l10n.holidaysNotThisYear('$y')
                      : format.holidayRange(o),
                  chevron: o != null,
                  onTap: o == null
                      ? null
                      : () => GoRouter.of(
                          context,
                        ).pushReplacement('$base?year=$y'),
                ),
            ],
          ),
        if (occurrence != null)
          AppButton(
            key: const ValueKey('holiday-open-calendar'),
            label: l10n.holidaysOpenInCalendar,
            kind: AppButtonKind.tinted,
            onPressed: () => context.go(
              '${RoutePaths.home}?date=${occurrence.start.toIso8601String().substring(0, 10)}',
            ),
          ),
      ],
    );
  }
}

class _Weekday extends StatelessWidget {
  const _Weekday({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final format = context.calendarFormat;
    return SizedBox(
      width: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            format.weekday(date, short: true),
            maxLines: 1,
            style: TextStyle(
              color: t.secondaryLabel,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            format.number(date.day),
            style: TextStyle(
              color: t.label,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
