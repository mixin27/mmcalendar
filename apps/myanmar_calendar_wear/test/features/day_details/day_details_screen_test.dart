import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_wear/features/day_details/bloc/day_details_bloc.dart';
import 'package:myanmar_calendar_wear/features/day_details/views/day_details_screen.dart';
import 'package:shared_localizations/shared_localizations.dart';

void main() {
  late DayDetailsBloc bloc;

  // Made inside each test, so its stream runs in the test's fake time.
  Future<void> pump(WidgetTester tester) async {
    bloc = DayDetailsBloc(
      language: Language.english,
      now: () => DateTime(2025, 10, 6, 9),
    )..add(const LoadToday());
    addTearDown(bloc.close);
    tester.view.physicalSize = const Size(454, 454);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DayDetailsScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  DateTime shown() => (bloc.state as DayDetailsLoaded).dayDetails.date;

  testWidgets('swipe left for the next day, right for the one before', (
    tester,
  ) async {
    await pump(tester);
    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(-200, 0),
      1000,
    );
    await tester.pump();
    expect(shown(), DateTime(2025, 10, 7));

    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(200, 0),
      1000,
    );
    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(200, 0),
      1000,
    );
    await tester.pump();
    expect(shown(), DateTime(2025, 10, 5));
  });

  testWidgets('the arrows move a day and Today comes back', (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('watch-today')), findsNothing);
    expect(find.text('Today'), findsOneWidget, reason: 'the today pill');

    await tester.tap(find.byKey(const ValueKey('watch-next-day')));
    await tester.pumpAndSettle();
    expect(shown(), DateTime(2025, 10, 7));
    expect(find.byKey(const ValueKey('watch-today')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('watch-today')));
    await tester.pumpAndSettle();
    expect(shown(), DateTime(2025, 10, 6));
    expect(find.byKey(const ValueKey('watch-today')), findsNothing);
  });

  testWidgets('shows the holiday, Sabbath, moon and astrology', (tester) async {
    await pump(tester);
    expect(find.textContaining('Thadingyut'), findsWidgets);
    expect(find.text('Sabbath'), findsOneWidget);
    expect(find.text('Full Moon'), findsOneWidget);
    expect(find.text('Nagahle'), findsOneWidget);
  });
}
