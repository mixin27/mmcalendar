import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../domain/long_weekends.dart';
import 'holiday_text.dart';

/// "Take 1 day off, get 5": the long breaks around [year]'s public
/// holidays, for up to 1, 2 or 3 days of leave. A break opens its first
/// holiday.
class LongWeekendsPage extends StatefulWidget {
  const LongWeekendsPage({super.key, this.year, this.today});

  final int? year;

  /// Today; now when null.
  final DateTime? today;

  @override
  State<LongWeekendsPage> createState() => _LongWeekendsPageState();
}

class _LongWeekendsPageState extends State<LongWeekendsPage> {
  late final DateTime _today = DateUtils.dateOnly(
    widget.today ?? DateTime.now(),
  );
  late final int _year = widget.year ?? _today.year;
  int _maxLeave = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = context.calendarFormat;
    final t = context.tokens;
    final breaks = LongWeekends.plan(
      _year,
      context.calendarLanguage,
      maxLeave: _maxLeave,
      today: _today,
    );

    String range(LongWeekend b) => b.start.month == b.end.month
        ? '${format.westernNumber(b.start.day)}–${format.dayMonth(b.end)}'
        : '${format.dayMonth(b.start)} – ${format.dayMonth(b.end)}';
    String leave(LongWeekend b) => b.leave.isEmpty
        ? l10n.longWeekendsNoLeave
        : l10n.longWeekendsTake(
            b.leave
                .map(
                  (d) =>
                      '${format.weekday(d, short: true)} ${format.dayMonth(d)}',
                )
                .join(', '),
          );
    String names(LongWeekend b) =>
        b.holidays.map((o) => o.entry.title(l10n)).toSet().join(' · ');

    String shareText() => [
      '${l10n.longWeekendsTitle} ${format.westernNumber(_year)}',
      for (final b in breaks)
        '• ${range(b)}: ${l10n.longWeekendsDays(b.length)} — ${leave(b)} (${names(b)})',
    ].join('\n');

    return AppPage(
      title: l10n.longWeekendsTitle,
      previousTitle: l10n.holidays,
      actions: [
        if (breaks.isNotEmpty)
          IconButton(
            key: const ValueKey('long-weekends-share'),
            tooltip: l10n.share,
            icon: Icon(
              context.isClearStyle ? Icons.ios_share : Icons.share_outlined,
              color: t.accent,
            ),
            onPressed: () =>
                share(title: l10n.longWeekendsTitle, content: shareText()),
          ),
      ],
      children: [
        AppSegmented<int>(
          key: const ValueKey('long-weekends-leave'),
          segments: {
            for (final n in const [1, 2, 3]) n: l10n.longWeekendsLeaveDays(n),
          },
          value: _maxLeave,
          onChanged: (n) => setState(() => _maxLeave = n),
        ),
        if (breaks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.longWeekendsNone,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.secondaryLabel, fontSize: 15),
            ),
          )
        else
          AppGroup(
            footer: l10n.longWeekendsFooter,
            children: [
              for (final b in breaks)
                AppRow(
                  key: ValueKey('long-weekend-${b.start.month}-${b.start.day}'),
                  title: '${range(b)} · ${l10n.longWeekendsDays(b.length)}',
                  subtitle: '${leave(b)}\n${names(b)}',
                  chevron: true,
                  onTap: () => GoRouter.of(context).push(
                    RoutePaths.holidayInViews(
                      b.holidays.first.entry.id,
                      b.holidays.first.start.year,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
