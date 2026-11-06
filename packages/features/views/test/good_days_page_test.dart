import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';
import 'package:views/views.dart';

Future<void> _pump(WidgetTester tester, AppStyle style) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 3000);
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => GoodDaysPage(today: DateTime(2026, 11, 5)),
      ),
      GoRoute(
        path: '/views/day',
        builder: (_, state) => Text('day ${state.extra}'),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.build(
        style: style,
        colorScheme: AppColorSchemes.modernLight,
      ),
      builder: (context, child) =>
          CalendarLanguageScope(language: Language.english, child: child!),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _goodDays() => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('good-day-'),
);

void main() {
  for (final style in [AppStyle.clear, AppStyle.material]) {
    testWidgets('${style.name}: three months of good days, by weekday', (
      tester,
    ) async {
      await _pump(tester, style);
      expect(_goodDays(), findsNWidgets(13));
      expect(find.byKey(const ValueKey('good-day-2026-11-30')), findsOneWidget);
      expect(find.textContaining('ask an astrologer'), findsOneWidget);

      await tester.tap(find.text('1 month'));
      await tester.pumpAndSettle();
      expect(_goodDays(), findsOneWidget);

      await tester.tap(find.text('3 months'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('good-days-weekday-1')));
      await tester.pumpAndSettle();
      expect(_goodDays().evaluate().length, lessThan(13));
      expect(find.byKey(const ValueKey('good-day-2026-11-30')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('good-day-2026-11-30')));
      await tester.pumpAndSettle();
      expect(find.text('day ${DateTime(2026, 11, 30)}'), findsOneWidget);
    });
  }

  testWidgets('good days fit large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, AppStyle.clear);
    // Taller rows: the last ones are below the fold.
    expect(_goodDays(), findsWidgets);
  });

  testWidgets('no good days says so', (tester) async {
    await _pump(tester, AppStyle.clear);
    await tester.tap(find.text('1 month'));
    await tester.pumpAndSettle();
    // 30 Nov is a Monday; keeping only Tuesdays leaves none.
    await tester.tap(find.byKey(const ValueKey('good-days-weekday-2')));
    await tester.pumpAndSettle();
    expect(find.text('No good days in this period.'), findsOneWidget);
  });
}
