import 'package:calendar/calendar.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

/// Real dates, no database: the same month building the data source does.
class _Repository implements CalendarRepository {
  @override
  Future<Either<Failure, CalendarMonth>> getCalendarMonth(
    DateTime month,
  ) async {
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    return Right(
      CalendarMonth(
        month: first,
        dates: [
          for (var d = 1; d <= days; d++)
            MyanmarCalendar.getCompleteDate(
              DateTime(month.year, month.month, d),
            ),
        ],
        gridDates: AppDateUtils.getCalendarGridDates(
          first,
          firstDayOfWeek: 1,
        ).map(MyanmarCalendar.getCompleteDate).toList(),
      ),
    );
  }

  @override
  Future<Either<Failure, CompleteDate>> getDateDetails(DateTime date) async =>
      Right(MyanmarCalendar.getCompleteDate(date));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Analytics implements AnalyticsPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _DisplayConfig implements CalendarDisplayConfigPort {
  _DisplayConfig(this.config);
  final CalendarDisplayConfig config;

  @override
  Future<CalendarDisplayConfig> getDisplayConfig() async => config;

  @override
  Stream<CalendarDisplayConfig> watchDisplayConfig() => Stream.value(config);
}

class _Events implements EventMarkersPort {
  @override
  Stream<Map<DateTime, List<CalendarEventItem>>> watchEventMarkers({
    required DateTime startDate,
    required DateTime endDate,
  }) => Stream.value(const {});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CalendarDisplayConfig _config(CalendarGridStyle style) {
  final defaults = CalendarDisplayConfig.defaults();
  return CalendarDisplayConfig(
    calendarLanguage: defaults.calendarLanguage,
    showHolidays: true,
    showAnniversaryDays: true,
    showSabbaths: true,
    showAstrology: true,
    showWesternDates: true,
    showMyanmarDates: true,
    showShanCalendar: defaults.showShanCalendar,
    useDeviceTimezone: defaults.useDeviceTimezone,
    sasanaYearType: defaults.sasanaYearType,
    calendarType: defaults.calendarType,
    gregorianStart: defaults.gregorianStart,
    timezoneOffset: defaults.timezoneOffset,
    defaultLanguage: defaults.defaultLanguage,
    gridStyle: style,
  );
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Size size,
  required DateTime month,
  CalendarGridStyle style = CalendarGridStyle.detailed,
}) async {
  final getIt = GetIt.instance;
  await getIt.reset();
  getIt
    ..registerSingleton<AnalyticsPort>(_Analytics())
    ..registerSingleton<CalendarDisplayConfigPort>(
      _DisplayConfig(_config(style)),
    )
    ..registerSingleton<EventMarkersPort>(_Events());

  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size
    ..padding = const FakeViewPadding(top: 44, bottom: 34);
  addTearDown(tester.view.reset);

  final repository = _Repository();
  final bloc = CalendarBloc(
    getCalendarMonth: GetCalendarMonth(repository),
    selectDateUseCase: SelectDate(repository),
  )..add(LoadCalendarMonth(month));
  addTearDown(bloc.close);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(value: bloc, child: const CalendarHomePage()),
        // Stands in for the app shell's navigation bar.
        bottomNavigationBar: const SizedBox(height: 80),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Row counts with Sunday first: Feb 2026 = 4, Oct 2026 = 5, Jan 2027 = 6.
  final months = {
    '4 rows': DateTime(2026, 2),
    '5 rows': DateTime(2026, 10),
    '6 rows': DateTime(2027, 1),
  };
  const phones = {
    'iPhone SE (320×568)': Size(320, 568),
    'small Android (360×640)': Size(360, 640),
    'iPhone 14 (390×844)': Size(390, 844),
    'Pro Max (430×932)': Size(430, 932),
  };

  for (final MapEntry(key: phone, value: size) in phones.entries) {
    for (final MapEntry(key: rows, value: month) in months.entries) {
      testWidgets('$phone, $rows: whole month above the day sheet', (
        tester,
      ) async {
        await _pumpHome(tester, size: size, month: month);

        final cells = find.byType(DetailedDayCell);
        final expectedCells = int.parse(rows[0]) * 7;
        expect(cells, findsNWidgets(expectedCells));

        final sheetTop = tester
            .getTopLeft(
              find
                  .descendant(
                    of: find.byType(DraggableScrollableSheet),
                    matching: find.byType(ListView),
                  )
                  .first,
            )
            .dy;
        final navTop = size.height - 80;
        for (final element in cells.evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          expect(rect.bottom, lessThanOrEqualTo(sheetTop + .5));
          expect(rect.bottom, lessThan(navTop));
          expect(rect.height, greaterThanOrEqualTo(40));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('tapping another day selects it and moves the sheet to it', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      size: const Size(390, 844),
      month: DateTime(2026, 10),
    );

    await tester.tap(find.text('22').first);
    await tester.pumpAndSettle();
    final bloc = BlocProvider.of<CalendarBloc>(
      tester.element(find.byType(CalendarHomePage)),
    );
    final state = bloc.state as CalendarLoaded;
    expect(state.selectedDate?.date, DateTime(2026, 10, 22));
    expect(find.textContaining('Oct 22'), findsWidgets);
  });

  testWidgets('the sheet expands when dragged up', (tester) async {
    await _pumpHome(
      tester,
      size: const Size(390, 844),
      month: DateTime(2026, 10),
    );
    final sheet = find
        .descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(ListView),
        )
        .first;
    final before = tester.getTopLeft(sheet).dy;

    await tester.drag(sheet, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(sheet).dy, lessThan(before - 200));
    expect(find.text('Full day details'), findsOneWidget);
  });

  for (final style in CalendarGridStyle.values) {
    testWidgets('${style.name} grid fits a small phone without overflow', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        size: const Size(320, 568),
        month: DateTime(2027, 1),
        style: style,
      );
      expect(find.byType(CalendarGrid), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
