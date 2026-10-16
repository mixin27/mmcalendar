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
}
