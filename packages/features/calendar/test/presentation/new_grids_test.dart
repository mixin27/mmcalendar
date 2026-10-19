import 'package:calendar/calendar.dart';
import 'package:calendar/src/presentation/widgets/astro_phrases.dart';
import 'package:calendar/src/presentation/widgets/day_cells.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

// October 2026: Tawthalin wanes into Thadingyut on the 12th; the full moon
// on the 26th is the End of Buddhist Lent.
final _month = DateTime(2026, 10);
final _dates = AppDateUtils.getCalendarGridDates(
  _month,
  firstDayOfWeek: 1,
).map(MyanmarCalendar.getCompleteDate).toList();

CompleteDate _day(int d) =>
    _dates.firstWhere((c) => c.westernMonth == 10 && c.westernDay == d);

final _events = <DateTime, List<CalendarEventItem>>{
  DateTime(2026, 10, 22): [
    CalendarEventItem(
      id: 1,
      title: 'Project review',
      eventDate: DateTime(2026, 10, 22),
      isAllDay: true,
      category: const CalendarEventCategory(
        name: 'Work',
        iconName: 'work',
        colorCode: 0xFF2F9BE0,
      ),
      isRecurring: false,
    ),
  ],
};

Future<void> _pumpGrid(
  WidgetTester tester,
  CalendarGridStyle style, {
  DateTime? selected,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(402, 874);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(
        style: AppStyle.clear,
        colorScheme: AppColorSchemes.modernLight,
      ),
      home: Scaffold(
        body: SizedBox(
          height: 560,
          child: CalendarGrid(
            gridDates: _dates,
            currentMonth: _month,
            today: DateTime(2026, 10, 19),
            selectedDate: selected,
            onDateTap: (_) {},
            eventsByDate: _events,
            gridStyle: style,
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('Myanmar month places mark where Thadingyut begins', () {
    final places = MyanmarMonthPlace.of(_dates);
    final i = _dates.indexOf(_day(12));
    expect(places[i].starts, isTrue);
    expect(places[i].edgeLeft, isTrue, reason: 'the 12th is a Monday');
    expect(places[i].index, places[i - 1].index + 1);
    // The week under it is wholly in Thadingyut; the 18th sits under the
    // 11th, the last of Tawthalin.
    expect(places[_dates.indexOf(_day(18))].edgeTop, isTrue);
    expect(places[_dates.indexOf(_day(13))].starts, isFalse);
  });

  test('astrology tones follow the display options', () {
    DayCellData data(int d, {bool astrology = true}) => DayCellData(
      info: _day(d),
      isToday: false,
      isSelected: false,
      isInMonth: true,
      options: DayCellOptions(showAstrology: astrology),
    );
    // 19th: Sabbath and Pyathada. 22nd: Yatyaza and Thamanyo.
    expect(data(19).astroTones, [AstroTone.sabbath, AstroTone.caution]);
    expect(data(22).astroTones, [AstroTone.good, AstroTone.caution]);
    expect(data(22, astrology: false).astroTones, isEmpty);
    expect(data(19, astrology: false).astroTones, [AstroTone.sabbath]);
  });

  testWidgets('Almanac shows the month start, holiday and events', (
    tester,
  ) async {
    await _pumpGrid(tester, CalendarGridStyle.almanac);
    expect(find.byType(AlmanacDayCell), findsNWidgets(35));
    expect(find.text('Thadingyut'), findsOneWidget);
    expect(find.text('End of Buddhist Lent'), findsOneWidget);
    expect(find.text('Project review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Almanac fits at twice the text size', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpGrid(tester, CalendarGridStyle.almanac);
    expect(tester.takeException(), isNull);
  });
}
