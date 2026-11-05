import 'package:converter/converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

Future<void> _pump(WidgetTester tester, DateTime birth) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 2000);
  addTearDown(tester.view.reset);
  MyanmarCalendar.setLanguage(Language.english);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.build(
        style: AppStyle.clear,
        colorScheme: AppColorSchemes.modernLight,
      ),
      builder: (context, child) =>
          CalendarLanguageScope(language: Language.english, child: child!),
      home: Scaffold(
        body: SingleChildScrollView(
          child: BirthDateTool(
            today: DateTime(2026, 11, 5),
            initialBirth: birth,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a birth date shows its sign, age and birthdays', (tester) async {
    await _pump(tester, DateTime(1990, 3, 11));
    expect(find.text('Born on Sunday'), findsOneWidget);
    expect(find.text('Garuda · Sun'), findsOneWidget);
    expect(find.byKey(const ValueKey('birth-noon')), findsNothing);
    // 36 years, 7 months, 25 days.
    expect(find.text('36'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('birth-next-myanmar')),
        matching: find.textContaining('1388 Tabaung Waning'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Wednesday asks before or after noon', (tester) async {
    await _pump(tester, DateTime(2026, 11, 4));
    expect(find.text('Tusked elephant · Mercury'), findsOneWidget);
    await tester.tap(find.text('After noon'));
    await tester.pumpAndSettle();
    expect(find.text('Tuskless elephant · Rahu'), findsOneWidget);
  });
}
