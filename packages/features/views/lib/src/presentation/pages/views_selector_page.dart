import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
    return AppPage(
      title: l10n?.views ?? 'Views',
      children: [
        AppGroup(
          children: [
            AppRow(
              icon: Icons.calendar_view_month,
              iconColor: const Color(0xFF2F5BEA),
              title: l10n?.year_view ?? 'Year View',
              subtitle: 'All 12 months with holiday counts',
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
              subtitle: 'Seven days with Myanmar dates and the moon',
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
              subtitle: 'Everything about one day',
              chevron: true,
              onTap: () => context.go('/views/day'),
            ),
          ],
        ),
      ],
    );
  }
}
