import 'dart:io';

import 'package:shared_core/shared_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:settings/settings.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';
import 'package:telegram_web/telegram_web.dart';

import '../../di/settings_injection.dart';
import '../widgets/settings_widgets.dart';

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

  String? get _telegramUserName => getIt.isRegistered<TelegramService>()
      ? getIt<TelegramService>().getUserName()
      : null;

  void _open(String path) => GoRouter.of(context).go('/settings/$path');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final settings = state is SettingsLoaded ? state.settings : null;
        final language = settings?.appLanguage ?? 'en';
        final appLanguageName = language == 'en'
            ? (l10n?.english ?? 'English')
            : (l10n?.myanmar ?? 'Myanmar');
        final useDeviceTimezone = settings?.useDeviceTimezone ?? true;
        final offset = useDeviceTimezone
            ? getDeviceTimezoneOffsetHours()
            : kMyanmarTimezoneOffset;
        final showWidgets = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

        return AppPage(
          title: l10n?.settings ?? 'Settings',
          children: [
            // Inside Telegram: the signed-in user (was an extra bar above
            // every tab).
            if (_telegramUserName case final name?)
              AppGroup(
                children: [
                  AppRow(
                    icon: Icons.send_rounded,
                    iconColor: SettingsIconColors.teal,
                    title: 'Telegram',
                    value: l10n?.telegramUserLabel(name) ?? 'TG: $name',
                  ),
                ],
              ),
            AppGroup(
              label: l10n?.general ?? 'General',
              children: [
                AppRow(
                  icon: Icons.palette_outlined,
                  iconColor: SettingsIconColors.indigo,
                  title: l10n?.appearance ?? 'Appearance',
                  value: switch (settings?.themeMode ?? ThemeMode.system) {
                    ThemeMode.light => l10n?.light ?? 'Light',
                    ThemeMode.dark => l10n?.dark ?? 'Dark',
                    ThemeMode.system => l10n?.system ?? 'System',
                  },
                  chevron: true,
                  onTap: () => _open(RoutePaths.themeSettings),
                ),
                AppRow(
                  icon: Icons.language_outlined,
                  iconColor: SettingsIconColors.blue,
                  title: l10n?.language ?? 'Language',
                  value: appLanguageName,
                  chevron: true,
                  onTap: () => _open(RoutePaths.languageSettings),
                ),
              ],
            ),
            AppGroup(
              label: l10n?.calendar ?? 'Calendar',
              children: [
                AppRow(
                  icon: Icons.event_note_outlined,
                  iconColor: SettingsIconColors.red,
                  title:
                      l10n?.calendar_configuration ?? 'Calendar Configuration',
                  value: 'UTC${offset >= 0 ? '+' : ''}${_formatOffset(offset)}',
                  chevron: true,
                  onTap: () => _open(RoutePaths.calendarConfig),
                ),
                AppRow(
                  icon: Icons.edit_calendar_outlined,
                  iconColor: SettingsIconColors.purple,
                  title: l10n?.calendarStudio ?? 'Calendar Studio',
                  value:
                      l10n?.settingsCalendarStudioValue ?? 'Design and print',
                  chevron: true,
                  onTap: () => GoRouter.of(context).push(RoutePaths.studio),
                ),
                AppRow(
                  icon: Icons.tune_rounded,
                  iconColor: SettingsIconColors.green,
                  title: l10n?.display_preferences ?? 'Display Preferences',
                  chevron: true,
                  onTap: () => _open(RoutePaths.displayPreferences),
                ),
                if (showWidgets)
                  AppRow(
                    icon: Icons.widgets_outlined,
                    iconColor: SettingsIconColors.orange,
                    title: l10n?.widgetSettings ?? 'Widget Settings',
                    chevron: true,
                    onTap: () => _open(RoutePaths.widgets),
                  ),
              ],
            ),
            AppGroup(
              label: l10n?.others ?? 'Others',
              children: [
                AppRow(
                  icon: Icons.shield_outlined,
                  iconColor: SettingsIconColors.gray,
                  title: l10n?.privacyAndData ?? 'Privacy & Data',
                  chevron: true,
                  onTap: () => _open(RoutePaths.privacyAndData),
                ),
                AppRow(
                  icon: Icons.system_update_alt_outlined,
                  iconColor: SettingsIconColors.blue,
                  title: l10n?.appUpdates ?? 'App Updates',
                  chevron: true,
                  onTap: () => _open(RoutePaths.appUpdate),
                ),
                AppRow(
                  icon: Icons.info_outline,
                  iconColor: SettingsIconColors.gray,
                  title: l10n?.about ?? 'About',
                  chevron: true,
                  onTap: () => _open(RoutePaths.about),
                ),
              ],
            ),
            AppGroup(
              children: [
                AppRow(
                  title: l10n?.resetAllSettings ?? 'Reset All Settings',
                  tone: AppRowTone.destructive,
                  onTap: () => _confirmReset(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static String _formatOffset(double hours) {
    final minutes = (hours.abs() * 60).round();
    final h = minutes ~/ 60, m = minutes % 60;
    final sign = hours < 0 ? '-' : '';
    return m == 0 ? '$sign$h' : '$sign$h:${'$m'.padLeft(2, '0')}';
  }

  Future<void> _confirmReset(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SettingsBloc>();
    final confirmed = await showAppConfirm(
      context: context,
      title: l10n?.resetSettingsQuestion ?? 'Reset Settings?',
      message:
          l10n?.resetSettingsConfirmation ??
          'This will reset all settings to their default values. '
              'This action cannot be undone.',
      confirmLabel: l10n?.reset ?? 'Reset',
      cancelLabel: l10n?.cancel ?? 'Cancel',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    bloc.add(const ResetAllSettings());
    context.showToast(
      l10n?.settingsResetSuccessfully ?? 'Settings reset successfully',
      kind: AppToastKind.success,
    );
  }
}
