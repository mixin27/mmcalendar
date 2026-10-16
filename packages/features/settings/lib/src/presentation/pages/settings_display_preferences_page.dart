import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:settings/settings.dart';
import 'package:settings/src/di/settings_injection.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../widgets/settings_widgets.dart';

class SettingsDisplayPreferencesPage extends StatefulWidget {
  const SettingsDisplayPreferencesPage({super.key});

  @override
  State<SettingsDisplayPreferencesPage> createState() =>
      _SettingsDisplayPreferencesPageState();
}

class _SettingsDisplayPreferencesPageState
    extends State<SettingsDisplayPreferencesPage> {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();

  @override
  void initState() {
    _analyticsService.logScreenView(
      screenName: 'settings_display_preferences',
      screenClass: 'SettingsDisplayPreferencesPage',
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSubPage(
      title: l10n?.display_preferences ?? 'Display Preferences',
      builder: (context, settings) {
        AppRow toggle(
          String title,
          String key,
          bool value,
          IconData icon,
          Color color, {
          String? subtitle,
        }) => AppRow.toggle(
          title: title,
          subtitle: subtitle,
          icon: icon,
          iconColor: color,
          value: value,
          onChanged: (v) =>
              context.read<SettingsBloc>().add(ToggleDisplayPreference(key, v)),
        );

        return [
          AppGroup(
            children: [
              AppRow(
                icon: Icons.grid_view_rounded,
                iconColor: SettingsIconColors.blue,
                title: 'Calendar grid',
                value: switch (settings.calendarGridStyle) {
                  CalendarGridStyle.detailed => 'Detailed',
                  CalendarGridStyle.clean => 'Clean',
                  CalendarGridStyle.classic => 'Classic',
                },
                chevron: true,
                onTap: () => GoRouter.of(
                  context,
                ).push('/settings/${RoutePaths.calendarGrid}'),
              ),
            ],
          ),
          AppGroup(
            label: 'Show in calendar',
            children: [
              toggle(
                l10n?.showHolidays ?? 'Show Holidays',
                StorageKeys.showHolidays,
                settings.showHolidays,
                Icons.star_rounded,
                SettingsIconColors.red,
              ),
              toggle(
                l10n?.showAnniversaryDays ?? 'Show Anniversary Days',
                StorageKeys.showAnniversaryDays,
                settings.showAnniversaryDays,
                Icons.celebration_outlined,
                SettingsIconColors.teal,
              ),
              toggle(
                l10n?.showSabbath ?? 'Show Sabbath',
                StorageKeys.showSabbaths,
                settings.showSabbaths,
                Icons.temple_buddhist_outlined,
                SettingsIconColors.amber,
              ),
              toggle(
                l10n?.showAstrology ?? 'Show Astrology',
                StorageKeys.showAstrology,
                settings.showAstrology,
                Icons.auto_awesome_outlined,
                SettingsIconColors.purple,
              ),
            ],
          ),
          AppGroup(
            label: 'Dates',
            footer:
                l10n?.preferShanYearDescription ??
                'Prefer Shan year: show the Shan calendar year instead of '
                    'the Myanmar year when the calendar language is Shan.',
            children: [
              toggle(
                l10n?.showWesternDates ?? 'Show Western Dates',
                StorageKeys.showWesternDates,
                settings.showWesternDates,
                Icons.event_outlined,
                SettingsIconColors.blue,
              ),
              toggle(
                l10n?.showMyanmarDates ?? 'Show Myanmar Dates',
                StorageKeys.showMyanmarDates,
                settings.showMyanmarDates,
                Icons.calendar_month_outlined,
                SettingsIconColors.indigo,
              ),
              toggle(
                l10n?.preferShanYear ?? 'Prefer Shan Year',
                StorageKeys.showShanCalendar,
                settings.showShanCalendar,
                Icons.calendar_view_month_outlined,
                SettingsIconColors.gray,
              ),
            ],
          ),
        ];
      },
    );
  }
}
