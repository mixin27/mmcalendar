import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Jade wall page for October 2027 with a photo added.
(CalendarStudioProject, CalendarStudioPage) _october() {
  final project = CalendarStudioTemplates.byId('jade-wall').create(
    id: 'source',
    source: const CalendarStudioSource(year: 2027, month: 10),
    now: DateTime(2027),
  );
  final page = project.pages.first;
  return (
    project,
    page.copyWith(
      blocks: [
        ...page.blocks,
        const CalendarStudioBlock(
          id: 'photo',
          type: CalendarStudioBlockType.image,
          name: 'Photo',
          bounds: StudioRect(left: .1, top: .1, width: .3, height: .2),
          content: {
            'assetId': 'edited',
            'originalAssetId': 'original',
            'editorState': '{"x":1}',
            'fit': 'cover',
          },
        ),
      ],
    ),
  );
}

CalendarStudioUserTemplate _capture({required bool keepPhotos}) {
  final (project, page) = _october();
  return CalendarStudioUserTemplates.capture(
    project,
    page,
    name: 'Gold wall',
    author: 'Aye',
    blocks: CalendarStudioUserTemplates.detectBindings(page),
    keepPhotos: keepPhotos,
    moods: const ['Gold'],
    now: DateTime.utc(2027, 3),
    preview: Uint8List.fromList([137, 80, 78, 71]),
  );
}

String _textOf(CalendarStudioPage page, String id) =>
    page.blocks.firstWhere((block) => block.id == id).content['text']!
        as String;

