import 'dart:io';

import 'package:core/core.dart';
import 'package:firebase_analytics_app/firebase_analytics_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localizations/l10n/app_localizations.dart';
import 'package:settings/settings.dart';

import '../../di/settings_injection.dart';
import '../widgets/reset_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();

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
            actions: [
              if (kDebugMode)
                IconButton(
                  onPressed: () =>
                      GoRouter.of(context).push('/widget-preview/generate'),
                  icon: const Icon(Icons.preview_outlined),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                AppLocalizations.of(context)?.settings ?? 'Settings',
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
                SectionHeader(title: 'General'),
                BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    final settings = state is SettingsLoaded
                        ? state.settings
                        : null;
                    final themeMode = settings?.themeMode ?? ThemeMode.system;
                    return SettingsListTile(
                      title:
                          AppLocalizations.of(context)?.appearance ??
                          'Appearance',
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
                    final calendarLanguage =
                        settings?.calendarLanguage.name.capitalize ?? 'English';

                    return SettingsListTile(
                      title:
                          AppLocalizations.of(context)?.language ?? 'Language',
                      trailing: '$language / $calendarLanguage',
                      icon: Icons.language_outlined,
                      onTap: () => GoRouter.of(
                        context,
                      ).go('/settings/${RoutePaths.languageSettings}'),
                    );
                  },
                ),

                // Calendar section
                SectionHeader(title: 'Calendar'),
                BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    final settings = state is SettingsLoaded
                        ? state.settings
                        : null;

                    final sasanaYearType =
                        settings?.calendarConfig.sasanaYearType ?? 0;
                    final calendarType =
                        settings?.calendarConfig.calendarType ?? 0;
                    final timezoneOffset =
                        settings?.calendarConfig.timezoneOffset ?? 6.5;

                    return SettingsListTile(
                      title:
                          AppLocalizations.of(
                            context,
                          )?.calendar_configuration ??
                          'Calendar Configuration',
                      trailing:
                          '$calendarType / $sasanaYearType / $timezoneOffset',
                      icon: Icons.edit_calendar,
                      onTap: () => GoRouter.of(
                        context,
                      ).go('/settings/${RoutePaths.calendarConfig}'),
                    );
                  },
                ),
                SettingsListTile(
                  title:
                      AppLocalizations.of(context)?.display_preferences ??
                      'Display Preferences',
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
                  SectionHeader(title: 'Home Widgets'),
                  SettingsListTile(
                    title: 'Widget Settings',
                    trailing: '',
                    icon: Icons.widgets_outlined,
                    onTap: () => GoRouter.of(
                      context,
                    ).go('/settings/${RoutePaths.widgets}'),
                  ),
                ],

                SectionHeader(title: 'Others'),
                SettingsListTile(
                  title: 'Privacy & Data',
                  trailing: '',
                  icon: Icons.analytics_outlined,
                  onTap: () => GoRouter.of(
                    context,
                  ).go('/settings/${RoutePaths.privacyAndData}'),
                ),
                SettingsListTile(
                  title: 'About',
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
