import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:holidays/holidays.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/views_injection.dart';
import '../bloc/views_bloc.dart';
import '../bloc/views_event.dart';

class ViewsSelectorPage extends StatefulWidget {
  const ViewsSelectorPage({super.key});

  @override
  State<ViewsSelectorPage> createState() => _ViewsSelectorPageState();
}

class _ViewsSelectorPageState extends State<ViewsSelectorPage> {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  @override
  void initState() {
    super.initState();
    // Log screen view when page loads
    _analyticsService.logScreenView(
      screenName: 'view_selector',
      screenClass: 'ViewsSelectorPage',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final year = DateTime.now().year;
    final publicHolidays = HolidayYears.of(
      year,
      context.calendarLanguage,
    ).where((o) => o.entry.officeClosed).length;
    return AppPage(
      title: l10n?.views ?? 'Views',
      children: [
        AppGroup(
          label: l10n?.viewsCalendarGroup,
          children: [
            AppRow(
              icon: Icons.calendar_view_month,
              iconColor: const Color(0xFF2F5BEA),
              title: l10n?.year_view ?? 'Year View',
              subtitle:
                  l10n?.viewsYearViewSubtitle ??
                  'All 12 months with holiday counts',
              chevron: true,
              onTap: () {
                context.read<ViewsBloc>().add(
                  LoadYearView(DateTime.now().year),
                );
                context.go('/views/year');
              },
            ),
            AppRow(
              icon: Icons.calendar_view_week,
              iconColor: const Color(0xFF16A3B0),
              title: l10n?.week_view ?? 'Week View',
              subtitle:
                  l10n?.viewsWeekViewSubtitle ??
                  'Seven days with Myanmar dates and the moon',
              chevron: true,
              onTap: () {
                context.read<ViewsBloc>().add(LoadWeekView(DateTime.now()));
                context.go('/views/week');
              },
            ),
            AppRow(
              icon: Icons.calendar_today,
              iconColor: const Color(0xFF8E6CEF),
              title: l10n?.day_view ?? 'Day View',
              subtitle:
                  l10n?.viewsDayViewSubtitle ?? 'Everything about one day',
              chevron: true,
              onTap: () => context.go('/views/day'),
            ),
          ],
        ),
        AppGroup(
          label: l10n?.viewsExploreGroup,
          footer: l10n?.holidaysViewsFooter(publicHolidays, '$year'),
          children: [
            AppRow(
              key: const ValueKey('views-holidays'),
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFE5383B),
              title: l10n?.holidays ?? 'Holidays',
              subtitle: l10n?.holidaysViewsSubtitle,
              value: '$publicHolidays',
              chevron: true,
              onTap: () => context.go(RoutePaths.holidaysPath()),
            ),
          ],
        ),
      ],
    );
  }
}