void main() {
  test('saving marks the month and year titles as bound', () {
    final template = _capture(keepPhotos: true);
    CalendarStudioBinding? bindingOf(String id) => CalendarStudioBindings.of(
      template.blocks.firstWhere((block) => block.id == id),
    );
    expect(bindingOf('month-mm'), CalendarStudioBinding.monthTitle);
    expect(bindingOf('month-en'), CalendarStudioBinding.monthYear);
    expect(bindingOf('year-mm'), CalendarStudioBinding.yearTitle);
    expect(bindingOf('era'), CalendarStudioBinding.eraLine);
    expect(template.basePresetId, 'jade-wall');
    expect(template.category, 'Wall · A4 portrait');
    expect(template.monthly, isTrue);
    expect(template.palette, isNotEmpty);
  });

  test('without Keep photos, photo frames stay but the photos go', () {
    final template = _capture(keepPhotos: false);
    final photo = template.blocks.firstWhere((block) => block.id == 'photo');
    expect(template.assetIds, isEmpty);
    expect(photo.content, {'fit': 'cover'});
    expect(_capture(keepPhotos: true).assetIds, {'edited', 'original'});
  });

  test('a template file round-trips into an empty store and makes a '
      'project with the right titles for every month', () async {
    final sourceAssets = _Assets()
      ..put('original', 'stupa.jpg', [1, 2, 3])
      ..put('edited', 'stupa (edited).jpg', [4, 5]);
    final artifact = await CalendarStudioTemplateBundle.export(
      _capture(keepPhotos: true),
      assets: sourceAssets,
      fileName: 'gold-wall',
    );
    expect(artifact.name, 'gold-wall.mmctemplate');
    final names = ZipDecoder()
        .decodeBytes(artifact.bytes)
        .files
        .map((file) => file.name)
        .toSet();
    expect(
      names,
      containsAll(['manifest.json', 'template.json', 'preview.png']),
    );

    final file = await CalendarStudioTemplateBundle.read(
      Uint8List.fromList(artifact.bytes),
    );
    expect(file.template.name, 'Gold wall');
    expect(file.template.author, 'Aye');
    expect(file.template.preview, [137, 80, 78, 71]);
    expect(file.missingAssetIds, isEmpty);

    final store = _Templates();
    final targetAssets = _Assets();
    final imported = await CalendarStudioTemplateBundle.import(
      file,
      templates: store,
      assets: targetAssets,
      now: DateTime.utc(2027, 4),
    );
    expect(store.values.values.single, imported);
    expect(imported.id, isNot(file.template.id));
    expect(imported.assetIds, everyElement(startsWith('stored-')));
    expect(targetAssets.bytes.length, 2);

    final gallery = CalendarStudioUserTemplates.toTemplate(imported);
    expect(gallery.id, 'user:${imported.id}');
    final project = gallery.create(
      id: 'new',
      source: const CalendarStudioSource(
        year: 2028,
        language: CalendarStudioLanguage.english,
      ),
      now: DateTime(2028),
    );
    expect(project.templateId, gallery.id);
    expect(project.pages, hasLength(12));
    for (final page in project.pages) {
      final month = CalendarStudioBindings.englishMonths[page.month - 1];
      expect(_textOf(page, 'month-mm'), month);
      expect(_textOf(page, 'month-en'), '$month 2028');
      expect(_textOf(page, 'year-mm'), '2028');
      expect(
        _textOf(page, 'era'),
        CalendarStudioBindings.eraLine(2028, page.month),
      );
    }
    final myanmar = gallery.create(
      id: 'mm',
      source: const CalendarStudioSource(
        year: 2028,
        month: 3,
        period: CalendarStudioPeriod.month,
        language: CalendarStudioLanguage.myanmar,
      ),
      now: DateTime(2028),
    );
    expect(_textOf(myanmar.pages.single, 'month-mm'), 'မတ်');
    expect(_textOf(myanmar.pages.single, 'year-mm'), '၂၀၂၈');
  });

  test('other files, damaged files and newer versions are rejected', () async {
    Future<Object?> readError(List<int> bytes) async {
      try {
        await CalendarStudioTemplateBundle.read(Uint8List.fromList(bytes));
      } on CalendarStudioTemplateFileException catch (error) {
        return error.message;
      }
      return null;
    }

    Uint8List zip(Map<String, Object> files) {
      final archive = Archive();
      for (final MapEntry(:key, :value) in files.entries) {
        final data = utf8.encode(jsonEncode(value));
        archive.addFile(ArchiveFile(key, data.length, data));
      }
      return Uint8List.fromList(ZipEncoder().encode(archive));
    }

    final template = CalendarStudioTemplateBundle.encode(
      _capture(keepPhotos: false),
    );
    expect(
      await readError([1, 2, 3]),
      contains("isn't a Calendar Studio template"),
    );
    expect(
      await readError(
        zip({
          'manifest.json': {
            'format': 'mmcalendar.studio.project',
            'version': 1,
          },
          'project.json': {},
        }),
      ),
      contains("isn't a Calendar Studio template"),
    );
    expect(
      await readError(
        zip({
          'manifest.json': {
            'format': CalendarStudioTemplateBundle.format,
            'version': 2,
          },
          'template.json': template,
        }),
      ),
      contains('newer version'),
    );
    expect(
      await readError(
        zip({
          'manifest.json': {
            'format': CalendarStudioTemplateBundle.format,
            'version': 1,
          },
          'template.json': {...template, 'formatVersion': 9},
        }),
      ),
      contains('newer version'),
    );
    expect(
      await readError(
        zip({
          'manifest.json': {
            'format': CalendarStudioTemplateBundle.format,
            'version': 1,
          },
          'template.json': {...template, 'blocks': 'nope'},
        }),
      ),
      contains('damaged'),
    );
  });
}

class _Assets implements CalendarStudioAssetStore {
  final bytes = <String, List<int>>{};
  final names = <String, String>{};
  var _next = 0;

  void put(String id, String name, List<int> data) {
    bytes[id] = data;
    names[id] = name;
  }

  @override
  Future<CalendarStudioAsset> importAsset(
    CalendarStudioAssetInput input,
  ) async {
    final id = 'stored-${_next++}';
    put(id, input.name, input.bytes);
    return CalendarStudioAsset(
      id: id,
      name: input.name,
      width: input.width,
      height: input.height,
    );
  }

  @override
  Future<List<int>?> loadBytes(String assetId) async => bytes[assetId];

  @override
  Future<CalendarStudioAsset?> load(String assetId) async =>
      names.containsKey(assetId)
      ? CalendarStudioAsset(
          id: assetId,
          name: names[assetId]!,
          width: 10,
          height: 10,
        )
      : null;

  @override
  Future<void> deleteUnusedAssets(Set<String> usedAssetIds) async {}
}

class _Templates implements CalendarStudioTemplateStore {
  final values = <String, CalendarStudioUserTemplate>{};
  @override
  Future<void> delete(String id) async => values.remove(id);
  @override
  Future<List<CalendarStudioUserTemplate>> list() async =>
      values.values.toList();
  @override
  Future<void> save(CalendarStudioUserTemplate template) async =>
      values[template.id] = template;
}
