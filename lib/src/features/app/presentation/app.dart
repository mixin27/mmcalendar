import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mmcalendar/src/l10n/l10n.dart';
import 'package:mmcalendar/src/routes/routes.dart';
import 'package:mmcalendar/src/widgets/settings/theme_mode_switch_tile.dart';

class AppWidget extends HookConsumerWidget {
  AppWidget({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      // title: 'Myanmar Calendar',
      onGenerateTitle: (context) => LocaleKeys.myanmar_calendar.tr(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF18363E)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF18363E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      routerConfig: _appRouter.config(
        navigatorObservers: () => [
          AppRouteObserver(),
          FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        ],
      ),

      // localization stuffs
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
