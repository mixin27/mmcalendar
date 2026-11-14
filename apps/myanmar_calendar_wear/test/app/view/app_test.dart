import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_wear/ambient_mode/ambient_mode.dart';
import 'package:myanmar_calendar_wear/app/view/app.dart';
import 'package:myanmar_calendar_wear/features/home/watch_home.dart';
import 'package:myanmar_calendar_wear/settings/watch_settings.dart';
import 'package:myanmar_calendar_wear/watch_payload/watch_payload_writer.dart';

import '../../helpers/helpers.dart';

void main() {
  // A Full Moon Sabbath: Thadingyut full moon, 6 October 2025.
  DateTime now() => DateTime(2025, 10, 6, 9);

  Future<WatchSettings> pump(
    WidgetTester tester, {
    Language language = Language.english,
  }) async {
    // The large round emulator: 454 px at density 2.
    tester.view.physicalSize = const Size(454, 454);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final settings = await testSettings(language: language);
    await tester.pumpWidget(App(settings, now: now));
    await tester.pumpAndSettle();
    return settings;
  }

  /// Swipes up to the Coming up page, after the day pages.
  Future<void> toComingUp(WidgetTester tester) async {
    for (var i = 0; i < WatchHome.dayPages; i++) {
      await tester.fling(
        find.byKey(const ValueKey('watch-pages')),
        const Offset(0, -150),
        1500,
      );
      await tester.pumpAndSettle();
    }
  }

  setUp(() => AmbientModeListener.instance.value = false);

  testWidgets('today first: the full moon, Sabbath and the holiday', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Full Moon'), findsOneWidget);
    expect(find.textContaining('Thadingyut'), findsWidgets);
    expect(find.text('Sabbath'), findsOneWidget);
    expect(find.text('Monday, 6 October 2025'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe up for tomorrow', (tester) async {
    await pump(tester);
    await tester.fling(
      find.byKey(const ValueKey('watch-pages')),
      const Offset(0, -150),
      1500,
    );
    await tester.pumpAndSettle();
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Tuesday, 7 October 2025'), findsOneWidget);
  });

  testWidgets('tap a day for its astrology', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('watch-day-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('watch-day-detail')), findsOneWidget);
    expect(find.text('Astrology'), findsOneWidget);
    expect(find.text('Nagahle'), findsOneWidget);
  });

  testWidgets('Coming up lists the next days, with countdowns', (tester) async {
    await pump(tester);
    await toComingUp(tester);
    expect(find.text('Coming up'), findsOneWidget);
    expect(find.textContaining('in '), findsWidgets);
  });

  testWidgets('speaks Myanmar for a Myanmar calendar', (tester) async {
    await pump(tester, language: Language.myanmar);
    expect(find.text('ယနေ့'), findsOneWidget);
    expect(find.text('ဥပုသ်'), findsOneWidget);
    expect(find.textContaining('သီတင်းကျွတ်'), findsWidgets);
  });

  testWidgets('changing the language saves it and rewrites the payload', (
    tester,
  ) async {
    final settings = await pump(tester);
    await toComingUp(tester);
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('watch-language')),
      find.byKey(const ValueKey('watch-coming-up')),
      const Offset(0, -100),
    );
    await tester.tap(find.byKey(const ValueKey('watch-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('မြန်မာ'));
    await tester.pumpAndSettle();

    expect(settings.preferences.getString('language'), 'my');
    expect(WatchSettings.languageOf(settings.preferences), Language.myanmar);
    expect(WatchPayloadWriter(settings.preferences).read()?['lang'], 'my');
  });

  testWidgets('ambient mode shows only today, dimmed', (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('watch-ambient')), findsNothing);

    await simulatePlatformCall('ambient_mode', 'onEnterAmbient');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('watch-ambient')), findsOneWidget);

    await simulatePlatformCall('ambient_mode', 'onExitAmbient');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('watch-ambient')), findsNothing);
  });
}
