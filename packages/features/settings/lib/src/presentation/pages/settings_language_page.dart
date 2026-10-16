import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:settings/settings.dart';
import 'package:settings/src/di/settings_injection.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../widgets/settings_widgets.dart';

class SettingsLanguagePage extends StatefulWidget {
  const SettingsLanguagePage({super.key});

  @override
  State<SettingsLanguagePage> createState() => _SettingsLanguagePageState();
}

class _SettingsLanguagePageState extends State<SettingsLanguagePage> {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();

  @override
  void initState() {
    _analyticsService.logScreenView(
      screenName: 'settings_language',
      screenClass: 'SettingsLanguagePage',
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSubPage(
      title: l10n?.language ?? 'Language',
      builder: (context, settings) => [
        AppGroup(
          label: l10n?.appLanguage ?? 'App Language',
          children: [
            for (final (code, name) in [
              ('en', l10n?.english ?? 'English'),
              ('my', 'မြန်မာ'),
            ])
              AppRow(
                title: name,
                selected: settings.appLanguage == code,
                onTap: () =>
                    context.read<SettingsBloc>().add(ChangeAppLanguage(code)),
              ),
          ],
        ),
        AppGroup(
          label: l10n?.calendarLanguage ?? 'Calendar Language',
          footer:
              'Changes month names, lunar days and weekdays across the app.',
          children: [
            for (final language in Language.values)
              AppRow(
                title: language == Language.myanmar
                    ? 'မြန်မာ'
                    : language.name.capitalize,
                selected: settings.calendarLanguage == language,
                onTap: () => context.read<SettingsBloc>().add(
                  ChangeCalendarLanguage(language),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
