import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart' show Rect, Size;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('project document survives a versioned JSON round trip', () {
    final now = DateTime(2027, 1, 1);
    final project = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'project-1',
      source: const CalendarStudioSource(year: 2027),
      now: now,
    );
    final result = CalendarStudioDocumentCodec.decode(
      CalendarStudioDocumentCodec.encode(project),
    );
    expect(result, project);
  });

  test('year project assigns the correct month and year to every page', () {
    final project = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'project-2',
      source: const CalendarStudioSource(year: 2027, month: 11),
      now: DateTime(2027),
    );

    expect((project.pages[0].year, project.pages[0].month), (2027, 11));
    expect((project.pages[2].year, project.pages[2].month), (2028, 1));
    expect((project.pages[11].year, project.pages[11].month), (2028, 10));
  });

  test('preset catalog matches all six mockup designs', () {
    expect(
      CalendarStudioTemplates.all.map((template) => template.id),
      containsAllInOrder([
        'blank',
        'jade-wall',
        'ledger-desk',
        'plain',
        'annual',
        'square',
        'story',
      ]),
    );
    expect(CalendarStudioTemplates.byId('square').name, 'Moonlight post');
    expect(CalendarStudioTemplates.byId('story').name, 'Lacquer story');
  });

  test('Jade preset preserves the HTML artboard geometry and layer data', () {
    final project = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'jade-geometry',
      source: const CalendarStudioSource(
        year: 2027,
        period: CalendarStudioPeriod.month,
      ),
      now: DateTime(2027),
    );
    final blocks = {
      for (final block in project.pages.single.blocks) block.id: block,
    };

    expect(
      blocks['hero']!.bounds.resolve(const Size(595, 842)),
      const Rect.fromLTWH(0, 0, 595, 292),
    );
    expect(
      blocks['grid']!.bounds.resolve(const Size(595, 842)),
      const Rect.fromLTWH(36, 410, 523, 344),
    );
    expect(
      blocks['legend']!.bounds.resolve(const Size(595, 842)),
      const Rect.fromLTWH(36, 766, 523, 40),
    );
    expect(blocks['hero']!.content['kind'], 'jadeHero');
    expect(blocks['month-mm']!.content['text'], 'ဇန်နဝါရီ');
    expect(blocks['era']!.content['text'], isNotEmpty);
  });

  test('annual preset is one sheet with twelve independent month grids', () {
    final project = CalendarStudioTemplates.byId('annual').create(
      id: 'annual-geometry',
      source: const CalendarStudioSource(year: 2027),
      now: DateTime(2027),
    );
    final grids = project.pages.single.blocks.where(
      (block) => block.type == CalendarStudioBlockType.calendarGrid,
    );

    expect(project.pages, hasLength(1));
    expect(grids, hasLength(12));
    expect(
      grids.map((block) => block.content['month']),
      orderedEquals(List.generate(12, (index) => index + 1)),
    );
  });
}
