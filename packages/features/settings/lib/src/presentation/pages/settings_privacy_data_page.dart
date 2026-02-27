import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:settings/settings.dart';
import 'package:settings/src/di/settings_injection.dart';
import 'package:shared_localizations/shared_localizations.dart';

import '../widgets/settings_widgets.dart';
import '../widgets/snackbar.dart';
import '../widgets/state_widgets.dart';

class SettingsPrivacyDataPage extends StatefulWidget {
  const SettingsPrivacyDataPage({super.key});

  @override
  State<SettingsPrivacyDataPage> createState() =>
      _SettingsPrivacyDataPageState();
}

class _SettingsPrivacyDataPageState extends State<SettingsPrivacyDataPage> {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();

  @override
  void initState() {
    _analyticsService.logScreenView(
      screenName: 'settings_privacy_data',
      screenClass: 'SettingsPrivacyDataPage',
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                Icons.privacy_tip_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.privacyAndData ?? 'Privacy & Data',
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
            return _SettingsPrivacyDataContent(settings: state.settings);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SettingsPrivacyDataContent extends StatelessWidget {
  const _SettingsPrivacyDataContent({required this.settings});

  final AppSettingsEntity settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          AnimatedSwitchTile(
            title: l10n?.analytics ?? 'Analytics',
            subtitle:
                l10n?.helpImproveBySharingAnalytics ??
                'Help improve the app by sharing usage analytics',
            icon: Icons.analytics_outlined,
            iconColor: Colors.blue,
            value: settings.enableAnalytics,
            useIcon: true,
            onChanged: (value) {
              context.read<SettingsBloc>().add(UpdateAnalyticsConsent(value));
            },
          ),
          AnimatedSwitchTile(
            title: l10n?.crashReports ?? 'Crash Reports',
            subtitle:
                l10n?.sendCrashReportsToHelpFixIssues ??
                'Send crash reports to help fix issues',
            icon: Icons.bug_report_outlined,
            iconColor: Colors.orange,
            value: settings.enableCrashlytics,
            useIcon: true,
            onChanged: (value) {
              context.read<SettingsBloc>().add(UpdateCrashlyticsConsent(value));
            },
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n?.privacyDataUsageDescription ??
                    'This data is used only for app improvement and is never shared with third parties.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
