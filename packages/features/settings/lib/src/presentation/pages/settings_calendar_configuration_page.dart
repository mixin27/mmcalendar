import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:settings/settings.dart';
import 'package:settings/src/di/settings_injection.dart';

import '../widgets/settings_widgets.dart';
import '../widgets/snackbar.dart';
import '../widgets/state_widgets.dart';

class SettingsCalendarConfigurationPage extends StatefulWidget {
  const SettingsCalendarConfigurationPage({super.key});

  @override
  State<SettingsCalendarConfigurationPage> createState() =>
      _SettingsCalendarConfigurationPageState();
}

class _SettingsCalendarConfigurationPageState
    extends State<SettingsCalendarConfigurationPage> {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  final RemoteConfigPort _remoteConfigPort = getIt<RemoteConfigPort>();
  bool _isRefreshingHolidayConfig = false;

  @override
  void initState() {
    _analyticsService.logScreenView(
      screenName: 'settings_calendar_configuration',
      screenClass: 'SettingsCalendarConfigurationPage',
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
                ).colorScheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.calendar_configuration ?? 'Calendar Configuration',
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
            return _SettingsCalendarConfigurationContent(
              settings: state.settings,
              isRefreshingHolidayConfig: _isRefreshingHolidayConfig,
              onForceRefreshHolidayConfig: _forceRefreshHolidayConfig,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _forceRefreshHolidayConfig() async {
    if (_isRefreshingHolidayConfig) return;

    _analyticsService.logButtonClick(
      buttonName: 'force_refresh_holiday_config',
      buttonLocation: 'settings_calendar_configuration',
    );

    setState(() {
      _isRefreshingHolidayConfig = true;
    });

    final fetchResult = await _remoteConfigPort.fetchAndActivate();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isRefreshingHolidayConfig = false;
    });

    if (fetchResult == RemoteFetchResult.failed) {
      showErrorSnackBar(
        context,
        l10n?.failedToFetchHolidayConfig ??
            'Failed to fetch holiday config from server.',
      );
      return;
    }

    context.read<SettingsBloc>().add(const LoadSettings());

    final holidayOverridesPort = getIt<HolidayOverridesPort>();
    final customCount = holidayOverridesPort.getCustomHolidays().length;
    final disabledCount = holidayOverridesPort.getDisabledHolidays().length;
    final fetchSummary = fetchResult == RemoteFetchResult.activated
        ? (l10n?.updated ?? 'updated')
        : (l10n?.noChanges ?? 'no changes');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.holidayConfigRefreshed(
                fetchSummary,
                customCount.toString(),
                disabledCount.toString(),
              ) ??
              'Holiday config refreshed ($fetchSummary). '
                  'Custom: $customCount, Disabled: $disabledCount',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SettingsCalendarConfigurationContent extends StatelessWidget {
  const _SettingsCalendarConfigurationContent({
    required this.settings,
    required this.onForceRefreshHolidayConfig,
    required this.isRefreshingHolidayConfig,
  });

  final AppSettingsEntity settings;
  final Future<void> Function() onForceRefreshHolidayConfig;
  final bool isRefreshingHolidayConfig;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          SettingsTile(
            title: l10n?.sasanaYearType ?? 'Sasana Year Type',
            subtitle:
                l10n?.typeValue(
                  settings.calendarConfig.sasanaYearType.toString(),
                ) ??
                'Type ${settings.calendarConfig.sasanaYearType}',
            leading: const Icon(Icons.auto_awesome),
            onTap: () => _showSasanaYearTypeDialog(context, settings),
          ),
          SettingsTile(
            title: l10n?.calendarType ?? 'Calendar Type',
            subtitle: _getCalendarTypeName(
              context,
              settings.calendarConfig.calendarType,
            ),
            leading: const Icon(Icons.event_note),
            onTap: () => _showCalendarTypeDialog(context, settings),
          ),
          SettingsTile(
            title: l10n?.timezoneOffset ?? 'Timezone Offset',
            subtitle:
                l10n?.hoursValue(
                  settings.calendarConfig.timezoneOffset.toString(),
                ) ??
                '${settings.calendarConfig.timezoneOffset} hours',
            leading: const Icon(Icons.access_time),
            onTap: () => _showTimezoneDialog(context, settings),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: Text(l10n?.holidayConfigRemote ?? 'Holiday Config (Remote)'),
            subtitle: Text(
              l10n?.forceRefreshHolidayConfigDescription ??
                  'Force refresh and apply holiday overrides from Remote Config',
            ),
            trailing: isRefreshingHolidayConfig
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onTap: isRefreshingHolidayConfig
                ? null
                : () => onForceRefreshHolidayConfig(),
          ),
        ],
      ),
    );
  }

  String _getCalendarTypeName(BuildContext context, int type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case 0:
        return l10n?.calendarTypeBritish ?? 'British';
      case 1:
        return l10n?.calendarTypeGregorian ?? 'Gregorian';
      case 2:
        return l10n?.calendarTypeJulian ?? 'Julian';
      default:
        return l10n?.unknown ?? 'Unknown';
    }
  }

  void _showSasanaYearTypeDialog(
    BuildContext context,
    AppSettingsEntity settings,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => EnhancedDialog(
        title: l10n?.sasanaYearType ?? 'Sasana Year Type',
        icon: Icons.auto_awesome,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioOption<int>(
              title: l10n?.typeValue('0') ?? 'Type 0',
              subtitle:
                  l10n?.defaultCalculationMethod ??
                  'Default calculation method',
              icon: Icons.looks_one,
              value: 0,
              groupValue: settings.calendarConfig.sasanaYearType,
              onChanged: (value) {
                _updateCalendarConfig(context, settings, sasanaYearType: value);
                Navigator.pop(dialogContext);
              },
            ),
            RadioOption<int>(
              title: l10n?.typeValue('1') ?? 'Type 1',
              subtitle:
                  l10n?.alternativeCalculationMethod ??
                  'Alternative calculation method',
              icon: Icons.looks_two,
              value: 1,
              groupValue: settings.calendarConfig.sasanaYearType,
              onChanged: (value) {
                _updateCalendarConfig(context, settings, sasanaYearType: value);
                Navigator.pop(dialogContext);
              },
            ),
            RadioOption<int>(
              title: l10n?.typeValue('2') ?? 'Type 2',
              subtitle:
                  l10n?.alternativeCalculationMethod ??
                  'Alternative calculation method',
              icon: Icons.looks_3,
              value: 2,
              groupValue: settings.calendarConfig.sasanaYearType,
              onChanged: (value) {
                _updateCalendarConfig(context, settings, sasanaYearType: value);
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCalendarTypeDialog(
    BuildContext context,
    AppSettingsEntity settings,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => EnhancedDialog(
        title: l10n?.calendarType ?? 'Calendar Type',
        icon: Icons.event_note,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioOption<int>(
              title: l10n?.calendarTypeBritish ?? 'British',
              subtitle:
                  l10n?.britishCalendarSystem ?? 'British calendar system',
              icon: Icons.flag,
              value: 0,
              groupValue: settings.calendarConfig.calendarType,
              onChanged: (value) {
                _updateCalendarConfig(context, settings, calendarType: value);
                Navigator.pop(dialogContext);
              },
            ),
            RadioOption<int>(
              title: l10n?.calendarTypeGregorian ?? 'Gregorian',
              subtitle:
                  l10n?.gregorianCalendarSystem ?? 'Gregorian calendar system',
              icon: Icons.calendar_month,
              value: 1,
              groupValue: settings.calendarConfig.calendarType,
              onChanged: (value) {
                _updateCalendarConfig(context, settings, calendarType: value);
                Navigator.pop(dialogContext);
              },
            ),
            RadioOption<int>(
              title: l10n?.calendarTypeJulian ?? 'Julian',
              subtitle: l10n?.julianCalendarSystem ?? 'Julian calendar system',
              icon: Icons.calendar_today,
              value: 2,
              groupValue: settings.calendarConfig.calendarType,
              onChanged: (value) {
                _updateCalendarConfig(context, settings, calendarType: value);
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTimezoneDialog(BuildContext context, AppSettingsEntity settings) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: settings.calendarConfig.timezoneOffset.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.access_time),
        title: Text(l10n?.timezoneOffset ?? 'Timezone Offset'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: l10n?.hours ?? 'Hours',
            hintText: (DateTime.now().timeZoneOffset.inMinutes.toDouble() / 60)
                .toString(),
            helperText:
                l10n?.timezoneOffsetExample ??
                'e.g., 6.5 for Myanmar Time (UTC+6:30)',
            prefixIcon: const Icon(Icons.schedule),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                _updateCalendarConfig(context, settings, timezoneOffset: value);
                Navigator.pop(dialogContext);
              }
            },
            child: Text(l10n?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }

  void _updateCalendarConfig(
    BuildContext context,
    AppSettingsEntity settings, {
    int? sasanaYearType,
    int? calendarType,
    double? timezoneOffset,
  }) {
    final newConfig = CalendarConfig(
      sasanaYearType: sasanaYearType ?? settings.calendarConfig.sasanaYearType,
      calendarType: calendarType ?? settings.calendarConfig.calendarType,
      gregorianStart: settings.calendarConfig.gregorianStart,
      timezoneOffset: timezoneOffset ?? settings.calendarConfig.timezoneOffset,
      defaultLanguage: settings.calendarConfig.defaultLanguage,
    );
    context.read<SettingsBloc>().add(UpdateCalendarConfiguration(newConfig));
  }
}
