import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';

final _presets = CalendarStudioTemplates.all
    .where((template) => template.collection != null)
    .toList();

CalendarStudioProject _create(
  CalendarStudioTemplate template, {
  CalendarStudioLanguage language = CalendarStudioLanguage.both,
}) => template.create(
  id: 'test-${template.id}',
  source: CalendarStudioSource(year: 2027, language: language),
  now: DateTime(2027),
);

final _myanmar = RegExp('[က-႟]');

void main() {
  test('round-2 presets are registered with gallery metadata', () {
    expect(_presets.length, greaterThanOrEqualTo(8));
    for (final template in _presets) {
      expect(template.moods, isNotEmpty, reason: template.id);
      expect(template.palette, hasLength(5), reason: template.id);
      expect(template.category, contains('·'), reason: template.id);
    }
  });

  for (final template in _presets) {
    group(template.name, () {
      final project = _create(template);
      final first = project.pages.first;
      final paper = first.canvas.backgroundColor;

      test('pages follow the project period', () {
        expect(project.pages, hasLength(template.monthly ? 12 : 1));
        for (final page in project.pages) {
          final title = page.blocks
              .where((block) => block.name == 'Month title')
              .firstOrNull;
          if (title == null) continue;
          expect(title.content['subtitle'], page.label);
          expect(title.content['text'] as String, matches(_myanmar));
        }
      });

      test('dates, holidays and weekends stay readable and distinct', () {
        for (final grid in first.blocks.where(
          (block) => block.type == CalendarStudioBlockType.calendarGrid,
        )) {
          final style = grid.style;
          expect(
            contrastRatio(style['inkColor']! as int, paper),
            greaterThanOrEqualTo(4.5),
            reason: 'dates',
          );
          for (final key in ['holidayColor', 'weekendColor', 'sabbathColor']) {
            expect(
              contrastRatio(style[key]! as int, paper),
              greaterThanOrEqualTo(3),
              reason: key,
            );
          }
          expect(style['holidayColor'], isNot(style['weekendColor']));
          expect(style['sabbathColor'], isNot(style['weekendColor']));
        }
      });

      test('Myanmar text is never slanted', () {
        for (final block in first.blocks.where(
          (block) => block.type == CalendarStudioBlockType.text,
        )) {
          if (_myanmar.hasMatch(block.content['text'] as String? ?? '')) {
            expect(block.style['italic'], isNot(true), reason: block.name);
          }
        }
      });

      test('English projects have English titles', () {
        final english = _create(
          template,
          language: CalendarStudioLanguage.english,
        );
        for (final block in english.pages.first.blocks) {
          if (block.name == 'Month title' || block.name == 'Year') {
            expect(block.content['text'] as String, isNot(matches(_myanmar)));
          }
        }
      });

      test('content blocks stay on the page and do not overlap', () {
        const content = {
          CalendarStudioBlockType.text,
          CalendarStudioBlockType.calendarGrid,
          CalendarStudioBlockType.holidayLegend,
          CalendarStudioBlockType.eventList,
        };
        final blocks = first.blocks
            .where((block) => content.contains(block.type))
            .toList();
        for (final block in first.blocks) {
          expect(
            block.bounds.right,
            lessThanOrEqualTo(1.0001),
            reason: block.name,
          );
          expect(
            block.bounds.bottom,
            lessThanOrEqualTo(1.0001),
            reason: block.name,
          );
        }
        for (var i = 0; i < blocks.length; i++) {
          for (var j = i + 1; j < blocks.length; j++) {
            final a = blocks[i].bounds;
            final b = blocks[j].bounds;
            final overlapX =
                (a.right < b.right ? a.right : b.right) -
                (a.left > b.left ? a.left : b.left);
            final overlapY =
                (a.bottom < b.bottom ? a.bottom : b.bottom) -
                (a.top > b.top ? a.top : b.top);
            expect(
              overlapX > .002 && overlapY > .002,
              isFalse,
              reason: '${blocks[i].name} overlaps ${blocks[j].name}',
            );
          }
        }
      });
    });
  }
}
