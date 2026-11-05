import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

/// The good days ahead by the app's rule ([GoodDays]): within one, three or
/// six months, optionally on chosen weekdays. A day opens Day details.
class GoodDaysPage extends StatefulWidget {
  const GoodDaysPage({super.key, this.today});

  /// Today; now when null.
  final DateTime? today;

  @override
  State<GoodDaysPage> createState() => _GoodDaysPageState();
}

class _GoodDaysPageState extends State<GoodDaysPage> {
  static const _periods = [1, 3, 6];

  late final DateTime _today = DateUtils.dateOnly(
    widget.today ?? DateTime.now(),
  );
  int _months = 3;

  /// `DateTime` weekdays to keep; every day when empty.
  final Set<int> _weekdays = {};

  List<CompleteDate> _days() => GoodDays.between(
    _today,
    DateTime(_today.year, _today.month + _months, _today.day - 1),
    weekdays: _weekdays.isEmpty ? null : _weekdays,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = context.calendarFormat;
    final language = context.calendarLanguage;
    final t = context.tokens;
    final days = _days();
    final byMonth = <DateTime, List<CompleteDate>>{};
    for (final d in days) {
      byMonth
          .putIfAbsent(DateTime(d.westernYear, d.westernMonth), () => [])
          .add(d);
    }
    String mark(String key) => TranslationService.translateTo(key, language);

    return AppPage(
      title: l10n.goodDaysTitle,
      previousTitle: l10n.views,
      children: [
        AppSegmented<int>(
          key: const ValueKey('good-days-period'),
          segments: {for (final m in _periods) m: l10n.goodDaysMonths(m)},
          value: _months,
          onChanged: (m) => setState(() => _months = m),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Sunday first, as the week starts in Myanmar calendars.
              for (final wd in const [7, 1, 2, 3, 4, 5, 6])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppChip(
                    key: ValueKey('good-days-weekday-$wd'),
                    label: format.weekdayOf(wd, short: true),
                    selected: _weekdays.contains(wd),
                    onSelected: (on) => setState(
                      () => on ? _weekdays.add(wd) : _weekdays.remove(wd),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (days.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.goodDaysNone,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.secondaryLabel, fontSize: 15),
            ),
          ),
        for (final (i, MapEntry(key: month, value: monthDays))
            in byMonth.entries.indexed)
          AppGroup(
            label:
                '${format.monthYear(month)} · '
                '${format.number(monthDays.length)}',
            // The rule, once, under the last month.
            footer: i == byMonth.length - 1 ? l10n.goodDaysFooter : null,
            children: [
              for (final d in monthDays)
                AppRow(
                  key: ValueKey(
                    'good-day-${d.westernYear}-${d.westernMonth}-${d.westernDay}',
                  ),
                  title: () {
                    final date = DateTime(
                      d.westernYear,
                      d.westernMonth,
                      d.westernDay,
                    );
                    return '${format.weekday(date, short: true)} '
                        '${format.dayMonth(date)}';
                  }(),
                  value: format.myanmar(d.myanmar, '&M &P &f'),
                  subtitle: [
                    for (final m in GoodDays.marks(d))
                      if (GoodDays.tone(m) != AstroTone.caution) mark(m),
                  ].join(' · '),
                  chevron: true,
                  onTap: () => GoRouter.of(context).push(
                    '${RoutePaths.views}/${RoutePaths.dayView}',
                    extra: DateTime(
                      d.westernYear,
                      d.westernMonth,
                      d.westernDay,
                    ),
                  ),
                ),
            ],
          ),
        if (days.isEmpty)
          Text(
            l10n.goodDaysFooter,
            style: TextStyle(color: t.secondaryLabel, fontSize: 13),
          ),
      ],
    );
  }
}
