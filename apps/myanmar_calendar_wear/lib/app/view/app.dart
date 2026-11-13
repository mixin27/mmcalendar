import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_wear/ambient_mode/ambient_mode.dart';
import 'package:myanmar_calendar_wear/features/day_details/bloc/day_details_bloc.dart';
import 'package:myanmar_calendar_wear/features/day_details/views/day_details_screen.dart';
import 'package:myanmar_calendar_wear/features/settings/views/language_settings_screen.dart';
import 'package:myanmar_calendar_wear/settings/watch_settings.dart';
import 'package:myanmar_calendar_wear/watch_payload/watch_payload_writer.dart';
import 'package:shared_localizations/shared_localizations.dart';

class App extends StatefulWidget {
  const App(this.settings, {super.key, this.now});

  final WatchSettings settings;

  /// The clock, for tests.
  final DateTime Function()? now;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late Language _language = widget.settings.language;
  late final DayDetailsBloc _dayDetailsBloc = DayDetailsBloc(
    language: _language,
    now: widget.now,
  )..add(const LoadToday());

  @override
  void dispose() {
    _dayDetailsBloc.close();
    super.dispose();
  }

  Future<void> _changeLanguage(Language language) async {
    setState(() => _language = language);
    _dayDetailsBloc.add(ChangeLanguage(language));
    await widget.settings.setLanguage(language);
    // The Tile and complications follow the app's language.
    await WatchPayloadWriter(widget.settings.preferences).write(language);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dayDetailsBloc,
      child: AmbientModeBuilder(
        child: const DayDetailsScreen(),
        builder: (context, isAmbientModeActive, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.myanmarCalendar,
            locale: WatchSettings.localeFor(_language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              useMaterial3: true,
              visualDensity: VisualDensity.compact,
              colorScheme: isAmbientModeActive
                  ? const ColorScheme.dark(
                      primary: Colors.white24,
                      onSurface: Colors.white10,
                    )
                  : const ColorScheme.dark(primary: Color(0xFF00B5FF)),
            ),
            debugShowCheckedModeBanner: false,
            home: child,
            routes: {
              DayDetailsScreen.settingsRoute: (context) =>
                  LanguageSettingsScreen(
                    currentLanguage: _language,
                    onLanguageChanged: (language) =>
                        unawaited(_changeLanguage(language)),
                  ),
            },
          );
        },
      ),
    );
  }
}
