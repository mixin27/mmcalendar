import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_localizations/shared_localizations.dart';

import '../../di/settings_injection.dart';
import '../widgets/settings_widgets.dart';

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
    final updateInfo = _lastUpdateInfo;

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
                Icons.system_update_alt,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.appUpdates ?? 'App Updates',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.tag),
              title: Text(l10n?.currentVersion ?? 'Current Version'),
              subtitle: Text(widget.appVersion ?? AppConstants.appVersion),
            ),
            SettingsTile(
              title: l10n?.checkForUpdates ?? 'Check for Updates',
              subtitle:
                  l10n?.useCurrentRemoteConfigValues ??
                  'Use current remote config values',
              leading: const Icon(Icons.update),
              onTap: () => _checkForUpdates(forceRefresh: false),
            ),
            SettingsTile(
              title:
                  l10n?.forceRefreshUpdateConfig ??
                  'Force Refresh Update Config',
              subtitle:
                  l10n?.fetchRemoteConfigNowAndCheckAgain ??
                  'Fetch remote config now and check again',
              leading: const Icon(Icons.cloud_download_outlined),
              onTap: () => _checkForUpdates(forceRefresh: true),
            ),
            if (_isChecking)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LinearProgressIndicator(),
              ),
            if (updateInfo != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _availabilityLabel(updateInfo.availability),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (_lastCheckedAt != null)
                          Text(
                            l10n?.lastCheckedAt(
                                  _formatDateTime(context, _lastCheckedAt!),
                                ) ??
                                'Last checked: ${_formatDateTime(context, _lastCheckedAt!)}',
                          ),
                        const SizedBox(height: 4),
                        Text(
                          l10n?.currentVersionWithBuild(
                                updateInfo.currentVersion,
                                updateInfo.currentBuildNumber.toString(),
                              ) ??
                              'Current: ${updateInfo.currentVersion} (${updateInfo.currentBuildNumber})',
                        ),
                        Text(
                          l10n?.latestVersionWithBuild(
                                updateInfo.latestVersion,
                                updateInfo.latestBuildNumber.toString(),
                              ) ??
                              'Latest: ${updateInfo.latestVersion} (${updateInfo.latestBuildNumber})',
                        ),
                        const SizedBox(height: 8),
                        Text(updateInfo.message),
                        if ((updateInfo.releaseNotes ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            l10n?.releaseNotes ?? 'Release Notes',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(updateInfo.releaseNotes!),
                        ],
                        if (updateInfo.hasUpdate) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _isChecking
                                  ? null
                                  : () => _launchUpdate(updateInfo),
                              icon: const Icon(Icons.open_in_new),
                              label: Text(l10n?.openStore ?? 'Open Store'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(updateInfo.title),
          content: Text(details.join('\n\n')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                isRequired
                    ? (AppLocalizations.of(context)?.close ?? 'Close')
                    : (AppLocalizations.of(context)?.later ?? 'Later'),
              ),
            ),
            FilledButton(
              onPressed: () => _launchUpdate(updateInfo, dialogContext),
              child: Text(
                isRequired
                    ? (AppLocalizations.of(context)?.updateNow ?? 'Update Now')
                    : (AppLocalizations.of(context)?.update ?? 'Update'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUpdate(
    AppUpdateInfo updateInfo, [
    BuildContext? dialogContext,
  ]) async {
    final launched = await _appUpdatePort.launchUpdate(updateInfo);
    if (!mounted) return;

    if (launched) {
      if (dialogContext != null && dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      return;
    }

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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
