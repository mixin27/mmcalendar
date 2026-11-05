import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:calendar/src/presentation/widgets/day_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:share_plus/share_plus.dart' show XFile;
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.build(
    style: AppStyle.clear,
    colorScheme: AppColorSchemes.modernLight,
  ),
  builder: (context, child) =>
      CalendarLanguageScope(language: Language.english, child: child!),
  home: home,
);

void main() {
  testWidgets('the card says the day, its holiday and marks', (tester) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Center(child: DayShareCard(date: DateTime(2026, 10, 26))),
        ),
      ),
    );
    // The Thadingyut full moon: the end of Buddhist Lent, a Sabbath.
    expect(find.text('Monday · 26 Oct 2026'), findsOneWidget);
    expect(find.text('1388 Thadingyut'), findsOneWidget);
    expect(find.text('Full Moon 15'), findsOneWidget);
    expect(find.textContaining('Thadingyut'), findsWidgets);
    expect(find.text('Sabbath day'), findsOneWidget);
    expect(find.text('Myanmar Calendar'), findsOneWidget);
  });

  testWidgets('sharing gives a 1080 px PNG in either shape', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);
    final shared = <XFile>[];
    var textShared = false;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDayShareSheet(
                context,
                date: DateTime(2026, 10, 26),
                shareText: () => textShared = true,
                shareFiles: (files) async => shared.addAll(files),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Share this day'), findsOneWidget);

    Future<(int, int)> shareAndMeasure() async {
      await tester.tap(find.byKey(const ValueKey('share-image')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      final bytes = await tester.runAsync(() => shared.last.readAsBytes());
      expect(bytes!.sublist(1, 4), Uint8List.fromList('PNG'.codeUnits));
      final size = await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return (frame.image.width, frame.image.height);
      });
      return size!;
    }

    expect(await shareAndMeasure(), (1080, 1080));

    await tester.tap(find.text('Story'));
    await tester.pumpAndSettle();
    expect(await shareAndMeasure(), (1080, 1920));

    await tester.tap(find.byKey(const ValueKey('share-text')));
    await tester.pumpAndSettle();
    expect(textShared, isTrue);
  });
}
