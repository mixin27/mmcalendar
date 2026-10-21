import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Template legends name no font or colour. They used to inherit the host:
  // white on white paper under a dark app theme, and boxes for Myanmar in
  // export, which has no theme at all.
  testWidgets('legend text follows the page, not the app theme', (
    tester,
  ) async {
    final project = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'legend',
      source: const CalendarStudioSource(
        year: 2027,
        month: 1,
        period: CalendarStudioPeriod.month,
      ),
      now: DateTime(2027),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Material(
          child: SizedBox(
            width: 595,
            height: 842,
            child: CalendarStudioScene(
              page: project.pages.first,
              source: project.source,
            ),
          ),
        ),
      ),
    );

    final label = tester.renderObject<RenderParagraph>(
      find.textContaining('Public holiday'),
    );
    final style = label.text.style!;
    expect(style.fontFamily, CalendarStudioFontCatalog.sansMyanmar);
    expect(style.fontFamilyFallback, [CalendarStudioFontCatalog.serifMyanmar]);
    expect(style.color, const Color(0xFF15201D));
  });
}
