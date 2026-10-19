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
          footer:
              l10n?.settingsAppLanguageFooter ?? 'Menus, buttons and messages.',
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
              l10n?.settingsCalendarLanguageFooter ??
              'Dates, month and weekday names, lunar days, holidays and moon '
                  'phases everywhere in the app, including widgets.',
          children: [
            for (final language in Language.values)
              AppRow(
                title: _calendarLanguageName(l10n, language),
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

/// A calendar language's name in the app language; Myanmar is always
/// written in Myanmar, as in the app language list.
String _calendarLanguageName(AppLocalizations? l10n, Language language) =>
    switch (language) {
      Language.english => l10n?.english ?? 'English',
      Language.myanmar => 'မြန်မာ',
      Language.zawgyi => l10n?.languageZawgyi ?? 'Zawgyi',
      Language.mon => l10n?.languageMon ?? 'Mon',
      Language.shan => l10n?.languageShan ?? 'Shan',
      Language.karen => l10n?.languageKaren ?? 'Karen',
    };
