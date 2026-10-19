import 'package:alchemist/alchemist.dart';
import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _source = CalendarStudioSource(
  year: 2027,
  month: 4, // Thingyan, full moon and Sabbath days all on one page.
  period: CalendarStudioPeriod.month,
);

void main() {
  final daysByTemplate = <String, Map<int, List<CalendarStudioDayData>>>{};
  final pages = <String, CalendarStudioPage>{};

  setUpAll(() async {
    const provider = MyanmarCalendarStudioDataProvider();
    for (final template in CalendarStudioTemplates.all) {
      final project = template.create(
        id: 'golden-${template.id}',
        source: _source,
        now: DateTime(2027),
      );
      final page = project.pages.first;
      pages[template.id] = page;
      final months = {
        for (final block in page.blocks)
          if (block.type == CalendarStudioBlockType.calendarGrid)
            block.content['month'] as int? ?? page.month,
      };
      daysByTemplate[template.id] = {
        for (final month in months)
          month: await provider.daysFor(
            _source.copyWith(year: page.year, month: month),
            month: month,
          ),
      };
    }
  });

  for (final template in CalendarStudioTemplates.all) {
    goldenTest(
      'template ${template.id} renders its first page',
      fileName: 'template_${template.id.replaceAll('-', '_')}',
      constraints: const BoxConstraints(maxWidth: 480),
      builder: () => GoldenTestScenario(
        name: template.name,
        child: SizedBox(
          width: 420,
          child: CalendarStudioScene(
            page: pages[template.id]!,
            source: _source,
            resolvedDaysByMonth: daysByTemplate[template.id]!,
          ),
        ),
      ),
    );
  }

  goldenTest(
    'selected block shows handles, rotate grip and guides',
    fileName: 'editor_selection_chrome',
    constraints: const BoxConstraints(maxWidth: 480),
    builder: () {
      final page = pages['jade-wall']!;
      final grid = page.blocks.firstWhere(
        (block) => block.type == CalendarStudioBlockType.calendarGrid,
      );
      return GoldenTestScenario(
        name: 'Jade wall · grid selected',
        child: SizedBox(
          width: 420,
          child: CalendarStudioScene(
            page: page,
            source: _source,
            resolvedDaysByMonth: daysByTemplate['jade-wall']!,
            selectedBlockId: grid.id,
            showSafeArea: true,
            onSelect: (_) {},
            onTransform: (_) {},
            guides: const [
              StudioGuide.vertical(.5),
              StudioGuide.horizontal(.25),
            ],
          ),
        ),
      );
    },
  );

  goldenTest(
    'themed blocks: lined grid, legend, lists, outline shape',
    fileName: 'themed_blocks',
    constraints: const BoxConstraints(maxWidth: 480),
    builder: () {
      const spec = CalendarStudioThemeSpec(
        paper: 0xFFF4F1E8,
        primary: 0xFF3F5E3A,
        accent: 0xFFA9744F,
        ink: 0xFF2B2A22,
        inkMuted: 0xFF6B6A58,
        line: 0xFFDAD5C2,
        holiday: 0xFF8C4B5B,
        weekend: 0xFF3F5E3A,
        sabbath: 0xFF8A5A1F,
      );
      CalendarStudioBlock block(
        String id,
        CalendarStudioBlockType type,
        StudioRect bounds, {
        Map<String, Object?> content = const {},
        Map<String, Object?> style = const {},
      }) => CalendarStudioBlock(
        id: id,
        type: type,
        name: id,
        bounds: bounds,
        content: content,
        style: style,
      );
      final page = CalendarStudioPage(
        id: 'themed',
        label: 'April',
        year: 2027,
        month: 4,
        canvas: const StudioCanvas(
          width: 210,
          height: 297,
          backgroundColor: 0xFFF4F1E8,
        ),
        blocks: [
          block(
            'title',
            CalendarStudioBlockType.text,
            const StudioRect(left: .08, top: .05, width: .6, height: .08),
            content: const {'text': 'ဧပြီ'},
            style: const {
              'color': 0xFF2B2A22,
              'fontSize': 40,
              'lineHeight': 1.6,
            },
          ),
          block(
            'ring',
            CalendarStudioBlockType.shape,
            const StudioRect(left: .74, top: .04, width: .18, height: .1),
            content: const {'shape': 'oval'},
            style: const {
              'color': 0xFFA9744F,
              'strokeColor': 0xFFA9744F,
              'strokeWidth': 3,
              'fill': 'none',
            },
          ),
          block(
            'grid',
            CalendarStudioBlockType.calendarGrid,
            const StudioRect(left: .08, top: .17, width: .84, height: .5),
            content: const {'mini': false, 'calendarStyle': 'standard'},
            style: spec.gridStyle(),
          ),
          block(
            'events',
            CalendarStudioBlockType.eventList,
            const StudioRect(left: .08, top: .7, width: .4, height: .14),
            content: const {
              'title': 'This month',
              'placeholder': ['4 — Family lunch', '12 — Pagoda visit'],
            },
            style: {
              'inkColor': spec.ink,
              'mutedColor': spec.inkMuted,
              'fontSize': 11,
            },
          ),
          block(
            'notes',
            CalendarStudioBlockType.eventList,
            const StudioRect(left: .52, top: .7, width: .4, height: .14),
            content: const {'title': 'Notes', 'kind': 'notes'},
            style: {
              'inkColor': spec.ink,
              'lineColor': spec.line,
              'fontSize': 11,
            },
          ),
          block(
            'legend',
            CalendarStudioBlockType.holidayLegend,
            const StudioRect(left: .08, top: .88, width: .84, height: .06),
            content: const {'kind': 'themed'},
            style: spec.legendStyle(fontSize: 11),
          ),
        ],
      );
      return GoldenTestScenario(
        name: 'Themed blocks',
        child: SizedBox(
          width: 420,
          child: CalendarStudioScene(
            page: page,
            source: _source,
            resolvedDaysByMonth: daysByTemplate['plain']!,
          ),
        ),
      );
    },
  );
}
