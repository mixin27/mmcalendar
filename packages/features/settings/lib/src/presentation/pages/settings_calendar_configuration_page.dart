import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:settings/settings.dart';
import 'package:settings/src/di/settings_injection.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../widgets/settings_widgets.dart';

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
    return SettingsSubPage(
      title: l10n?.calendar_configuration ?? 'Calendar Configuration',
      builder: (context, settings) => _CalendarConfigurationGroups(
        settings: settings,
        onForceRefreshHolidayConfig: _forceRefreshHolidayConfig,
        isRefreshingHolidayConfig: _isRefreshingHolidayConfig,
      ).build(context),
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
      context.showToast(
        l10n?.failedToFetchHolidayConfig ??
            'Failed to fetch holiday config from server.',
        kind: AppToastKind.error,
      );
      return;
    }

    context.read<SettingsBloc>().add(const LoadSettings());

    final holidayOverridesPort = getIt<HolidayOverridesPort>();
    final customCount = holidayOverridesPort.getCustomHolidayRules().length;
    final disabledCount = holidayOverridesPort.getDisabledHolidays().length;
    final fetchSummary = fetchResult == RemoteFetchResult.activated
        ? (l10n?.updated ?? 'updated')
        : (l10n?.noChanges ?? 'no changes');

    context.showToast(
      l10n?.holidayConfigRefreshed(
            fetchSummary,
            customCount.toString(),
            disabledCount.toString(),
          ) ??
          'Holiday config refreshed ($fetchSummary). '
              'Custom: $customCount, Disabled: $disabledCount',
      kind: AppToastKind.success,
    );
  }
}

/// The page's groups, built from the loaded settings.
class _CalendarConfigurationGroups {
  const _CalendarConfigurationGroups({
    required this.settings,
    required this.onForceRefreshHolidayConfig,
    required this.isRefreshingHolidayConfig,
  });

  final AppSettingsEntity settings;
  final Future<void> Function() onForceRefreshHolidayConfig;
  final bool isRefreshingHolidayConfig;

  List<Widget> build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sasana = settings.calendarConfig.sasanaYearType;
    final runtimeOffset = settings.useDeviceTimezone
        ? getDeviceTimezoneOffsetHours()
        : kMyanmarTimezoneOffset;
    return [
      AppGroup(
        label: l10n?.sasanaYearType ?? 'Sasana Year Type',
        children: [
          for (final type in const [0, 1, 2])
            AppRow(
              title: l10n?.typeValue('$type') ?? 'Type $type',
              subtitle: type == 0
                  ? (l10n?.defaultCalculationMethod ??
                        'Default calculation method')
                  : (l10n?.alternativeCalculationMethod ??
                        'Alternative calculation method'),
              selected: sasana == type,
              onTap: () => _updateCalendarConfig(
                context,
                settings,
                sasanaYearType: type,
              ),
            ),
        ],
      ),
      AppGroup(
        label: 'Time',
        children: [
          AppRow(
            icon: Icons.lock_outline,
            iconColor: SettingsIconColors.gray,
            title: l10n?.calendarType ?? 'Calendar Type',
            value: _getCalendarTypeName(context, 0),
          ),
          AppRow.toggle(
            icon: Icons.access_time,
            iconColor: SettingsIconColors.blue,
            title: 'Use Device Timezone',
            value: settings.useDeviceTimezone,
            onChanged: (value) => context.read<SettingsBloc>().add(
              ToggleDisplayPreference(StorageKeys.useDeviceTimezone, value),
            ),
          ),
          AppRow(
            icon: Icons.schedule,
            iconColor: SettingsIconColors.indigo,
            title: l10n?.timezoneOffset ?? 'Timezone Offset',
            value: _formatUtcOffset(runtimeOffset),
          ),
        ],
      ),
      AppGroup(
        label: l10n?.holidayConfigRemote ?? 'Holiday Config (Remote)',
        footer:
            l10n?.forceRefreshHolidayConfigDescription ??
            'Force refresh and apply holiday overrides from Remote Config',
        children: [
          AppRow(
            title: 'Refresh holiday data',
            tone: AppRowTone.accent,
            trailing: isRefreshingHolidayConfig
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: isRefreshingHolidayConfig
                ? null
                : () => onForceRefreshHolidayConfig(),
          ),
        ],
      ),
    ];
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

  void _updateCalendarConfig(
    BuildContext context,
    AppSettingsEntity settings, {
    int? sasanaYearType,
  }) {
    final newConfig = CalendarConfig(
      sasanaYearType: sasanaYearType ?? settings.calendarConfig.sasanaYearType,
      calendarType: 0,
      gregorianStart: settings.calendarConfig.gregorianStart,
      timezoneOffset: kMyanmarTimezoneOffset,
      defaultLanguage: settings.calendarConfig.defaultLanguage,
    );
    context.read<SettingsBloc>().add(UpdateCalendarConfiguration(newConfig));
  }

  String _formatUtcOffset(double offset) {
    final sign = offset >= 0 ? '+' : '-';
    final absoluteOffset = offset.abs();
    var hours = absoluteOffset.floor();
    var minutes = ((absoluteOffset - hours) * 60).round();
    if (minutes == 60) {
      hours += 1;
      minutes = 0;
    }
    return 'UTC$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
