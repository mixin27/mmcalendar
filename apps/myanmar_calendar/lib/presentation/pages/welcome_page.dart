import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:onboarding/onboarding.dart';
import 'package:settings/settings.dart';
import 'package:shared_core/shared_core.dart';
import 'package:events/events.dart';
import 'package:whats_new/whats_new.dart';

import '../../config/di_setup.dart';

/// First run: the onboarding tour and setup, wired to settings. Replaces
/// the old consent page.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<SettingsBloc>().state;
    final settings = state is SettingsLoaded ? state.settings : null;
    final bloc = context.read<SettingsBloc>();
    final phoneLanguage =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return OnboardingPage(
      settings: OnboardingSettings(
        appLanguage:
            settings?.appLanguage ?? (phoneLanguage == 'my' ? 'my' : 'en'),
        calendarLanguage: settings?.calendarLanguage ?? Language.myanmar,
        themeMode: settings?.themeMode ?? ThemeMode.system,
        themePreset: settings?.themePreset ?? 'modern',
      ),
      actions: OnboardingActions(
        setAppLanguage: (code) => bloc.add(ChangeAppLanguage(code)),
        setCalendarLanguage: (language) =>
            bloc.add(ChangeCalendarLanguage(language)),
        setThemeMode: (mode) => bloc.add(ChangeThemeMode(mode)),
        setThemePreset: (id) => bloc.add(ChangeThemePreset(id)),
        requestNotifications: () =>
            getIt<NotificationService>().requestPermissions(),
        finish: ({required analytics, required crashReports}) async {
          bloc
            ..add(UpdateAnalyticsConsent(analytics))
            ..add(UpdateCrashlyticsConsent(crashReports))
            ..add(const MarkConsentDialogShown());
          await getIt<OnboardingStore>().complete();
          // New users were just introduced to the app.
          await getIt<WhatsNewStore>().markSeen();
          if (context.mounted) GoRouter.of(context).go(RoutePaths.home);
        },
      ),
    );
  }
}
