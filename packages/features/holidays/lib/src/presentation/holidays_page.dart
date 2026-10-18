import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../domain/holiday_search.dart';
import '../domain/holiday_year.dart';
import 'holiday_text.dart';
import 'holiday_widgets.dart';
import 'holidays_cubit.dart';

/// Every holiday of a year: the next one on top, then month by month, with
/// search and filters. Opened from Views.
class HolidaysPage extends StatelessWidget {
  const HolidaysPage({super.key, this.year, this.actions = const []});

  final int? year;

  /// Extra page actions (the reminders menu).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => HolidaysCubit(year: year),
    child: _HolidaysView(actions: actions),
  );
}

class _HolidaysView extends StatefulWidget {
  const _HolidaysView({required this.actions});

  final List<Widget> actions;

  @override
  State<_HolidaysView> createState() => _HolidaysViewState();
}

class _HolidaysViewState extends State<_HolidaysView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(BuildContext context, HolidayOccurrence o) => GoRouter.of(
    context,
  ).push(RoutePaths.holidayInViews(o.entry.id, o.start.year));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = context.calendarFormat;
    final language = context.calendarLanguage;
    final state = context.watch<HolidaysCubit>().state;
    final cubit = context.read<HolidaysCubit>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final list = HolidayYears.of(
      state.year,
      language,
    ).where((o) => state.filter.accepts(o.entry)).toList();

    Widget row(
      HolidayOccurrence o, {
      String? subtitle,
      bool showYear = false,
    }) => HolidayRow(
      key: ValueKey('holiday-${o.entry.id}-${o.start.toIso8601String()}'),
      occurrence: o,
      today: today,
      subtitle: subtitle,
      showYear: showYear,
      onTap: () => _open(context, o),
    );

    List<Widget> byMonth(Iterable<HolidayOccurrence> items) {
      final groups = <int, List<HolidayOccurrence>>{};
      for (final o in items) {
        groups.putIfAbsent(o.start.month, () => []).add(o);
      }
      return [
        for (final MapEntry(key: month, value: rows) in groups.entries)
          AppGroup(
            label: format.month(month),
            children: [for (final o in rows) row(o)],
          ),
      ];
    }

    final children = <Widget>[
      AppSearchField(
        key: const ValueKey('holidays-search'),
        controller: _search,
        placeholder: l10n.holidaysSearchHint,
        onChanged: cubit.search,
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in HolidayFilter.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AppChip(
                  key: ValueKey('holidays-filter-${f.name}'),
                  label: f.label(l10n),
                  selected: state.filter == f,
                  onSelected: (_) => cubit.filterBy(f),
                ),
              ),
          ],
        ),
      ),
    ];

    if (!state.searching) {
      final next = _nextHoliday(today, language);
      if (state.year == today.year && next != null) {
        children.add(
          _NextUp(
            occurrence: next,
            today: today,
            onTap: () => _open(context, next),
          ),
        );
      }
      children.add(_YearSwitcher(year: state.year, onChanged: cubit.showYear));
      if (state.year == today.year) {
        final upcoming = list.where((o) => !o.end.isBefore(today));
        final past = list.where((o) => o.end.isBefore(today)).toList();
        children.addAll(byMonth(upcoming));
        if (past.isNotEmpty) {
          children.add(
            AppGroup(
              label: l10n.holidaysEarlier,
              children: [for (final o in past) row(o, showYear: false)],
            ),
          );
        }
      } else {
        children.addAll(byMonth(list));
      }
    } else {
      children.addAll(_results(context, state, list, today, row));
    }

    return AppPage(
      title: l10n.holidays,
      actions: widget.actions,
      children: children,
    );
  }

  List<Widget> _results(
    BuildContext context,
    HolidaysState state,
    List<HolidayOccurrence> list,
    DateTime today,
    Widget Function(HolidayOccurrence, {String? subtitle, bool showYear}) row,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final format = context.calendarFormat;
    final language = context.calendarLanguage;

    String? match(HolidayOccurrence o) {
      final title = o.entry.title(l10n);
      final m = HolidaySearch.match(o, state.query, titles: [title]);
      if (m == null) return null;
      return m == title ? '' : m;
    }

    Widget hit(HolidayOccurrence o, String m, {bool showYear = false}) =>
        row(o, subtitle: m.isEmpty ? null : m, showYear: showYear);

    if (state.allYears) {
      final out = <Widget>[];
      for (var y = HolidayYears.firstYear; y <= HolidayYears.lastYear; y++) {
        final hits = [
          for (final o in HolidayYears.of(y, language))
            if (state.filter.accepts(o.entry))
              if (match(o) case final m?) hit(o, m),
        ];
        if (hits.isNotEmpty) {
          out.add(AppGroup(label: format.number(y), children: hits));
        }
      }
      return out.isEmpty
          ? [
              _Empty(
                text: l10n.holidaysNoResults(
                  '${state.year}',
                  state.query.trim(),
                ),
              ),
            ]
          : out;
    }

    final hits = [
      for (final o in list)
        if (match(o) case final m?) (o, m),
    ];
    final out = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          l10n.holidaysResults(hits.length, '${state.year}'),
          style: TextStyle(color: context.tokens.secondaryLabel, fontSize: 13),
        ),
      ),
    ];
    if (hits.isEmpty) {
      out.add(
        _Empty(
          text: l10n.holidaysNoResults('${state.year}', state.query.trim()),
        ),
      );
    } else if (state.year == today.year) {
      final earlier = hits.where((h) => h.$1.end.isBefore(today)).toList();
      final coming = hits.where((h) => !h.$1.end.isBefore(today)).toList();
      if (earlier.isNotEmpty) {
        out.add(
          AppGroup(
            label: l10n.holidaysEarlier,
            children: [for (final (o, m) in earlier) hit(o, m)],
          ),
        );
      }
      if (coming.isNotEmpty) {
        out.add(
          AppGroup(
            label: l10n.holidaysComingUp,
            children: [for (final (o, m) in coming) hit(o, m)],
          ),
        );
      }
      // Holidays already past this year: when they come round next.
      final nextTime = [
        for (final (o, m) in earlier)
          if (HolidayYears.find(o.entry.id, state.year + 1, language)
              case final n?)
            if (!coming.any((c) => c.$1.entry == o.entry))
              hit(n, m, showYear: true),
      ];
      if (nextTime.isNotEmpty) {
        out.add(AppGroup(label: l10n.holidaysNextYear, children: nextTime));
      }
    } else {
      out.add(AppGroup(children: [for (final (o, m) in hits) hit(o, m)]));
    }
    out.add(
      AppGroup(
        children: [
          AppRow(
            key: const ValueKey('holidays-search-all-years'),
            icon: Icons.search,
            iconColor: const Color(0xFF8E8E93),
            title: l10n.holidaysSearchAllYears,
            subtitle: l10n.holidaysYearsRange(
              '${HolidayYears.firstYear}',
              '${HolidayYears.lastYear}',
            ),
            chevron: true,
            onTap: context.read<HolidaysCubit>().searchAllYears,
          ),
        ],
      ),
    );
    return out;
  }

  /// The next day off from [today], this year or next.
  static HolidayOccurrence? _nextHoliday(DateTime today, Language language) {
    for (final y in [today.year, today.year + 1]) {
      for (final o in HolidayYears.of(y, language)) {
        if (o.entry.officeClosed && !o.end.isBefore(today)) return o;
      }
    }
    return null;
  }
}

