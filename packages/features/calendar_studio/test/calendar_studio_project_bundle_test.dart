import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

CalendarStudioProject _projectWithImages() {
  final template = CalendarStudioTemplates.byId('plain').create(
    id: 'bundle-source',
    source: const CalendarStudioSource(
      year: 2027,
      period: CalendarStudioPeriod.month,
    ),
    now: DateTime(2027),
  );
  final page = template.pages.first;
  return template.copyWith(
    name: 'Temple days',
    pages: [
      page.copyWith(
        blocks: [
          ...page.blocks,
          CalendarStudioBlock(
            id: 'photo',
            type: CalendarStudioBlockType.image,
            name: 'Photo',
            bounds: const StudioRect(left: .1, top: .1, width: .3, height: .2),
            content: const {
              'assetId': 'edited',
              'originalAssetId': 'original',
              'editBaseAssetId': 'original',
              'editorState': '{"x":1}',
              'assetName': 'stupa.jpg',
            },
          ),
          CalendarStudioBlock(
            id: 'logo',
            type: CalendarStudioBlockType.logo,
            name: 'Logo',
            bounds: const StudioRect(left: .6, top: .1, width: .2, height: .1),
            content: const {'assetId': 'gone'},
          ),
        ],
      ),
    ],
  );
}

void main() {
  test('a project file round-trips with its images and new ids', () async {
    final sourceAssets = _Assets()
      ..put('original', 'stupa.jpg', [1, 2, 3])
      ..put('edited', 'stupa (edited).jpg', [4, 5]);
    final project = _projectWithImages();

    final artifact = await CalendarStudioProjectBundle.export(
      project,
      assets: sourceAssets,
      fileName: 'temple-days',
      now: DateTime.utc(2027, 3, 1),
    );
    expect(artifact.name, 'temple-days.mmcstudio');
    expect(artifact.mimeType, 'application/zip');

    final file = await CalendarStudioProjectBundle.read(
      Uint8List.fromList(artifact.bytes),
    );
    expect(file.project.name, 'Temple days');
    expect(file.assets.keys, unorderedEquals(['original', 'edited']));
    expect(file.missingAssetIds, {'gone'});
    expect(file.assets['edited']!.name, 'stupa (edited).jpg');

    final store = _Projects();
    final targetAssets = _Assets();
    final imported = await CalendarStudioProjectBundle.import(
      file,
      projects: store,
      assets: targetAssets,
      now: DateTime(2027, 3, 2),
    );
    expect(imported.id, isNot(project.id));
    expect(imported.name, 'Temple days (imported)');
    expect(store.values[imported.id], imported);
    final photo = imported.pages.first.blocks.firstWhere(
      (b) => b.id == 'photo',
    );
    final newEdited = photo.content['assetId']! as String;
    final newOriginal = photo.content['originalAssetId']! as String;
    expect(newEdited, isNot('edited'));
    expect(photo.content['editBaseAssetId'], newOriginal);
    expect(photo.content['editorState'], '{"x":1}');
    expect(targetAssets.bytes[newEdited], [4, 5]);
    expect(targetAssets.bytes[newOriginal], [1, 2, 3]);
    final logo = imported.pages.first.blocks.firstWhere((b) => b.id == 'logo');
    expect(logo.content.containsKey('assetId'), isFalse);
  });

  group('rejects', () {
    Future<String> messageFor(Uint8List bytes) async {
      try {
        await CalendarStudioProjectBundle.read(bytes);
        return 'accepted';
      } on CalendarStudioProjectFileException catch (error) {
        return error.message;
      }
    }

    Uint8List zip(Map<String, List<int>> files) {
      final archive = Archive();
      files.forEach((name, data) {
        archive.addFile(ArchiveFile(name, data.length, data));
      });
      return Uint8List.fromList(ZipEncoder().encode(archive));
    }

    List<int> json(Object value) => utf8.encode(jsonEncode(value));
    final projectJson = json(
      CalendarStudioDocumentCodec.encode(_projectWithImages()),
    );

    test('files that are not zips', () async {
      expect(
        await messageFor(Uint8List.fromList('hello'.codeUnits)),
        contains("isn't a Calendar Studio project file"),
      );
    });

    test('zips without a Studio manifest', () async {
      expect(
        await messageFor(zip({'project.json': projectJson})),
        contains("isn't a Calendar Studio project file"),
      );
      expect(
        await messageFor(
          zip({
            'manifest.json': json({'format': 'other', 'version': 1}),
            'project.json': projectJson,
          }),
        ),
        contains('damaged'),
      );
    });

    test('files from a newer app version', () async {
      expect(
        await messageFor(
          zip({
            'manifest.json': json({
              'format': CalendarStudioProjectBundle.format,
              'version': 99,
            }),
            'project.json': projectJson,
          }),
        ),
        contains('newer version'),
      );
    });

    test('unsafe paths are never read', () async {
      final file = await CalendarStudioProjectBundle.read(
        zip({
          'manifest.json': json({
            'format': CalendarStudioProjectBundle.format,
            'version': 1,
            'assets': [
              {'id': 'original', 'file': '../escape.jpg', 'name': 'x.jpg'},
            ],
          }),
          'project.json': projectJson,
          '../escape.jpg': [9, 9],
        }),
      );
      expect(file.assets, isEmpty);
    });
  });

  testWidgets('dashboard import reviews, saves and lists the project', (
    tester,
  ) async {
    final project = _projectWithImages();
    final bytes = (await tester.runAsync(() async {
      final artifact = await CalendarStudioProjectBundle.export(
        project,
        assets: _Assets()
          ..put(
            'original',
            'stupa.png',
            img.encodePng(img.Image(width: 8, height: 4)),
          )
          ..put(
            'edited',
            'stupa.png',
            img.encodePng(img.Image(width: 8, height: 4)),
          ),
        fileName: 'temple',
      );
      return Uint8List.fromList(artifact.bytes);
    }))!;
    final store = _Projects();
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarStudioWorkspace(
          configuration: CalendarStudioConfiguration(
            projects: store,
            assets: _Assets(),
            pickProjectFile: () async => bytes,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Import a project file'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Import project'));
      await tester.pump();
      for (
        var i = 0;
        i < 100 && find.text('Import project').evaluate().length < 2;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('Saved as'), findsOneWidget);
    expect(find.text('Temple days (imported)'), findsOneWidget);
    expect(find.textContaining("image isn't in this file"), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(
        find.byKey(const ValueKey('calendar-studio-import-confirm')),
      );
      for (var i = 0; i < 100 && store.values.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(store.values.values.single.name, 'Temple days (imported)');
    expect(find.text('Imported "Temple days (imported)".'), findsOneWidget);
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

class _Projects implements CalendarStudioProjectStore {
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
