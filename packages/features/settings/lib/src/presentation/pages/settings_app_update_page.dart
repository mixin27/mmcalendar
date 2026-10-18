import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/settings_injection.dart';

class SettingsAppUpdatePage extends StatefulWidget {
  const SettingsAppUpdatePage({super.key, this.appVersion});

  final String? appVersion;

  @override
  State<SettingsAppUpdatePage> createState() => _SettingsAppUpdatePageState();
}

class _SettingsAppUpdatePageState extends State<SettingsAppUpdatePage> {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  final AppUpdatePort _appUpdatePort = getIt<AppUpdatePort>();

  AppUpdateInfo? _lastUpdateInfo;
  DateTime? _lastCheckedAt;
  bool _isChecking = false;

  @override
  void initState() {
    _analyticsService.logScreenView(
      screenName: 'settings_app_update',
      screenClass: 'SettingsAppUpdatePage',
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final updateInfo = _lastUpdateInfo;

    return AppPage(
      title: l10n?.appUpdates ?? 'App Updates',
      previousTitle: l10n?.settings ?? 'Settings',
      children: [
        AppGroup(
          children: [
            AppRow(
              title: l10n?.currentVersion ?? 'Current Version',
              value: widget.appVersion ?? AppConstants.appVersion,
            ),
          ],
        ),
        if (updateInfo != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _availabilityLabel(updateInfo.availability),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: updateInfo.hasUpdate ? t.accent : t.label,
                    ),
                  ),
                  if (_lastCheckedAt != null)
                    Text(
                      l10n?.lastCheckedAt(
                            _formatDateTime(context, _lastCheckedAt!),
                          ) ??
                          'Last checked: ${_formatDateTime(context, _lastCheckedAt!)}',
                      style: TextStyle(fontSize: 12.5, color: t.secondaryLabel),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.latestVersionWithBuild(
                          updateInfo.latestVersion,
                          updateInfo.latestBuildNumber.toString(),
                        ) ??
                        'Latest: ${updateInfo.latestVersion} (${updateInfo.latestBuildNumber})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    updateInfo.message,
                    style: TextStyle(color: t.secondaryLabel),
                  ),
                  if ((updateInfo.releaseNotes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      l10n?.releaseNotes ?? 'Release Notes',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(updateInfo.releaseNotes!),
                  ],
                  if (updateInfo.hasUpdate) ...[
                    const SizedBox(height: 12),
                    AppButton(
                      label: l10n?.openStore ?? 'Open Store',
                      icon: Icons.open_in_new,
                      compact: true,
                      expand: false,
                      onPressed: _isChecking
                          ? null
                          : () => _launchUpdate(updateInfo),
                    ),
                  ],
                ],
              ),
            ),
          ),
        AppGroup(
          children: [
            AppRow(
              title: l10n?.checkForUpdates ?? 'Check for Updates',
              subtitle:
                  l10n?.useCurrentRemoteConfigValues ??
                  'Use current remote config values',
              tone: AppRowTone.accent,
              trailing: _isChecking
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _isChecking
                  ? null
                  : () => _checkForUpdates(forceRefresh: false),
            ),
            AppRow(
              title:
                  l10n?.forceRefreshUpdateConfig ??
                  'Force Refresh Update Config',
              subtitle:
                  l10n?.fetchRemoteConfigNowAndCheckAgain ??
                  'Fetch remote config now and check again',
              tone: AppRowTone.accent,
              onTap: _isChecking
                  ? null
                  : () => _checkForUpdates(forceRefresh: true),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _checkForUpdates({required bool forceRefresh}) async {
    if (_isChecking) return;

    _analyticsService.logButtonClick(
      buttonName: forceRefresh
          ? 'force_refresh_update_config'
          : 'check_for_updates',
      buttonLocation: 'settings_app_update',
    );

    setState(() {
      _isChecking = true;
    });

    final updateInfo = await _appUpdatePort.checkForUpdate(
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;

    setState(() {
      _isChecking = false;
      _lastUpdateInfo = updateInfo;
      _lastCheckedAt = DateTime.now();
    });

    switch (updateInfo.availability) {
      case AppUpdateAvailability.optionalUpdateAvailable:
        await _showUpdateDialog(updateInfo: updateInfo, isRequired: false);
        return;
      case AppUpdateAvailability.requiredUpdate:
        await _showUpdateDialog(updateInfo: updateInfo, isRequired: true);
        return;
      case AppUpdateAvailability.upToDate:
      case AppUpdateAvailability.unavailable:
      case AppUpdateAvailability.unsupportedPlatform:
      case AppUpdateAvailability.failed:
        _showSnackBar(updateInfo.message);
        return;
    }
  }

  Future<void> _showUpdateDialog({
    required AppUpdateInfo updateInfo,
    required bool isRequired,
  }) async {
    final details = <String>[updateInfo.message];
    final notes = updateInfo.releaseNotes?.trim() ?? '';
    if (notes.isNotEmpty) {
      details.add(notes);
    }

    final l10n = AppLocalizations.of(context);
    final update = await showAppConfirm(
      context: context,
      title: updateInfo.title,
      message: details.join('\n\n'),
      confirmLabel: isRequired
          ? (l10n?.updateNow ?? 'Update Now')
          : (l10n?.update ?? 'Update'),
      cancelLabel: isRequired
          ? (l10n?.close ?? 'Close')
          : (l10n?.later ?? 'Later'),
    );
    if (update && mounted) await _launchUpdate(updateInfo);
  }

  Future<void> _launchUpdate(AppUpdateInfo updateInfo) async {
    final launched = await _appUpdatePort.launchUpdate(updateInfo);
    if (!mounted || launched) return;

    _showSnackBar(
      AppLocalizations.of(context)?.unableToOpenUpdatePage ??
          'Unable to open the update page.',
    );
  }

  String _availabilityLabel(AppUpdateAvailability availability) {
    final l10n = AppLocalizations.of(context);
    switch (availability) {
      case AppUpdateAvailability.upToDate:
        return l10n?.upToDate ?? 'Up to date';
      case AppUpdateAvailability.optionalUpdateAvailable:
        return l10n?.updateAvailable ?? 'Update available';
      case AppUpdateAvailability.requiredUpdate:
        return l10n?.updateRequired ?? 'Update required';
      case AppUpdateAvailability.unsupportedPlatform:
        return l10n?.unsupportedPlatform ?? 'Unsupported platform';
      case AppUpdateAvailability.unavailable:
        return l10n?.updateCheckDisabled ?? 'Update check disabled';
      case AppUpdateAvailability.failed:
        return l10n?.checkFailed ?? 'Check failed';
    }
  }

  String _formatDateTime(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatCompactDate(value);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: true,
    );
    return '$date $time';
  }

  void _showSnackBar(String message) => context.showToast(message);
}
