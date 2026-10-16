import 'package:shared_core/shared_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:promo/promo.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

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

  Future<void> _clearPromoData(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      await getIt<PromoRepository>().clearAllData();
      if (context.mounted) {
        context.showToast(
          l10n?.promoDataClearedRestartApp ??
              'Promo data cleared! Restart app to see onboarding.',
          kind: AppToastKind.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        context.showToast(
          l10n?.errorWithMessage(e.toString()) ?? 'Error: $e',
          kind: AppToastKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final version = widget.appVersion ?? AppConstants.appVersion;
    return AppPage(
      title: l10n?.about ?? 'About',
      previousTitle: 'Settings',
      children: [
        Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/logo.png',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 72,
                  height: 72,
                  color: t.accent,
                  child: Icon(Icons.calendar_month, color: t.onAccent),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n?.myanmarCalendar ?? 'Myanmar Calendar',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${l10n?.appVersion ?? 'App Version'} $version',
              style: TextStyle(fontSize: 13, color: t.secondaryLabel),
            ),
          ],
        ),
        AppGroup(
          children: [
            if (!(kIsWeb || kIsWasm))
              AppRow(
                icon: Icons.system_update_alt_outlined,
                iconColor: SettingsIconColors.blue,
                title: l10n?.appUpdates ?? 'App Updates',
                chevron: true,
                onTap: () => GoRouter.of(
                  context,
                ).go('${RoutePaths.settings}/${RoutePaths.appUpdate}'),
              ),
            AppRow(
              icon: Icons.description_outlined,
              iconColor: SettingsIconColors.gray,
              title: l10n?.openSourceLicenses ?? 'Open Source Licenses',
              chevron: true,
              onTap: () => showLicensePage(context: context),
            ),
            AppRow(
              icon: Icons.privacy_tip_outlined,
              iconColor: SettingsIconColors.gray,
              title: l10n?.privacyPolicy ?? 'Privacy policy',
              chevron: true,
              onTap: () => GoRouter.of(context).go(
                '${RoutePaths.settings}/${RoutePaths.about}/${RoutePaths.privacyPolicy}',
              ),
            ),
          ],
        ),
        if (kDebugMode)
          AppGroup(
            footer: 'Debug builds only.',
            children: [
              AppRow(
                title: l10n?.clearPromoDataDebug ?? 'Clear Promo Data (Debug)',
                subtitle:
                    l10n?.resetOnboardingAnnouncements ??
                    'Reset onboarding & announcements',
                tone: AppRowTone.destructive,
                onTap: () => _clearPromoData(context),
              ),
            ],
          ),
      ],
    );
  }
}
