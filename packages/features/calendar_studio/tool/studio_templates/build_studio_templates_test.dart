// Builds the Calendar Studio template pack: for each design a year project
// (.mmcstudio), a reusable template (.mmctemplate) and a contact sheet.
//
//   flutter test tool/studio_templates/build_studio_templates_test.dart
//
// STUDIO_TEMPLATES_YEAR (default 2027) and STUDIO_TEMPLATES_OUT (default the
// repo's docs/studio-templates) change the year and the folder. It lives in
// tool/, so the package's own `flutter test` never runs it.
import 'dart:convert';
import 'dart:io';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'design.dart';
import 'designs/business.dart';
import 'designs/family.dart';
import 'designs/friendship.dart';
import 'designs/relationship.dart';
import 'page_builder.dart';

final List<StudioTemplateDesign> designs = [
  const LoveLetters(),
  const SweetPastel(),
  const Moonlit(),
  const FamilyAlbum(),
  const LittleHome(),
  const GoodTimes(),
  const Postcards(),
  const CleanCorporate(),
  const StudioBold(),
];

const topics = {
  'relationship': 'Relationship',
  'family': 'Family',
  'friendship': 'Friendship',
  'business': 'Business',
};

final year =
    int.tryParse(Platform.environment['STUDIO_TEMPLATES_YEAR'] ?? '') ?? 2027;
final out =
    Platform.environment['STUDIO_TEMPLATES_OUT'] ??
    '../../../docs/studio-templates';
final now = DateTime.utc(year - 1, 10, 27);

const source = CalendarStudioLanguage.both;

Map<String, Object?> _source(int year) => {
  'year': year,
  'month': 1,
  'period': 'year',
  'language': source.name,
  'weekStartsMonday': false,
  'timeZoneLabel': 'Myanmar Time (UTC+6:30)',
  'showMyanmarDate': true,
  'showMoonPhases': true,
  'showHolidays': true,
  // Astrology dots crowd small grids; moon days and holidays stay.
  'showAstrology': false,
  'showEvents': true,
};

Map<String, Object?> _page(
  StudioTemplateDesign design,
  int index,
  String label,
  int month,
  PageBuilder page,
) => {
  'id': 'page-$index',
  'label': label,
  'year': year,
  'month': month,
  'canvas': {
    'width': design.format.canvasWidth,
    'height': design.format.canvasHeight,
    'safeInset': 0.04,
    'bleed': 0.0,
    'backgroundColor': design.palette.paper,
  },
  'blocks': page.blocks,
};

/// The year project: a cover and twelve months, titles filled in by
/// Studio's own bindings.
CalendarStudioProject buildProject(
  StudioTemplateDesign design, {
  String? Function()? photo,
}) {
  final context = DesignContext(template: false, photo: photo ?? () => null);
  final cover = PageBuilder(design.palette);
  design.cover(cover, context);
  final pages = [_page(design, 0, 'Cover', 1, cover)];
  for (var month = 1; month <= 12; month++) {
    final page = PageBuilder(design.palette);
    design.month(page, month, context);
    pages.add(
      _page(
        design,
        month,
        CalendarStudioBindings.englishMonths[month - 1],
        month,
        page,
      ),
    );
  }
  final project = CalendarStudioDocumentCodec.decode({
    'schemaVersion': 3,
    'id': 'pack-${design.id}-$year',
    'name': '${design.name} $year',
    'templateId': design.basePresetId,
    'createdAt': now.toIso8601String(),
    'updatedAt': now.toIso8601String(),
    'source': _source(year),
    'defaultExportPreset': {
      'id': 'page-pdf',
      'label': 'Page size print',
      'format': 'pdf',
      'dpi': 300,
      'width': 2480,
      'height': 3508,
    },
    'pages': pages,
  });
  return project.copyWith(
    pages: [
      for (final page in project.pages)
        page.copyWith(
          blocks: [
            for (final block in page.blocks)
              CalendarStudioBindings.apply(
                block,
                language: source,
                year: page.year,
                month: page.month,
              ),
          ],
        ),
    ],
  );
}

/// The reusable design: one month page that Studio repeats for any year.
CalendarStudioUserTemplate buildTemplate(
  StudioTemplateDesign design, {
  String? Function()? photo,
  Uint8List? preview,
}) {
  final page = PageBuilder(design.palette);
  design.month(
    page,
    design.templateMonth,
    DesignContext(template: true, photo: photo ?? () => null),
  );
  final decoded = CalendarStudioDocumentCodec.decode({
    'schemaVersion': 3,
    'id': 'template',
    'name': design.name,
    'templateId': design.basePresetId,
    'createdAt': now.toIso8601String(),
    'updatedAt': now.toIso8601String(),
    'source': _source(year),
    'pages': [_page(design, 0, 'Template', design.templateMonth, page)],
  });
  return CalendarStudioUserTemplate(
    id: 'studio-pack-${design.id}',
    name: design.name,
    author: 'Myanmar Calendar',
    description: design.description,
    basePresetId: design.basePresetId,
    category: design.format.category,
    canvas: decoded.pages.single.canvas,
    monthly: true,
    moods: design.moods,
    palette: design.palette.swatches,
    blocks: decoded.pages.single.blocks,
    createdAt: now,
    updatedAt: now,
    preview: preview,
  );
}

