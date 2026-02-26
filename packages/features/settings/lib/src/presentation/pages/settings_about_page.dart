import 'package:shared_core/shared_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:promo/promo.dart';

import '../../di/settings_injection.dart';
import '../widgets/settings_widgets.dart';

class SettingsAboutPage extends StatefulWidget {
  const SettingsAboutPage({super.key, this.appVersion});

  final String? appVersion;

  @override
  State<SettingsAboutPage> createState() => _SettingsAboutPageState();
}

class _SettingsAboutPageState extends State<SettingsAboutPage> {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  final AppUpdatePort _appUpdatePort = getIt<AppUpdatePort>();

  @override
  void initState() {
    _analyticsService.logScreenView(
      screenName: 'settings_about',
      screenClass: 'SettingsAboutPage',
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
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.about ?? 'About',
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
              title: const Text('App Version'),
              subtitle: Text(widget.appVersion ?? AppConstants.appVersion),
              trailing: !(kIsWeb || kIsWasm)
                  ? IconButton(
                      onPressed: _checkForUpdates,
                      icon: const Icon(Icons.update),
                      tooltip: 'Check for Updates',
                    )
                  : null,
            ),
            SettingsTile(
              title: 'Open Source Licenses',
              subtitle: 'View all licenses',
              leading: const Icon(Icons.description),
              onTap: () => showLicensePage(context: context),
            ),
            SettingsTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: 'Privacy policy',
              subtitle: "View privacy & policy",
              onTap: () => GoRouter.of(context).go(
                "${RoutePaths.settings}/${RoutePaths.about}/${RoutePaths.privacyPolicy}",
              ),
            ),

            // Debug: Clear promo data
            if (kDebugMode)
              SettingsTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: 'Clear Promo Data (Debug)',
                subtitle: 'Reset onboarding & announcements',
                onTap: () async {
                  try {
                    final promoRepo = getIt<PromoRepository>();
                    await promoRepo.clearAllData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '✅ Promo data cleared! Restart app to see onboarding.',
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await _appUpdatePort.checkForUpdate(forceRefresh: true);
    if (!mounted) return;

    switch (updateInfo.availability) {
      case AppUpdateAvailability.optionalUpdateAvailable:
        await _showUpdateDialog(updateInfo: updateInfo, isRequired: false);
        return;
      case AppUpdateAvailability.requiredUpdate:
        await _showUpdateDialog(updateInfo: updateInfo, isRequired: true);
        return;
      case AppUpdateAvailability.upToDate:
        _showSnackBar('Your app is up to date!');
        return;
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
        return PopScope(
          canPop: true,
          child: AlertDialog(
            title: Text(updateInfo.title),
            content: Text(details.join('\n\n')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(isRequired ? 'Close' : 'Later'),
              ),
              FilledButton(
                onPressed: () async {
                  final launched = await _appUpdatePort.launchUpdate(
                    updateInfo,
                  );
                  if (!mounted) return;

                  if (launched) {
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    return;
                  }

                  _showSnackBar('Unable to open the update page.');
                },
                child: Text(isRequired ? 'Update Now' : 'Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
