import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:settings/settings.dart';
import 'package:settings/src/di/settings_injection.dart';
import 'package:shared_localizations/shared_localizations.dart';

import '../widgets/settings_widgets.dart';

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
    return SettingsSubPage(
      title: l10n?.privacyAndData ?? 'Privacy & Data',
      builder: (context, settings) => [
        AppGroup(
          footer:
              l10n?.privacyDataUsageDescription ??
              'This data is used only for app improvement and is never '
                  'shared with third parties.',
          children: [
            AppRow.toggle(
              title: l10n?.analytics ?? 'Analytics',
              subtitle:
                  l10n?.helpImproveBySharingAnalytics ??
                  'Help improve the app by sharing usage analytics',
              icon: Icons.insights_outlined,
              iconColor: SettingsIconColors.blue,
              value: settings.enableAnalytics,
              onChanged: (value) => context.read<SettingsBloc>().add(
                UpdateAnalyticsConsent(value),
              ),
            ),
            AppRow.toggle(
              title: l10n?.crashReports ?? 'Crash Reports',
              subtitle:
                  l10n?.sendCrashReportsToHelpFixIssues ??
                  'Send crash reports to help fix issues',
              icon: Icons.bug_report_outlined,
              iconColor: SettingsIconColors.red,
              value: settings.enableCrashlytics,
              onChanged: (value) => context.read<SettingsBloc>().add(
                UpdateCrashlyticsConsent(value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
