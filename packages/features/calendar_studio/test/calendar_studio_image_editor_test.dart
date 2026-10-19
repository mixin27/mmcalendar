import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _jpg(int width, int height) => img.encodeJpg(
  img.Image(width: width, height: height)..clear(img.ColorRgb8(0, 90, 70)),
);

void main() {
  testWidgets('edit, re-edit and revert keep the original image', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final assets = _MemoryAssets()..put('original', 'photo.jpg', _jpg(80, 40));
    final template = CalendarStudioTemplates.byId('plain').create(
      id: 'edit-project',
      source: const CalendarStudioSource(
        year: 2027,
        period: CalendarStudioPeriod.month,
      ),
      now: DateTime(2027),
    );
    final page = template.pages.first;
    final project = template.copyWith(
      pages: [
        page.copyWith(
          blocks: [
            ...page.blocks,
            CalendarStudioBlock(
              id: 'photo',
              type: CalendarStudioBlockType.image,
              name: 'Header photo',
              bounds: const StudioRect(
                left: .1,
                top: .1,
                width: .3,
                height: .1,
              ),
              zIndex: page.blocks.length,
              content: const {
                'assetId': 'original',
                'assetName': 'photo.jpg',
                'pixelWidth': 80,
                'pixelHeight': 40,
              },
            ),
          ],
        ),
      ],
    );
    final editor = _FakeEditor(_jpg(60, 30));
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarStudioWorkspace(
          configuration: CalendarStudioConfiguration(
            projects: _MemoryStore()..values[project.id] = project,
            assets: assets,
            imageEditor: editor,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Header photo').first);
    await tester.pumpAndSettle();

    CalendarStudioBlock photo() => tester
        .widget<CalendarStudioScene>(find.byType(CalendarStudioScene))
        .page
        .blocks
        .firstWhere((block) => block.id == 'photo');

    Future<void> runEdit() async {
      await tester.runAsync(() async {
        await tester.tap(
          find.byKey(const ValueKey('calendar-studio-edit-image')),
        );
        await tester.pump();
        for (var i = 0; i < 50 && photo().content['editorState'] == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();
    }

    await runEdit();
    expect(editor.calls.single.state, isNull);
    expect(editor.calls.single.original, assets.bytes['original']);
    var content = photo().content;
    expect(content['originalAssetId'], 'original');
    expect(content['assetId'], isNot('original'));
    expect(content['assetName'], 'photo.jpg');
    expect(content['pixelWidth'], 60);
    expect(content['editorState'], 'state-1');
    expect(find.text('Revert to original'), findsOneWidget);

    // Re-editing starts from the original with the saved history.
    await runEdit();
    expect(editor.calls.last.original, assets.bytes['original']);
    expect(editor.calls.last.state, 'state-1');
    expect(photo().content['editorState'], 'state-2');

    await tester.tap(find.text('Revert to original'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    content = photo().content;
    expect(content['assetId'], 'original');
    expect(content['pixelWidth'], 80);
    expect(content.containsKey('originalAssetId'), isFalse);
    expect(content.containsKey('editorState'), isFalse);
  });

  testWidgets('Edit image is hidden without a host editor', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final project = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'no-editor',
      source: const CalendarStudioSource(
        year: 2027,
        period: CalendarStudioPeriod.month,
      ),
      now: DateTime(2027),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarStudioWorkspace(
          configuration: CalendarStudioConfiguration(
            projects: _MemoryStore()..values[project.id] = project,
            assets: _MemoryAssets(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('calendar-studio-edit-image')),
      findsNothing,
    );
  });
}

class _FakeEditor implements CalendarStudioImageEditor {
  _FakeEditor(this.output);
  final Uint8List output;
  final calls = <({Uint8List original, String? state})>[];

  @override
  Future<CalendarStudioEditedImage?> edit(
    BuildContext context, {
    required Uint8List original,
    String? editorState,
    required int maxDimension,
  }) async {
    calls.add((original: original, state: editorState));
    return CalendarStudioEditedImage(
      bytes: output,
      editorState: 'state-${calls.length}',
    );
  }
}

class _MemoryAssets implements CalendarStudioAssetStore {
  final bytes = <String, Uint8List>{};
  final assets = <String, CalendarStudioAsset>{};

  void put(String id, String name, Uint8List data) {
    bytes[id] = data;
    final decoded = img.decodeImage(data)!;
    assets[id] = CalendarStudioAsset(
      id: id,
      name: name,
      width: decoded.width,
      height: decoded.height,
    );
  }

  @override
  Future<CalendarStudioAsset> importAsset(
    CalendarStudioAssetInput input,
  ) async {
    final id = 'edited-${assets.length}';
    bytes[id] = Uint8List.fromList(input.bytes);
    return assets[id] = CalendarStudioAsset(
      id: id,
      name: input.name,
      width: input.width,
      height: input.height,
    );
  }

  @override
  Future<List<int>?> loadBytes(String assetId) async => bytes[assetId];
  @override
  Future<CalendarStudioAsset?> load(String assetId) async => assets[assetId];
  @override
  Future<void> deleteUnusedAssets(Set<String> usedAssetIds) async {}
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
