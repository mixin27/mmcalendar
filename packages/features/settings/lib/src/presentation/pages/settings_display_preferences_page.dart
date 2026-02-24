import 'package:shared_core/shared_core.dart';
import 'package:integrations_firebase/integrations_firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:settings/settings.dart';
import 'package:settings/src/di/settings_injection.dart';

import '../widgets/settings_widgets.dart';
import '../widgets/snackbar.dart';
import '../widgets/state_widgets.dart';

class SettingsDisplayPreferencesPage extends StatefulWidget {
  const SettingsDisplayPreferencesPage({super.key});

  @override
  State<SettingsDisplayPreferencesPage> createState() =>
      _SettingsDisplayPreferencesPageState();
}

class _SettingsDisplayPreferencesPageState
    extends State<SettingsDisplayPreferencesPage> {
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();

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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.display_settings_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.display_preferences ??
                  'Display Preferences',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            showErrorSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is SettingsInitial) {
            context.read<SettingsBloc>().add(const LoadSettings());
            return const LoadingView();
          }

          if (state is SettingsLoading) {
            return const LoadingView();
          }

          if (state is SettingsError) {
            return ErrorView(
              message: state.message,
              onRetry: () {
                context.read<SettingsBloc>().add(const LoadSettings());
              },
            );
          }

          if (state is SettingsLoaded) {
            return _SettingsDisplayPreferencesContent(settings: state.settings);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SettingsDisplayPreferencesContent extends StatelessWidget {
  const _SettingsDisplayPreferencesContent({required this.settings});

  final AppSettingsEntity settings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AnimatedSwitchTile(
            title: 'Show Holidays',
            subtitle: 'Display holiday indicators',
            icon: Icons.public_off,
            iconColor: Colors.red.shade700,
            value: settings.showHolidays,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                ToggleDisplayPreference(StorageKeys.showHolidays, value),
              );
            },
          ),
          AnimatedSwitchTile(
            title: 'Show Anniversary Days',
            subtitle: 'Display anniversary days indicators',
            icon: Icons.celebration,
            iconColor: Colors.teal.shade700,
            value: settings.showAnniversaryDays,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                ToggleDisplayPreference(StorageKeys.showAnniversaryDays, value),
              );
            },
          ),
          AnimatedSwitchTile(
            title: 'Show Sabbath',
            subtitle: 'Display sabbath indicators',
            icon: Icons.temple_buddhist,
            iconColor: Colors.amber.shade700,
            value: settings.showSabbaths,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                ToggleDisplayPreference(StorageKeys.showSabbaths, value),
              );
            },
          ),
          AnimatedSwitchTile(
            title: 'Show Astrology',
            subtitle: 'Display astrological indicators',
            icon: Icons.star,
            iconColor: Colors.deepPurple.shade700,
            value: settings.showAstrology,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                ToggleDisplayPreference(StorageKeys.showAstrology, value),
              );
            },
          ),
          AnimatedSwitchTile(
            title: 'Show Western Dates',
            subtitle: 'Display Western calendar dates',
            icon: Icons.event,
            value: settings.showWesternDates,
            useIcon: true,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                ToggleDisplayPreference(StorageKeys.showWesternDates, value),
              );
            },
          ),
          AnimatedSwitchTile(
            title: 'Show Myanmar Dates',
            subtitle: 'Display Myanmar calendar dates',
            icon: Icons.calendar_month,
            value: settings.showMyanmarDates,
            useIcon: true,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                ToggleDisplayPreference(StorageKeys.showMyanmarDates, value),
              );
            },
          ),
          AnimatedSwitchTile(
            title: 'Prefer Shan Year',
            subtitle:
                'Display Shan calendar year instead of Myanmar year in Shan language',
            icon: Icons.calendar_month,
            value: settings.showShanCalendar,
            useIcon: true,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                ToggleDisplayPreference(StorageKeys.showShanCalendar, value),
              );
            },
          ),
        ],
      ),
    );
  }
}
