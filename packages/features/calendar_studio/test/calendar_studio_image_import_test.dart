import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _png(int width, int height) => img.encodePng(
  img.Image(width: width, height: height, numChannels: 4)
    ..clear(img.ColorRgba8(10, 20, 30, 128)),
);

Uint8List _jpg(int width, int height) => img.encodeJpg(
  img.Image(width: width, height: height)..clear(img.ColorRgb8(200, 0, 0)),
);

void main() {
  testWidgets('small images keep their original bytes', (tester) async {
    final bytes = _jpg(320, 200);
    final prepared = (await tester.runAsync(
      () => CalendarStudioImageImport.prepare(
        CalendarStudioPickedImage(name: 'photo.jpg', bytes: bytes),
      ),
    ))!;
    expect(prepared.resized, isFalse);
    expect(identical(prepared.bytes, bytes), isTrue);
    expect((prepared.width, prepared.height), (320, 200));
  });

  testWidgets('oversized PNGs are downsized and stay PNG', (tester) async {
    final prepared = (await tester.runAsync(
      () => CalendarStudioImageImport.prepare(
        CalendarStudioPickedImage(name: 'logo.png', bytes: _png(800, 200)),
        maxDimension: 400,
      ),
    ))!;
    expect(prepared.resized, isTrue);
    expect((prepared.width, prepared.height), (400, 100));
    expect(prepared.name, 'logo.png');
    final decoded = img.decodePng(prepared.bytes)!;
    expect((decoded.width, decoded.height), (400, 100));
    expect(decoded.getPixel(0, 0).a, closeTo(128, 2));
  });

  testWidgets('oversized photos are re-encoded as JPEG', (tester) async {
    final prepared = (await tester.runAsync(
      () => CalendarStudioImageImport.prepare(
        CalendarStudioPickedImage(name: 'IMG_1.heic', bytes: _jpg(300, 600)),
        maxDimension: 150,
      ),
    ))!;
    expect((prepared.width, prepared.height), (75, 150));
    expect(prepared.name, 'IMG_1.jpg');
    expect(img.decodeJpg(prepared.bytes), isNotNull);
  });

  testWidgets('non-image files are rejected', (tester) async {
    Object? error;
    await tester.runAsync(() async {
      try {
        await CalendarStudioImageImport.prepare(
          CalendarStudioPickedImage(
            name: 'notes.txt',
            bytes: Uint8List.fromList('hello'.codeUnits),
          ),
        );
      } catch (e) {
        error = e;
      }
    });
    expect(error, isA<CalendarStudioUnsupportedImageException>());
  });

  testWidgets('adding an image offers host sources and adds one block', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(560, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final project = CalendarStudioTemplates.byId('plain').create(
      id: 'image-project',
      source: const CalendarStudioSource(
        year: 2027,
        period: CalendarStudioPeriod.month,
      ),
      now: DateTime(2027),
    );
    final picker = _FakePicker(_jpg(64, 32));
    final assets = _MemoryAssets();
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarStudioWorkspace(
          configuration: CalendarStudioConfiguration(
            projects: _MemoryStore()..values[project.id] = project,
            assets: assets,
            imagePicker: picker,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Images'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo from your gallery'));
    await tester.pumpAndSettle();

    expect(find.text('Choose image'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Camera'));
      await tester.pump();
      for (var i = 0; i < 20 && assets.imported.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();

    expect(picker.requested, CalendarStudioImageSource.camera);
    expect(assets.imported.single.width, 64);
    final scene = tester.widget<CalendarStudioScene>(
      find.byType(CalendarStudioScene),
    );
    final image = scene.page.blocks.singleWhere(
      (block) => block.type == CalendarStudioBlockType.image,
    );
    expect(image.content['assetId'], 'asset-1');
    expect(image.content['pixelHeight'], 32);
  });
}

class _FakePicker implements CalendarStudioImagePicker {
  _FakePicker(this.bytes);
  final Uint8List bytes;
  CalendarStudioImageSource? requested;

  @override
  List<CalendarStudioImageSource> get sources => const [
    CalendarStudioImageSource.gallery,
    CalendarStudioImageSource.camera,
    CalendarStudioImageSource.files,
  ];

  @override
  Future<CalendarStudioPickedImage?> pick(
    CalendarStudioImageSource source, {
    required int maxDimension,
  }) async {
    requested = source;
    return CalendarStudioPickedImage(name: 'shot.jpg', bytes: bytes);
  }
}

class _MemoryAssets implements CalendarStudioAssetStore {
  final imported = <CalendarStudioAssetInput>[];

  @override
  Future<CalendarStudioAsset> importAsset(
    CalendarStudioAssetInput input,
  ) async {
    imported.add(input);
    return CalendarStudioAsset(
      id: 'asset-${imported.length}',
      name: input.name,
      width: input.width,
      height: input.height,
    );
  }

  @override
  Future<List<int>?> loadBytes(String assetId) async => imported.last.bytes;
  @override
  Future<CalendarStudioAsset?> load(String assetId) async => null;
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
