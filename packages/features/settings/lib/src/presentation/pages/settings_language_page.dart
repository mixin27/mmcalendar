import 'package:core/core.dart';
import 'package:firebase_analytics_app/firebase_analytics_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:localizations/localizations.dart';
import 'package:settings/settings.dart';
import 'package:settings/src/di/settings_injection.dart';

import '../widgets/settings_widgets.dart';
import '../widgets/snackbar.dart';
import '../widgets/state_widgets.dart';

class SettingsLanguagePage extends StatefulWidget {
  const SettingsLanguagePage({super.key});

  @override
  State<SettingsLanguagePage> createState() => _SettingsLanguagePageState();
}

class _SettingsLanguagePageState extends State<SettingsLanguagePage> {
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();

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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.language_outlined,
                color: colorScheme.secondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.language ?? 'Language',
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
            return _SettingsLanguageContent(settings: state.settings);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SettingsLanguageContent extends StatelessWidget {
  const _SettingsLanguageContent({required this.settings});

  final AppSettingsEntity settings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SettingsTile(
            title: 'App Language',
            subtitle: settings.appLanguage == 'en' ? 'English' : 'Myanmar',
            leading: const Icon(Icons.translate),
            onTap: () => _showAppLanguageDialog(context, settings),
          ),
          SettingsTile(
            title: 'Calendar Language',
            subtitle: settings.calendarLanguage.name.capitalize,
            leading: const Icon(Icons.calendar_today),
            onTap: () => _showCalendarLanguageDialog(context, settings),
          ),
        ],
      ),
    );
  }

  void _showAppLanguageDialog(
    BuildContext context,
    AppSettingsEntity settings,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => EnhancedDialog(
        title: 'App Language',
        icon: Icons.translate,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioOption<String>(
              title: 'English',
              subtitle: 'Display app in English',
              icon: Icons.language,
              value: 'en',
              groupValue: settings.appLanguage,
              onChanged: (value) {
                context.read<SettingsBloc>().add(ChangeAppLanguage(value!));
                Navigator.pop(dialogContext);
              },
            ),
            RadioOption<String>(
              title: 'Myanmar',
              subtitle: 'Display app in Myanmar',
              icon: Icons.language,
              value: 'my',
              groupValue: settings.appLanguage,
              onChanged: (value) {
                context.read<SettingsBloc>().add(ChangeAppLanguage(value!));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCalendarLanguageDialog(
    BuildContext context,
    AppSettingsEntity settings,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => EnhancedDialog(
        title: 'Calendar Language',
        icon: Icons.calendar_today,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: Language.values.map((language) {
              return RadioOption<Language>(
                title: language.name.capitalize,
                subtitle: 'Display calendar in ${language.name}',
                icon: Icons.calendar_month,
                value: language,
                groupValue: settings.calendarLanguage,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(
                    ChangeCalendarLanguage(value!),
                  );
                  Navigator.pop(dialogContext);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
