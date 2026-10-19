import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026);

  test(
    'bindings regenerate the built-in titles for every month and language',
    () {
      var bound = 0;
      for (final template in CalendarStudioTemplates.all) {
        for (final language in CalendarStudioLanguage.values) {
          final project = template.create(
            id: 'p',
            source: CalendarStudioSource(year: 2027, language: language),
            now: now,
          );
          // Re-applying any page's bindings for every month must give exactly
          // what the template writes for that month.
          final first = project.pages.first;
          for (final page in project.pages) {
            for (var i = 0; i < page.blocks.length; i++) {
              final block = page.blocks[i];
              if (CalendarStudioBindings.of(block) == null) continue;
              bound++;
              final regenerated = CalendarStudioBindings.apply(
                first.blocks[i],
                language: language,
                year: page.year,
                month: page.month,
              );
              expect(
                regenerated.content,
                block.content,
                reason: '${template.id} ${language.name} ${page.label}',
              );
            }
          }
        }
      }
      expect(bound, greaterThan(100));
    },
  );

  test('detects month, year and era text in any language', () {
    expect(
      CalendarStudioBindings.detect('ဇန်နဝါရီ', 2027, 1),
      CalendarStudioBinding.monthTitle,
    );
    expect(
      CalendarStudioBindings.detect('JANUARY', 2027, 1),
      CalendarStudioBinding.monthTitle,
    );
    expect(
      CalendarStudioBindings.detect('၂၀၂၇', 2027, 1),
      CalendarStudioBinding.yearTitle,
    );
    expect(
      CalendarStudioBindings.detect('January 2027', 2027, 1),
      CalendarStudioBinding.monthYear,
    );
    expect(
      CalendarStudioBindings.detect(
        CalendarStudioBindings.eraLine(2027, 1),
        2027,
        1,
      ),
      CalendarStudioBinding.eraLine,
    );
    expect(CalendarStudioBindings.detect('February', 2027, 1), isNull);
    expect(CalendarStudioBindings.detect('Happy new year', 2027, 1), isNull);
  });

  test('a detected title keeps its subtitle and capitals', () {
    const block = CalendarStudioBlock(
      id: 't',
      type: CalendarStudioBlockType.text,
      name: 'Title',
      bounds: StudioRect(left: 0, top: 0, width: 1, height: .1),
      content: {'text': 'ဇန်နဝါရီ', 'subtitle': 'JANUARY'},
    );
    final marked = CalendarStudioBindings.markDetected(
      block,
      year: 2027,
      month: 1,
    );
    expect(CalendarStudioBindings.of(marked), CalendarStudioBinding.monthTitle);

    final march = CalendarStudioBindings.apply(
      marked,
      language: CalendarStudioLanguage.both,
      year: 2027,
      month: 3,
    );
    expect(march.content['text'], 'မတ်');
    expect(march.content['subtitle'], 'March');

    final upper = CalendarStudioBindings.apply(
      CalendarStudioBindings.markDetected(
        block.copyWith(content: const {'text': 'JANUARY 2027'}),
        year: 2027,
        month: 1,
      ),
      language: CalendarStudioLanguage.english,
      year: 2028,
      month: 6,
    );
    expect(upper.content['text'], 'JUNE 2028');

    final unbound = CalendarStudioBindings.unbind(marked);
    expect(CalendarStudioBindings.of(unbound), isNull);
    expect(unbound.content, block.content);
  });
}
