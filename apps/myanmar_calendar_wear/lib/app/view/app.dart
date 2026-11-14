import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_wear/ambient_mode/ambient_mode.dart';
import 'package:myanmar_calendar_wear/app/watch_colors.dart';
import 'package:myanmar_calendar_wear/features/home/watch_home.dart';
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

  /// The slim payload: Coming up reads it, as the Tile does.
  Map<String, Object?>? _payload;

  @override
  void initState() {
    super.initState();
    // After the first frame: building the days takes a moment on a watch.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_write()));
  }

  /// Writes the Tile and complication payload, and keeps it for Coming up.
  Future<void> _write() async {
    final language = _language;
    final payload = await WatchPayloadWriter(
      widget.settings.preferences,
    ).write(language, now: widget.now?.call());
    if (mounted && language == _language) setState(() => _payload = payload);
  }

  Future<void> _changeLanguage(Language language) async {
    setState(() {
      _language = language;
      _payload = null;
    });
    await widget.settings.setLanguage(language);
    // The Tile and complications follow the app's language.
    await _write();
  }

  void _openLanguage() => _navigatorKey.currentState?.push(
    MaterialPageRoute<void>(
      builder: (_) => LanguageSettingsScreen(
        currentLanguage: _language,
        onLanguageChanged: (language) => unawaited(_changeLanguage(language)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AmbientModeBuilder(
      builder: (context, isAmbientModeActive, _) => MaterialApp(
        navigatorKey: _navigatorKey,
        onGenerateTitle: (context) =>
            AppLocalizations.of(context)!.myanmarCalendar,
        locale: WatchSettings.localeFor(_language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          visualDensity: VisualDensity.compact,
          scaffoldBackgroundColor: WatchColors.background,
          colorScheme: const ColorScheme.dark(
            primary: WatchColors.accent,
            surface: WatchColors.background,
          ),
        ),
        debugShowCheckedModeBanner: false,
        // Ambient mode covers whatever is open with today's date.
        builder: (context, child) => Stack(
          children: [
            ?child,
            if (isAmbientModeActive)
              Positioned.fill(
                child: AmbientDay(language: _language, now: widget.now),
              ),
          ],
        ),
        home: WatchHome(
          language: _language,
          payload: _payload,
          onLanguage: _openLanguage,
          now: widget.now,
        ),
      ),
    );
  }
}
