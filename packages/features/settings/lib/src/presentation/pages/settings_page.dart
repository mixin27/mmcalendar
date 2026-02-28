import 'dart:io';

import 'package:shared_core/shared_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:settings/settings.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/settings_injection.dart';
import '../widgets/reset_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView(
      screenName: 'settings',
      screenClass: 'SettingsPage',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n?.settings ?? 'Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.colorScheme.primaryContainer,
                      context.colorScheme.primaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Settings Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SectionHeader(title: l10n?.general ?? 'General'),
                BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    final settings = state is SettingsLoaded
                        ? state.settings
                        : null;
                    final themeMode = settings?.themeMode ?? ThemeMode.system;
                    return SettingsListTile(
                      title: l10n?.appearance ?? 'Appearance',
                      trailing: themeMode.name.capitalize,
                      icon: Icons.palette_outlined,
                      onTap: () => GoRouter.of(
                        context,
                      ).go('/settings/${RoutePaths.themeSettings}'),
                    );
                  },
                ),
                BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    final settings = state is SettingsLoaded
                        ? state.settings
                        : null;
                    final language = settings?.appLanguage ?? 'en';
                    final appLanguageName = language == 'en'
                        ? (l10n?.english ?? 'English')
                        : (l10n?.myanmar ?? 'Myanmar');
                    final calendarLanguage =
                        settings?.calendarLanguage.name.capitalize ?? 'English';

                    return SettingsListTile(
                      title: l10n?.language ?? 'Language',
                      trailing: '$appLanguageName / $calendarLanguage',
                      icon: Icons.language_outlined,
                      onTap: () => GoRouter.of(
                        context,
                      ).go('/settings/${RoutePaths.languageSettings}'),
                    );
                  },
                ),

                // Calendar section
                SectionHeader(title: l10n?.calendar ?? 'Calendar'),
                BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    final settings = state is SettingsLoaded
                        ? state.settings
                        : null;

                    final useDeviceTimezone =
                        settings?.useDeviceTimezone ?? true;
                    final timezoneOffset = useDeviceTimezone
                        ? getDeviceTimezoneOffsetHours()
                        : kMyanmarTimezoneOffset;
                    final timezoneSource = useDeviceTimezone ? 'device' : 'MMT';

                    return SettingsListTile(
                      title:
                          l10n?.calendar_configuration ??
                          'Calendar Configuration',
                      trailing:
                          'tz: ${timezoneOffset.toStringAsFixed(1)} ($timezoneSource)',
                      icon: Icons.edit_calendar,
                      onTap: () => GoRouter.of(
                        context,
                      ).go('/settings/${RoutePaths.calendarConfig}'),
                    );
                  },
                ),
                SettingsListTile(
                  title: l10n?.display_preferences ?? 'Display Preferences',
                  trailing: '',
                  icon: Icons.display_settings_outlined,
                  onTap: () => GoRouter.of(
                    context,
                  ).go('/settings/${RoutePaths.displayPreferences}'),
                ),

                // todo(mixin27): remove conditional when home_widgets configured
                // in ios
                // Home Screen Widget Section
                if (!kIsWeb && Platform.isAndroid) ...[
                  SectionHeader(title: l10n?.homeWidgets ?? 'Home Widgets'),
                  SettingsListTile(
                    title: l10n?.widgetSettings ?? 'Widget Settings',
                    trailing: '',
                    icon: Icons.widgets_outlined,
                    onTap: () => GoRouter.of(
                      context,
                    ).go('/settings/${RoutePaths.widgets}'),
                  ),
                ],

                SectionHeader(title: l10n?.others ?? 'Others'),
                SettingsListTile(
                  title: l10n?.privacyAndData ?? 'Privacy & Data',
                  trailing: '',
                  icon: Icons.analytics_outlined,
                  onTap: () => GoRouter.of(
                    context,
                  ).go('/settings/${RoutePaths.privacyAndData}'),
                ),
                SettingsListTile(
                  title: l10n?.appUpdates ?? 'App Updates',
                  trailing: '',
                  icon: Icons.system_update_alt_outlined,
                  onTap: () => GoRouter.of(
                    context,
                  ).go('/settings/${RoutePaths.appUpdate}'),
                ),
                SettingsListTile(
                  title: l10n?.about ?? 'About',
                  trailing: '',
                  icon: Icons.info_outline,
                  onTap: () =>
                      GoRouter.of(context).go('/settings/${RoutePaths.about}'),
                ),

                ResetButton(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