/// Soft gradients standing in for photos in previews.
class _Samples implements CalendarStudioAssetStore {
  static const tones = [
    [(0xE8, 0xC4, 0xB8), (0x9A, 0x5B, 0x4D)],
    [(0xF6, 0xDE, 0xB0), (0xC9, 0x8A, 0x5A)],
    [(0xC2, 0xD3, 0xE4), (0x5F, 0x7F, 0xA8)],
    [(0xD7, 0xE6, 0xCF), (0x6E, 0x93, 0x72)],
    [(0xE9, 0xD5, 0xEC), (0x8E, 0x6E, 0xA8)],
    [(0xF2, 0xD6, 0xC9), (0xB9, 0x7A, 0x56)],
  ];
  final photos = [
    for (final tone in tones)
      () {
        final (a, b) = (tone[0], tone[1]);
        final image = img.Image(width: 480, height: 480);
        for (var y = 0; y < 480; y++) {
          for (var x = 0; x < 480; x++) {
            final t = x / 480 * .45 + y / 480 * .55;
            int mix(int p, int q) => (p + (q - p) * t).round();
            image.setPixelRgb(
              x,
              y,
              mix(a.$1, b.$1),
              mix(a.$2, b.$2),
              mix(a.$3, b.$3),
            );
          }
        }
        return Uint8List.fromList(img.encodeJpg(image, quality: 88));
      }(),
  ];

  String? Function() counter() {
    var next = 0;
    return () => 'sample-${next++ % photos.length}';
  }

  @override
  Future<List<int>?> loadBytes(String assetId) async =>
      photos[int.parse(assetId.split('-').last)];
  @override
  Future<CalendarStudioAsset?> load(String assetId) async => null;
  @override
  Future<CalendarStudioAsset> importAsset(CalendarStudioAssetInput input) =>
      throw UnimplementedError();
  @override
  Future<void> deleteUnusedAssets(Set<String> usedAssetIds) async {}
}

/// All pages side by side, five to a row.
Uint8List contactSheet(List<Uint8List> pages, StudioFormat format) {
  const columns = 5;
  const gap = 16;
  final (cellWidth, cellHeight) = format.pixels(300);
  final rows = (pages.length / columns).ceil();
  final sheet = img.Image(
    width: columns * cellWidth + (columns + 1) * gap,
    height: rows * cellHeight + (rows + 1) * gap,
  )..clear(img.ColorRgb8(236, 232, 228));
  for (var i = 0; i < pages.length; i++) {
    final page = img.copyResize(
      img.decodePng(pages[i])!,
      width: cellWidth,
      height: cellHeight,
      interpolation: img.Interpolation.average,
    );
    img.compositeImage(
      sheet,
      page,
      dstX: gap + (i % columns) * (cellWidth + gap),
      dstY: gap + (i ~/ columns) * (cellHeight + gap),
    );
  }
  return Uint8List.fromList(img.encodePng(sheet));
}

