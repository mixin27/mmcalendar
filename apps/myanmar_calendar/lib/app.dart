import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:calendar/calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:settings/settings.dart';
import 'package:views/views.dart';

import 'config/di_setup.dart';
import 'config/router.dart';
import 'presentation/bloc/app_bloc.dart';

class MyanmarCalendarApp extends StatelessWidget {
  const MyanmarCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppBloc()..add(InitializeApp()),
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          if (state is AppInitializing) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return MultiBlocProvider(
            providers: [
              // Calendar BLoC
              BlocProvider(
                create: (context) =>
                    getIt<CalendarBloc>()
                      ..add(LoadCalendarMonth(DateTime.now())),
              ),
              // Settings BLoC
              BlocProvider(
                create: (context) =>
                    getIt<SettingsBloc>()..add(const LoadSettings()),
              ),
              // Views BLoC
              BlocProvider(create: (context) => getIt<ViewsBloc>()),
              // Add more BLoC providers here when features are ready
            ],
            child: BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, settingsState) {
                // Get theme from settings or use default
                final themeColors = settingsState is SettingsLoaded
                    ? settingsState.settings.customColors
                    : null;
                final themeMode = settingsState is SettingsLoaded
                    ? settingsState.settings.themeMode
                    : ThemeMode.system;

                return MaterialApp.router(
                  title: AppConstants.appName,
                  debugShowCheckedModeBanner: false,

                  // Theme
                  theme: AppTheme.lightTheme(customColors: themeColors),
                  darkTheme: AppTheme.darkTheme(customColors: themeColors),
                  themeMode: themeMode,

                  // Localization
                  localizationsDelegates: [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: [
                    Locale('en'), // English
                    Locale('my'), // Myanmar
                  ],

                  // Routing
                  routerConfig: router,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
