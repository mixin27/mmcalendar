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
    final l10n = AppLocalizations.of(context);
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
              title: Text(l10n?.appVersion ?? 'App Version'),
              subtitle: Text(widget.appVersion ?? AppConstants.appVersion),
            ),
            if (!(kIsWeb || kIsWasm))
              SettingsTile(
                leading: const Icon(Icons.system_update_alt),
                title: l10n?.appUpdates ?? 'App Updates',
                subtitle:
                    l10n?.checkForNewVersionsAndUpdateSettings ??
                    'Check for new versions and update settings',
                onTap: () => GoRouter.of(
                  context,
                ).go("${RoutePaths.settings}/${RoutePaths.appUpdate}"),
              ),
            SettingsTile(
              title: l10n?.openSourceLicenses ?? 'Open Source Licenses',
              subtitle: l10n?.viewAllLicenses ?? 'View all licenses',
              leading: const Icon(Icons.description),
              onTap: () => showLicensePage(context: context),
            ),
            SettingsTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: l10n?.privacyPolicy ?? 'Privacy policy',
              subtitle: l10n?.viewPrivacyPolicy ?? 'View privacy & policy',
              onTap: () => GoRouter.of(context).go(
                "${RoutePaths.settings}/${RoutePaths.about}/${RoutePaths.privacyPolicy}",
              ),
            ),

            // Debug: Clear promo data
            if (kDebugMode)
              SettingsTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: l10n?.clearPromoDataDebug ?? 'Clear Promo Data (Debug)',
                subtitle:
                    l10n?.resetOnboardingAnnouncements ??
                    'Reset onboarding & announcements',
                onTap: () async {
                  try {
                    final promoRepo = getIt<PromoRepository>();
                    await promoRepo.clearAllData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n?.promoDataClearedRestartApp ??
                                'Promo data cleared! Restart app to see onboarding.',
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n?.errorWithMessage(e.toString()) ?? 'Error: $e',
                          ),
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
}
