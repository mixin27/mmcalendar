import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';
import 'package:views/views.dart';

class _Analytics implements AnalyticsPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _Display implements DisplayPreferencesPort {
  @override
  Future<bool> getShowShanCalendar() async => false;
  @override
  Stream<bool> watchShowShanCalendar() => Stream.value(false);
}

class _Preview implements MonthPreviewPort {
  @override
  Widget buildMonthPreview({
    required DateTime date,
    void Function(DateTime date)? onDateTap,
  }) => const SizedBox();
}

Future<ViewsBloc> _pump(
  WidgetTester tester,
  AppStyle style,
  Widget page,
  ViewsEvent first,
) async {
  final getIt = GetIt.instance;
  await getIt.reset();
  getIt
    ..registerSingleton<AnalyticsPort>(_Analytics())
    ..registerSingleton<DisplayPreferencesPort>(_Display())
    ..registerSingleton<MonthPreviewPort>(_Preview());
  final repository = ViewsRepositoryImpl(ViewsLocalDataSourceImpl());
  final bloc = ViewsBloc(
    getYearView: GetYearView(repository),
    getWeekView: GetWeekView(repository),
    getDayView: GetDayView(repository),
  )..add(first);
  addTearDown(bloc.close);
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 1600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(
        style: style,
        colorScheme: AppColorSchemes.modernLight,
      ),
      home: BlocProvider.value(value: bloc, child: page),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

void main() {
  for (final style in [AppStyle.clear, AppStyle.material]) {
    group('${style.name} style', () {
      testWidgets('Views lists year, week and day', (tester) async {
        await _pump(
          tester,
          style,
          const ViewsSelectorPage(),
          const LoadYearView(2026),
        );
        expect(find.text('Year View'), findsOneWidget);
        expect(find.text('Week View'), findsOneWidget);
        expect(find.text('Day View'), findsOneWidget);
      });

      testWidgets('Year view: 12 months that start on the right weekday', (
        tester,
      ) async {
        await _pump(
          tester,
          style,
          const YearViewPage(),
          const LoadYearView(2026),
        );
        expect(find.text('2026'), findsWidgets);
        expect(find.text('October'), findsOneWidget);

        // October 2026 starts on a Thursday: the 4th (a Sunday) sits in the
        // first column, left of the 1st.
        final october = find.ancestor(
          of: find.text('October'),
          matching: find.byType(InkWell),
        );
        Offset dayCenter(String day) => tester.getCenter(
          find.descendant(of: october, matching: find.text(day)),
        );
        expect(dayCenter('4').dx, lessThan(dayCenter('1').dx));
        expect(dayCenter('4').dy, greaterThan(dayCenter('1').dy));
      });

      testWidgets('Week view: seven days with moons', (tester) async {
        await _pump(
          tester,
          style,
          const WeekViewPage(),
          LoadWeekView(DateTime(2026, 10, 16)),
        );
        expect(find.byType(MoonGlyph), findsNWidgets(7));
        expect(find.byType(AppRow), findsNWidgets(7));
      });
    });
  }

  tearDown(() => GetIt.instance.reset());
}