Future<void> _loadFonts() async {
  Future<void> load(String family, Directory folder) async {
    final loader = FontLoader(family);
    for (final file in folder.listSync()) {
      if (file.path.endsWith('.ttf')) {
        final bytes = File(file.path).readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
    }
    await loader.load();
  }

  for (final font in CalendarStudioFontCatalog.fonts) {
    final folder = font.family.toLowerCase().replaceAll(' ', '');
    await load(
      CalendarStudioFontCatalog.resolve(font.family)!,
      Directory('assets/fonts/$folder'),
    );
  }
  // The host app's face for Myanmar UI text.
  await load(
    CalendarStudioFontCatalog.sansMyanmar,
    Directory('../../../apps/myanmar_calendar/assets/fonts/google_fonts'),
  );
}

String _readme() {
  final rows = StringBuffer();
  for (final MapEntry(key: topic, value: title) in topics.entries) {
    rows.writeln('\n## $title\n');
    for (final design in designs.where((d) => d.topic == topic)) {
      rows
        ..writeln('### ${design.name}\n')
        ..writeln('${design.description}\n')
        ..writeln(
          '${design.format.category.split(' · ').last} · '
          'moods: ${design.moods.join(', ')} · '
          '[$year project](${design.topic}/${design.id}-$year.mmcstudio) · '
          '[template (any year)](${design.topic}/${design.id}.mmctemplate)\n',
        )
        ..writeln('![${design.name}](${design.topic}/${design.id}.png)\n');
    }
  }
  return '''
# Calendar Studio template pack

Ready-made Calendar Studio designs to share and import, in Myanmar and
English, with Myanmar dates, moon days and holidays in every grid. Photo
frames are empty: tap one, then **Replace**, to add your own. Text is
ordinary Studio text you can edit. Previews show soft colours where photos go.

Each design comes two ways:

- **`.mmcstudio`, a $year project**: a cover and twelve months, each month
  laid out a little differently. In the app: Calendar Studio → **Import
  project**.
- **`.mmctemplate`, a reusable template**: one month design that works for
  any year. In the app: Calendar Studio → **New calendar** → **Import
  template** (top bar). It's then listed under **My templates**: pick it and
  choose the year.

Studio won't export a project while a photo frame is empty; logo frames on
the business designs can stay empty.
$rows
## Regenerating

The files and previews come from
`packages/features/calendar_studio/tool/studio_templates/`. See its README to
build them for another year or add a design.
''';
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('build the template pack', (tester) async {
    final samples = _Samples();
    final renderer = CalendarStudioRasterRenderer(
      dataProvider: const MyanmarCalendarStudioDataProvider(),
      assetStore: samples,
    );
    Future<Uint8List> render(
      CalendarStudioProject project,
      CalendarStudioPage page,
      StudioFormat format, {
      int long = 900,
    }) async {
      final (width, height) = format.pixels(long);
      return (await tester.runAsync(
        () => renderer.renderPage(project, page, width: width, height: height),
      ))!;
    }

    expect(designs.map((d) => d.id).toSet(), hasLength(designs.length));
    for (final design in designs) {
      final folder = Directory('$out/${design.topic}')
        ..createSync(recursive: true);

      // Year project.
      final project = buildProject(design);
      final projectFile = (await tester.runAsync(
        () => CalendarStudioProjectBundle.export(
          project,
          fileName: '${design.id}-$year',
          now: now,
        ),
      ))!;
      File(
        '${folder.path}/${projectFile.name}',
      ).writeAsBytesSync(projectFile.bytes);
      final readProject = (await tester.runAsync(
        () => CalendarStudioProjectBundle.read(
          Uint8List.fromList(projectFile.bytes),
        ),
      ))!;
      expect(readProject.project.pages, hasLength(13), reason: design.id);
      expect(readProject.missingAssetIds, isEmpty, reason: design.id);

      // Previews of every page, with stand-in photos.
      final preview = buildProject(design, photo: samples.counter());
      final pages = [
        for (final page in preview.pages)
          await render(preview, page, design.format),
      ];
      File(
        '${folder.path}/${design.id}.png',
      ).writeAsBytesSync(contactSheet(pages, design.format));

      // Template, with its first page as the gallery picture.
      final sample =
          CalendarStudioUserTemplates.toTemplate(
            buildTemplate(design, photo: samples.counter()),
          ).create(
            id: 'preview',
            source: CalendarStudioSource(
              year: year,
              month: design.templateMonth,
              language: source,
              showAstrology: false,
            ),
            now: now,
          );
      final picture = await render(
        sample,
        sample.pages.first,
        design.format,
        long: 600,
      );
      final template = buildTemplate(design, preview: picture);
      final templateFile = (await tester.runAsync(
        () => CalendarStudioTemplateBundle.export(
          template,
          fileName: design.id,
          now: now,
        ),
      ))!;
      File(
        '${folder.path}/${templateFile.name}',
      ).writeAsBytesSync(templateFile.bytes);
      final readTemplate = (await tester.runAsync(
        () => CalendarStudioTemplateBundle.read(
          Uint8List.fromList(templateFile.bytes),
        ),
      ))!;
      expect(readTemplate.template.blocks, isNotEmpty, reason: design.id);

      // The template makes a right calendar for another year too.
      final next = CalendarStudioUserTemplates.toTemplate(template).create(
        id: 'next',
        source: CalendarStudioSource(year: year + 1, language: source),
        now: now,
      );
      expect(next.pages, hasLength(12), reason: design.id);
      final (nextYear, _) = CalendarStudioBindings.resolve(
        CalendarStudioBinding.yearTitle,
        language: source,
        year: year + 1,
        month: 1,
      );
      final yearBlocks = [
        for (final block in next.pages.first.blocks)
          if (block.content['binding'] == 'yearTitle') block.content['text'],
      ];
      expect(yearBlocks.every((text) => text == nextYear), isTrue);
    }

    File('$out/README.md').writeAsStringSync(_readme());
    File('$out/designs.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert([
        for (final design in designs)
          {
            'id': design.id,
            'name': design.name,
            'topic': design.topic,
            'format': design.format.name,
            'project': '${design.topic}/${design.id}-$year.mmcstudio',
            'template': '${design.topic}/${design.id}.mmctemplate',
            'preview': '${design.topic}/${design.id}.png',
          },
      ]),
    );
  });
}
