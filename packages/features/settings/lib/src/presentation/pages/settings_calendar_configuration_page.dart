import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
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
              AppLocalizations.of(context)?.calendar_configuration ??
                  'Calendar Configuration',
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

    setState(() {
      _isRefreshingHolidayConfig = false;
    });

    if (fetchResult == RemoteFetchResult.failed) {
      showErrorSnackBar(context, 'Failed to fetch holiday config from server.');
      return;
    }

    context.read<SettingsBloc>().add(const LoadSettings());

    final holidayOverridesPort = getIt<HolidayOverridesPort>();
    final customCount = holidayOverridesPort.getCustomHolidays().length;
    final disabledCount = holidayOverridesPort.getDisabledHolidays().length;
    final fetchSummary = fetchResult == RemoteFetchResult.activated
        ? 'updated'
        : 'no changes';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
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
    return SingleChildScrollView(
      child: Column(
        children: [
          SettingsTile(
            title: 'Sasana Year Type',
            subtitle: 'Type ${settings.calendarConfig.sasanaYearType}',
            leading: const Icon(Icons.auto_awesome),
            onTap: () => _showSasanaYearTypeDialog(context, settings),
          ),
          SettingsTile(
            title: 'Calendar Type',
            subtitle: _getCalendarTypeName(
              settings.calendarConfig.calendarType,
            ),
            leading: const Icon(Icons.event_note),
            onTap: () => _showCalendarTypeDialog(context, settings),
          ),
          SettingsTile(
            title: 'Timezone Offset',
            subtitle: '${settings.calendarConfig.timezoneOffset} hours',
            leading: const Icon(Icons.access_time),
            onTap: () => _showTimezoneDialog(context, settings),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('Holiday Config (Remote)'),
            subtitle: const Text(
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

  String _getCalendarTypeName(int type) {
    switch (type) {
      case 0:
        return 'British';
      case 1:
        return 'Gregorian';
      case 2:
        return 'Julian';
      default:
        return 'Unknown';
    }
  }

  void _showSasanaYearTypeDialog(
    BuildContext context,
    AppSettingsEntity settings,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => EnhancedDialog(
        title: 'Sasana Year Type',
        icon: Icons.auto_awesome,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioOption<int>(
              title: 'Type 0',
              subtitle: 'Default calculation method',
              icon: Icons.looks_one,
              value: 0,
              groupValue: settings.calendarConfig.sasanaYearType,
              onChanged: (value) {
                _updateCalendarConfig(context, settings, sasanaYearType: value);
                Navigator.pop(dialogContext);
              },
            ),
            RadioOption<int>(
              title: 'Type 1',
              subtitle: 'Alternative calculation method',
              icon: Icons.looks_two,
              value: 1,
              groupValue: settings.calendarConfig.sasanaYearType,
              onChanged: (value) {
                _updateCalendarConfig(context, settings, sasanaYearType: value);
                Navigator.pop(dialogContext);
              },
            ),
            RadioOption<int>(
              title: 'Type 2',
              subtitle: 'Alternative calculation method',
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
    showDialog(
      context: context,
      builder: (dialogContext) => EnhancedDialog(
        title: 'Calendar Type',
        icon: Icons.event_note,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioOption<int>(
              title: 'British',
              subtitle: 'British calendar system',
              icon: Icons.flag,
              value: 0,
              groupValue: settings.calendarConfig.calendarType,
              onChanged: (value) {
                _updateCalendarConfig(context, settings, calendarType: value);
                Navigator.pop(dialogContext);
              },
            ),
            RadioOption<int>(
              title: 'Gregorian',
              subtitle: 'Gregorian calendar system',
              icon: Icons.calendar_month,
              value: 1,
              groupValue: settings.calendarConfig.calendarType,
              onChanged: (value) {
                _updateCalendarConfig(context, settings, calendarType: value);
                Navigator.pop(dialogContext);
              },
            ),
            RadioOption<int>(
              title: 'Julian',
              subtitle: 'Julian calendar system',
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
    final controller = TextEditingController(
      text: settings.calendarConfig.timezoneOffset.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.access_time),
        title: const Text('Timezone Offset'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: 'Hours',
            hintText: (DateTime.now().timeZoneOffset.inMinutes.toDouble() / 60)
                .toString(),
            helperText: 'e.g., 6.5 for Myanmar Time (UTC+6:30)',
            prefixIcon: Icon(Icons.schedule),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                _updateCalendarConfig(context, settings, timezoneOffset: value);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
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
