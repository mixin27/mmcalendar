import 'dart:developer';

import 'package:converter/converter.dart';
import 'package:calendar/calendar.dart';
import 'package:events/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:localizations/localizations.dart';
import 'package:settings/settings.dart';
import 'package:views/views.dart';

import 'config/di_setup.dart';
import 'config/router.dart';

class MyanmarCalendarApp extends StatelessWidget {
  const MyanmarCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Calendar feature
        BlocProvider(
          create: (context) =>
              getIt<CalendarBloc>()..add(LoadCalendarMonth(DateTime.now())),
        ),

        // Settings feature
        BlocProvider(
          create: (context) => getIt<SettingsBloc>()..add(const LoadSettings()),
        ),

        // Views feature
        BlocProvider(create: (context) => getIt<ViewsBloc>()),

        // Converter feature
        BlocProvider(create: (context) => getIt<ConverterBloc>()),

        // Events feature
        BlocProvider(
          create: (context) =>
              getIt<UserEventsBloc>()..add(const LoadAllEvents()),
        ),
        BlocProvider(
          create: (context) =>
              getIt<EventCategoriesBloc>()..add(const LoadEventCategories()),
        ),
      ],
      child: _AppContent(),
    );
  }
}

class _AppContent extends StatefulWidget {
  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  @override
  void initState() {
    super.initState();
    // Request notification permissions
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    final notificationService = getIt<NotificationService>();
    await notificationService.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, curr) {
        if (prev is SettingsLoaded && curr is SettingsLoaded) {
          return prev.settings.themeMode != curr.settings.themeMode ||
              prev.settings.customColors != curr.settings.customColors ||
              prev.settings.themePreset != curr.settings.themePreset ||
              prev.settings.appLanguage != curr.settings.appLanguage;
        }
        return true;
      },
      builder: (context, settingsState) {
        // Get theme mode from settings
        ThemeMode themeMode = ThemeMode.system;
        if (settingsState is SettingsLoaded) {
          log(settingsState.settings.themeMode.toString());
          themeMode = settingsState.settings.themeMode;
        }

        final themeColors = settingsState is SettingsLoaded
            ? settingsState.settings.customColors
            : null;

        // Sync with Telegram theme if available
        // final telegramBgColor = getIt<TelegramService>()
        //     .getThemeBackgroundColor();
        // final telegramColor = Color(
        //   int.parse(telegramBgColor.replaceFirst('#', '0xff')),
        // );

        final lightTheme = AppTheme.lightTheme(customColors: themeColors);
        final darkTheme = AppTheme.darkTheme(customColors: themeColors);

        final locale = settingsState is SettingsLoaded
            ? Locale(settingsState.settings.appLanguage)
            : Locale('en');

        return MaterialApp.router(
          key: ValueKey(
            'theme-${themeMode.name}-${themeColors?.toStringShort()}',
          ),
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          routerConfig: router,
        );
      },
    );
  }
}