class _NextUp extends StatelessWidget {
  const _NextUp({
    required this.occurrence,
    required this.today,
    required this.onTap,
  });

  final HolidayOccurrence occurrence;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = AppLocalizations.of(context)!;
    final format = context.calendarFormat;
    final o = occurrence;
    final days = o.daysFrom(today);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('holidays-next-up'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: t.surface,
            gradient: LinearGradient(
              colors: [t.holidaySoft, t.surface],
              stops: const [0, .7],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Column(
                  children: [
                    Text(
                      days <= 0 ? l10n.holidaysNow : '$days',
                      style: TextStyle(
                        color: t.holiday,
                        fontSize: days <= 0 ? 22 : 34,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    if (days > 0)
                      Text(
                        l10n
                            .holidaysDayCount(days)
                            .replaceAll(RegExp(r'^\S+\s*'), ''),
                        style: TextStyle(
                          color: t.secondaryLabel,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.holidaysNextUp.toUpperCase(),
                      style: TextStyle(
                        color: t.tertiaryLabel,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .4,
                      ),
                    ),
                    Text(
                      o.entry.title(l10n),
                      style: TextStyle(
                        color: t.label,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    Text(
                      '${format.holidayRange(o)} · ${l10n.holidaysDaysOff(o.length)}',
                      style: TextStyle(color: t.secondaryLabel, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearSwitcher extends StatelessWidget {
  const _YearSwitcher({required this.year, required this.onChanged});

  final int year;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final format = context.calendarFormat;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          key: const ValueKey('holidays-year-prev'),
          onPressed: year > HolidayYears.firstYear
              ? () => onChanged(year - 1)
              : null,
          icon: Icon(Icons.chevron_left, color: t.accent),
        ),
        GestureDetector(
          onTap: () => onChanged(DateTime.now().year),
          child: Text(
            format.number(year),
            style: TextStyle(
              color: t.label,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('holidays-year-next'),
          onPressed: year < HolidayYears.lastYear
              ? () => onChanged(year + 1)
              : null,
          icon: Icon(Icons.chevron_right, color: t.accent),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: context.tokens.secondaryLabel, fontSize: 14.5),
    ),
  );
}
