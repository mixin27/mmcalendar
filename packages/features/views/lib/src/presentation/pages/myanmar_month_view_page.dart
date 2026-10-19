import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart' as mm;
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/views_injection.dart';

/// A Myanmar month laid out as it is counted: the waxing fortnight to the
/// full moon, then the waning fortnight to the new moon, with the month's
/// quarter moons under it. Tapping a day opens its details.
class MyanmarMonthViewPage extends StatefulWidget {
  const MyanmarMonthViewPage({super.key});

  @override
  State<MyanmarMonthViewPage> createState() => _MyanmarMonthViewPageState();
}

class _MyanmarMonthViewPageState extends State<MyanmarMonthViewPage> {
  final AnalyticsPort _analytics = getIt<AnalyticsPort>();
  int? _year;
  int? _month;

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(
      screenName: 'myanmar_month_view',
      screenClass: 'MyanmarMonthViewPage',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_year == null) {
      final today = mm.MyanmarCalendarScope.of(
        context,
      ).day(DateTime.now()).myanmar;
      _year = today.year;
      _month = today.month;
    }
  }

  void _openDay(mm.CompleteDate day) {
    final w = day.western;
    context.go(
      '${RoutePaths.views}/${RoutePaths.dayView}',
      extra: DateTime(w.year, w.month, w.day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppPage(
      title: l10n?.viewsMyanmarMonth ?? 'Myanmar Month',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: mm.MyanmarLunarMonthCalendar(
            key: const ValueKey('views-myanmar-month'),
            year: _year!,
            month: _month!,
            onDayTapped: _openDay,
            onMonthChanged: (year, month) => setState(() {
              _year = year;
              _month = month;
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: mm.MoonPhaseStrip(
            year: _year!,
            month: _month!,
            onDayTapped: _openDay,
          ),
        ),
      ],
    );
  }
}
