import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _spec = CalendarStudioThemeSpec(
  paper: 0xFFFAF6EF,
  primary: 0xFF5B6B4F,
  accent: 0xFFB5793F,
  ink: 0xFF3B3024,
  inkMuted: 0xFF6E6555,
  line: 0xFFDAD2C0,
  holiday: 0xFF9C4B3B,
  weekend: 0xFF5B6B4F,
  sabbath: 0xFF8A5A1F,
);

CalendarStudioPage _page(List<CalendarStudioBlock> blocks) =>
    CalendarStudioPage(
      id: 'p',
      label: 'September',
      year: 2026,
      month: 9,
      canvas: const StudioCanvas(
        width: 210,
        height: 297,
        backgroundColor: 0xFFFAF6EF,
      ),
      blocks: blocks,
    );

Widget _scene(
  List<CalendarStudioBlock> blocks, {
  CalendarStudioSource source = const CalendarStudioSource(
    year: 2026,
    month: 9,
  ),
  List<CalendarStudioDayData>? days,
}) => MaterialApp(
  home: Center(
    child: SizedBox(
      width: 420,
      child: CalendarStudioScene(
        page: _page(blocks),
        source: source,
        resolvedDays: days,
      ),
    ),
  ),
);

void main() {
  test('contrast ratio follows WCAG', () {
    expect(contrastRatio(0xFF000000, 0xFFFFFFFF), closeTo(21, .01));
    expect(contrastRatio(0xFF777777, 0xFF777777), 1);
  });

  test('spec flags the mockups\' unreadable pairings', () {
    expect(_spec.contrastIssues(), isEmpty);
    const panelPop = CalendarStudioThemeSpec(
      paper: 0xFFFFFFFF,
      primary: 0xFF3550E0,
      accent: 0xFFFFC83D,
      ink: 0xFF15131A,
      inkMuted: 0xFF5B5866,
      line: 0xFF15131A,
      holiday: 0xFFFFC83D,
      weekend: 0xFFFFC83D,
      sabbath: 0xFF3550E0,
    );
    final issues = panelPop.contrastIssues();
    expect(issues, contains(startsWith('holiday on paper')));
    expect(issues, contains('holiday and weekend share a colour'));
  });

  testWidgets('legend drops items the project hides', (tester) async {
    final legend = CalendarStudioBlock(
      id: 'legend',
      type: CalendarStudioBlockType.holidayLegend,
      name: 'Legend',
      bounds: const StudioRect(left: .05, top: .9, width: .9, height: .05),
      content: const {
        'kind': 'themed',
        'items': ['sabbath', 'holiday', 'fullMoon', 'newMoon', 'events'],
      },
      style: _spec.legendStyle(),
    );
    await tester.pumpWidget(
      _scene(
        [legend],
        source: const CalendarStudioSource(
          year: 2026,
          month: 9,
          showMoonPhases: false,
          language: CalendarStudioLanguage.english,
        ),
      ),
    );
    expect(find.text('Sabbath'), findsOneWidget);
    expect(find.text('Public holiday'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Full moon'), findsNothing);
    expect(find.text('New moon'), findsNothing);
  });

  testWidgets('event list shows placeholders until real events exist', (
    tester,
  ) async {
    CalendarStudioBlock list({double height = .12}) => CalendarStudioBlock(
      id: 'events',
      type: CalendarStudioBlockType.eventList,
      name: 'Events',
      bounds: StudioRect(left: .05, top: .1, width: .5, height: height),
      content: const {
        'title': 'This month',
        'placeholder': ['4 — Family lunch', '12 — Pagoda visit', '19 — Picnic'],
      },
      style: {
        'inkColor': _spec.ink,
        'mutedColor': _spec.inkMuted,
        'fontSize': 10,
      },
    );
    await tester.pumpWidget(_scene([list()]));
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('12 — Pagoda visit'), findsOneWidget);

    // A short box shows fewer rows instead of clipping one mid-line.
    await tester.pumpWidget(_scene([list(height: .055)]));
    expect(find.text('4 — Family lunch'), findsOneWidget);
    expect(find.text('19 — Picnic'), findsNothing);

    final days = [
      for (var day = 1; day <= 30; day++)
        CalendarStudioDayData(
          date: DateTime(2026, 9, day),
          gregorianLabel: '$day',
          events: day == 8 ? const ['Grandma visits'] : const [],
        ),
    ];
    await tester.pumpWidget(_scene([list()], days: days));
    expect(find.text('8 — Grandma visits'), findsOneWidget);
    expect(find.text('12 — Pagoda visit'), findsNothing);
  });
}
