import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_wear/ambient_mode/ambient_mode.dart';
import 'package:myanmar_calendar_wear/app/view/app.dart';
import 'package:myanmar_calendar_wear/features/day_details/views/day_details_screen.dart';
import 'package:myanmar_calendar_wear/settings/watch_settings.dart';
import 'package:myanmar_calendar_wear/watch_payload/watch_payload_writer.dart';

import '../../helpers/helpers.dart';

void main() {
  // A Full Moon Sabbath: Thadingyut full moon, 6 October 2025.
  DateTime now() => DateTime(2025, 10, 6, 9);

  group('App', () {
    setUpAll(() {
      AmbientModeListener.instance.value = false;
    });

    testWidgets('renders the day', (tester) async {
      await tester.pumpWidget(App(await testSettings(), now: now));
      await tester.pump();
      expect(find.byType(DayDetailsScreen), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Sabbath'), findsOneWidget);
    });

    testWidgets('speaks Myanmar for a Myanmar calendar', (tester) async {
      final settings = await testSettings(language: Language.myanmar);
      await tester.pumpWidget(App(settings, now: now));
      await tester.pump();
      expect(find.text('ယနေ့'), findsOneWidget);
      expect(find.text('ဥပုသ်'), findsOneWidget);
      expect(find.textContaining('သီတင်းကျွတ်'), findsWidgets);
    });

    testWidgets('changing the language saves it and rewrites the payload', (
      tester,
    ) async {
      final settings = await testSettings();
      await tester.pumpWidget(App(settings, now: now));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('watch-language')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('မြန်မာ'));
      await tester.pumpAndSettle();

      expect(find.text('ယနေ့'), findsOneWidget);
      expect(settings.preferences.getString('language'), 'my');
      expect(WatchSettings.languageOf(settings.preferences), Language.myanmar);
      final payload = WatchPayloadWriter(settings.preferences).read();
      expect(payload?['lang'], 'my');
    });

    group('renders the correct color scheme', () {
      testWidgets('on ambient mode updates', (tester) async {
        await tester.pumpWidget(App(await testSettings(), now: now));

        MaterialApp getMaterialApp() {
          return find.byType(MaterialApp).evaluate().first.widget
              as MaterialApp;
        }

        expect(
          getMaterialApp().theme?.colorScheme,
          const ColorScheme.dark(primary: Color(0xFF00B5FF)),
        );

        await simulatePlatformCall('ambient_mode', 'onUpdateAmbient');
        await tester.pumpAndSettle();

        expect(
          getMaterialApp().theme?.colorScheme,
          const ColorScheme.dark(
            primary: Colors.white24,
            onSurface: Colors.white10,
          ),
        );

        await simulatePlatformCall('ambient_mode', 'onExitAmbient');
        await tester.pumpAndSettle();

        expect(
          getMaterialApp().theme?.colorScheme,
          const ColorScheme.dark(primary: Color(0xFF00B5FF)),
        );
      });
    });
  });
}
