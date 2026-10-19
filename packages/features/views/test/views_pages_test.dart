import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart' as mm;
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

class _Events implements EventMarkersPort {
  _Events(this.events);
  final Map<DateTime, List<CalendarEventItem>> events;
  @override
  Stream<Map<DateTime, List<CalendarEventItem>>> watchEventMarkers({
    required DateTime startDate,
    required DateTime endDate,
  }) => Stream.value(events);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  ViewsEvent first, {
  void Function(GetIt getIt)? register,
}) async {
  final getIt = GetIt.instance;
  await getIt.reset();
  getIt
    ..registerSingleton<AnalyticsPort>(_Analytics())
    ..registerSingleton<DisplayPreferencesPort>(_Display())
    ..registerSingleton<MonthPreviewPort>(_Preview());
  register?.call(getIt);
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
        expect(find.text('Myanmar Month'), findsOneWidget);
        expect(find.text('Agenda'), findsOneWidget);
      });

      testWidgets('Agenda: days with holidays, moons and events', (
        tester,
      ) async {
        final today = DateUtils.dateOnly(DateTime.now());
        final events = _Events({
          today.add(const Duration(days: 2)): [
            CalendarEventItem(
              id: 7,
              title: 'Pagoda visit',
              eventDate: today.add(const Duration(days: 2)),
              isAllDay: true,
              category: const CalendarEventCategory(
                name: 'Family',
                iconName: 'family',
                colorCode: 0xFF2F5BEA,
              ),
              isRecurring: false,
            ),
          ],
        });
        await _pump(
          tester,
          style,
          const AgendaViewPage(),
          const LoadYearView(2026),
          register: (getIt) =>
              getIt.registerSingleton<EventMarkersPort>(events),
        );
        expect(find.text('Pagoda visit'), findsOneWidget);
        // Every 90 days have at least two full moons.
        expect(find.byType(mm.MoonGlyph), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Myanmar month: fortnights and quarter moons', (
        tester,
      ) async {
        await _pump(
          tester,
          style,
          const MyanmarMonthViewPage(),
          const LoadYearView(2026),
        );
        expect(find.byType(mm.MyanmarLunarMonthCalendar), findsOneWidget);
        expect(find.byType(mm.MoonPhaseStrip), findsOneWidget);
        // Full moon and new moon in the month, plus four quarter moons.
        expect(find.byType(mm.MoonGlyph), findsNWidgets(6));

        // Stepping to the next Myanmar month moves the strip with it.
        final title = tester
            .widget<mm.MyanmarLunarMonthCalendar>(
              find.byType(mm.MyanmarLunarMonthCalendar),
            )
            .month;
        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();
        final strip = tester.widget<mm.MoonPhaseStrip>(
          find.byType(mm.MoonPhaseStrip),
        );
        expect(strip.month, isNot(title));
        expect(tester.takeException(), isNull);
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
