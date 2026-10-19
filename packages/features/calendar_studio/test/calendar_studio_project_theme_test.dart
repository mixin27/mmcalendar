import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';

const _rosePrimary = 0xFF8C3B4D;

Future<CalendarStudioController> _create(
  String templateId, {
  CalendarStudioPeriod period = CalendarStudioPeriod.month,
}) async {
  final controller = CalendarStudioController(
    CalendarStudioConfiguration(projects: _MemoryStore()),
  );
  await controller.create(
    templateId,
    CalendarStudioSource(year: 2027, period: period),
  );
  return controller;
}

Iterable<int> _colors(CalendarStudioPage page) sync* {
  yield page.canvas.backgroundColor;
  for (final block in page.blocks) {
    for (final MapEntry(:key, :value) in block.style.entries) {
      if (value is int && CalendarStudioRetheme.isColorKey(key)) yield value;
    }
  }
}

void main() {
  test('the library has every preset theme and the plain ones', () {
    final rose = CalendarStudioProjectThemes.library.firstWhere(
      (t) => t.id == 'love_relationship',
    );
    expect(rose.name, 'Rose Bond');
    expect(rose.color('primary'), _rosePrimary);
    expect(rose.displayFont, 'Cormorant Garamond');
    for (final id in ['jade', 'lacquer', 'indigo', 'saffron', 'mono']) {
      final theme = CalendarStudioProjectThemes.library.firstWhere(
        (t) => t.id == id,
      );
      for (final role in CalendarStudioProjectTheme.roles) {
        expect(theme.colors[role], isNotNull, reason: '$id $role');
      }
    }
  });

  test('a preset project uses its preset theme', () async {
    final controller = await _create('love_relationship');
    expect(controller.project!.theme, isNull);
    expect(controller.theme!.id, 'love_relationship');
    controller.dispose();
  });

  test('older templates infer a theme from their colours', () async {
    final controller = await _create('jade-wall');
    final theme = controller.theme!;
    expect(theme.color('paper'), controller.currentPage.canvas.backgroundColor);
    final grid = controller.currentPage.blocks.firstWhere(
      (b) => b.type == CalendarStudioBlockType.calendarGrid,
    );
    expect(theme.colors['ink'], grid.style['inkColor']);
    expect(theme.colors['primary'], isNotNull);
    controller.dispose();
  });

  test('switching theme recolours every page as one undo step', () async {
    final controller = await _create(
      'love_relationship',
      period: CalendarStudioPeriod.year,
    );
    expect(controller.project!.pages.length, greaterThan(1));

    // A colour the person picked themselves is not a theme role.
    final first = controller.currentPage.blocks.first;
    controller.updateBlock(
      first.copyWith(style: {...first.style, 'color': 0xFF123456}),
    );
    final before = controller.project!;

    final indigo = CalendarStudioProjectThemes.library.firstWhere(
      (t) => t.id == 'indigo',
    );
    controller.applyTheme(indigo);
    final after = controller.project!;
    expect(after.theme, indigo);
    expect(controller.theme, indigo);
    for (final page in after.pages) {
      final colors = _colors(page).toList();
      expect(colors, isNot(contains(_rosePrimary)), reason: page.label);
      expect(colors, contains(indigo.color('primary')), reason: page.label);
      expect(page.canvas.backgroundColor, indigo.color('paper'));
    }
    expect(after.pages.first.blocks.first.style['color'], 0xFF123456);

    controller.undo();
    expect(controller.project!.pages, before.pages);
    expect(controller.project!.theme, isNull);
    controller.dispose();
  });

  test('a custom role edit becomes a custom theme', () {
    final rose = CalendarStudioProjectThemes.library.first;
    final custom = rose.withColor('primary', 0xFF000000);
    expect(custom.id, 'custom');
    expect(custom.name, '${rose.name} (custom)');
    expect(custom.color('primary'), 0xFF000000);
    expect(custom.withColor('ink', 0xFF111111).name, custom.name);
  });

  test('the codec keeps the theme, and older files have none', () async {
    final controller = await _create('love_relationship');
    final plain = CalendarStudioDocumentCodec.encode(controller.project!);
    expect(plain.containsKey('theme'), isFalse);
    expect(CalendarStudioDocumentCodec.decode(plain).theme, isNull);

    controller.applyTheme(CalendarStudioProjectThemes.library.last);
    final json = CalendarStudioDocumentCodec.encode(controller.project!);
    final decoded = CalendarStudioDocumentCodec.decode(json);
    expect(decoded.theme, controller.project!.theme);
    expect(decoded, controller.project);
    controller.dispose();
  });
}

class _MemoryStore implements CalendarStudioProjectStore {
  final values = <String, CalendarStudioProject>{};
  @override
  Future<void> delete(String id) async => values.remove(id);
  @override
  Future<List<CalendarStudioProject>> list() async => values.values.toList();
  @override
  Future<CalendarStudioProject?> load(String id) async => values[id];
  @override
  Future<void> save(CalendarStudioProject project) async =>
      values[project.id] = project;
}
