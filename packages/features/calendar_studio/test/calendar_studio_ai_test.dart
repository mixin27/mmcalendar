import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _jpg(int width, int height) => img.encodeJpg(
  img.Image(width: width, height: height)..clear(img.ColorRgb8(0, 90, 70)),
);

Uint8List _png(int width, int height) => img.encodePng(
  img.Image(width: width, height: height, numChannels: 4)
    ..clear(img.ColorRgba8(0, 0, 0, 0)),
);

CalendarStudioProject _project() {
  final template = CalendarStudioTemplates.byId('plain').create(
    id: 'ai-project',
    source: const CalendarStudioSource(
      year: 2027,
      period: CalendarStudioPeriod.month,
    ),
    now: DateTime(2027),
  );
  final page = template.pages.first;
  return template.copyWith(
    pages: [
      page.copyWith(
        blocks: [
          ...page.blocks,
          CalendarStudioBlock(
            id: 'photo',
            type: CalendarStudioBlockType.image,
            name: 'Header photo',
            bounds: const StudioRect(left: .1, top: .1, width: .3, height: .1),
            zIndex: page.blocks.length,
            content: const {
              'assetId': 'original',
              'assetName': 'logo.jpg',
              'pixelWidth': 80,
              'pixelHeight': 40,
            },
          ),
          CalendarStudioBlock(
            id: 'headline',
            type: CalendarStudioBlockType.text,
            name: 'Headline',
            bounds: const StudioRect(left: .1, top: .3, width: .6, height: .1),
            zIndex: page.blocks.length + 1,
            style: const {'fontSize': 36},
            content: const {'text': 'January'},
          ),
        ],
      ),
    ],
  );
}

Future<void> _openEditor(
  WidgetTester tester,
  CalendarStudioConfiguration configuration,
) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(home: CalendarStudioWorkspace(configuration: configuration)),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Resume'));
  await tester.pumpAndSettle();
}

CalendarStudioBlock _block(WidgetTester tester, String id) => tester
    .widget<CalendarStudioScene>(find.byType(CalendarStudioScene))
    .page
    .blocks
    .firstWhere((block) => block.id == id);

void main() {
  testWidgets('AI actions stay hidden when providers are missing or off', (
    tester,
  ) async {
    final assets = _MemoryAssets()..put('original', 'logo.jpg', _jpg(80, 40));
    await _openEditor(
      tester,
      CalendarStudioConfiguration(
        projects: _MemoryStore()..values['ai-project'] = _project(),
        assets: assets,
        ai: CalendarStudioAiConfiguration(
          backgroundRemover: _FakeRemover(available: false),
          textSuggester: _FakeSuggester(throwOnAvailability: true),
        ),
      ),
    );
    await tester.tap(find.text('Header photo').first);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('calendar-studio-remove-background')),
      findsNothing,
    );
    await tester.tap(find.text('Headline').first);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('calendar-studio-suggest-text')),
      findsNothing,
    );
  });

  testWidgets('background removal swaps in a cut-out and can be reverted', (
    tester,
  ) async {
    final assets = _MemoryAssets()..put('original', 'logo.jpg', _jpg(80, 40));
    final remover = _FakeRemover(available: true, output: _png(80, 40));
    await _openEditor(
      tester,
      CalendarStudioConfiguration(
        projects: _MemoryStore()..values['ai-project'] = _project(),
        assets: assets,
        ai: CalendarStudioAiConfiguration(backgroundRemover: remover),
      ),
    );
    await tester.tap(find.text('Header photo').first);
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(
        find.byKey(const ValueKey('calendar-studio-remove-background')),
      );
      await tester.pump();
      for (
        var i = 0;
        i < 50 && _block(tester, 'photo').content['assetId'] == 'original';
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();

    expect(remover.inputs.single, assets.bytes['original']);
    final content = _block(tester, 'photo').content;
    expect(content['originalAssetId'], 'original');
    expect(content['assetId'], isNot('original'));
    expect(assets.assets[content['assetId']]!.name, 'logo (cutout).png');
    expect(find.text('Removing background…'), findsNothing);

    await tester.tap(find.text('Revert to original'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(_block(tester, 'photo').content['assetId'], 'original');
  });

  testWidgets('editing after a cut-out starts from the cut-out', (
    tester,
  ) async {
    final assets = _MemoryAssets()..put('original', 'logo.jpg', _jpg(80, 40));
    final cutout = _png(80, 40);
    final editor = _FakeEditor(_png(40, 20));
    await _openEditor(
      tester,
      CalendarStudioConfiguration(
        projects: _MemoryStore()..values['ai-project'] = _project(),
        assets: assets,
        imageEditor: editor,
        ai: CalendarStudioAiConfiguration(
          backgroundRemover: _FakeRemover(available: true, output: cutout),
        ),
      ),
    );
    await tester.tap(find.text('Header photo').first);
    await tester.pumpAndSettle();

    Future<void> tapAndWait(Key key, bool Function() done) async {
      await tester.runAsync(() async {
        await tester.tap(find.byKey(key));
        await tester.pump();
        for (var i = 0; i < 50 && !done(); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();
    }

    await tapAndWait(
      const ValueKey('calendar-studio-remove-background'),
      () => _block(tester, 'photo').content['assetId'] != 'original',
    );
    final cutoutId = _block(tester, 'photo').content['assetId'];
    await tapAndWait(
      const ValueKey('calendar-studio-edit-image'),
      () => _block(tester, 'photo').content['editorState'] != null,
    );

    expect(editor.originals.single, assets.bytes[cutoutId]);
    final content = _block(tester, 'photo').content;
    expect(content['editBaseAssetId'], cutoutId);
    expect(content['originalAssetId'], 'original');
  });

  testWidgets('no subject found keeps the image and explains why', (
    tester,
  ) async {
    final assets = _MemoryAssets()..put('original', 'logo.jpg', _jpg(80, 40));
    await _openEditor(
      tester,
      CalendarStudioConfiguration(
        projects: _MemoryStore()..values['ai-project'] = _project(),
        assets: assets,
        ai: CalendarStudioAiConfiguration(
          backgroundRemover: _FakeRemover(available: true),
        ),
      ),
    );
    await tester.tap(find.text('Header photo').first);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(
        find.byKey(const ValueKey('calendar-studio-remove-background')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('No clear subject was found in this image.'), findsOne);
    expect(_block(tester, 'photo').content['assetId'], 'original');
  });

  testWidgets('text suggestions use calendar context and apply on tap', (
    tester,
  ) async {
    final suggester = _FakeSuggester();
    await _openEditor(
      tester,
      CalendarStudioConfiguration(
        projects: _MemoryStore()..values['ai-project'] = _project(),
        calendarData: _HolidayData(),
        ai: CalendarStudioAiConfiguration(textSuggester: suggester),
      ),
    );
    await tester.tap(find.text('Headline').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('calendar-studio-suggest-text')),
    );
    await tester.pumpAndSettle();

    final request = suggester.requests.single;
    expect(request.kind, CalendarStudioTextKind.title);
    expect(request.year, 2027);
    expect(request.month, 1);
    expect(request.currentText, 'January');
    expect(request.holidays, ['New Year']);
    expect(request.sabbathDays, [8]);

    await tester.tap(find.text('Quote'));
    await tester.pumpAndSettle();
    expect(suggester.requests.last.kind, CalendarStudioTextKind.quote);

    await tester.tap(find.text('quote 2'));
    await tester.pumpAndSettle();
    expect(_block(tester, 'headline').content['text'], 'quote 2');
    expect(find.widgetWithText(TextFormField, 'quote 2'), findsOneWidget);
  });
}

class _FakeEditor implements CalendarStudioImageEditor {
  _FakeEditor(this.output);
  final Uint8List output;
  final originals = <Uint8List>[];

  @override
  Future<CalendarStudioEditedImage?> edit(
    BuildContext context, {
    required Uint8List original,
    String? editorState,
    required int maxDimension,
  }) async {
    originals.add(original);
    return CalendarStudioEditedImage(bytes: output, editorState: 'state');
  }
}

class _FakeRemover implements CalendarStudioBackgroundRemover {
  _FakeRemover({required this.available, this.output});
  final bool available;
  final Uint8List? output;
  final inputs = <Uint8List>[];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<Uint8List?> removeBackground(Uint8List image) async {
    inputs.add(image);
    return output;
  }
}

class _FakeSuggester implements CalendarStudioTextSuggester {
  _FakeSuggester({this.throwOnAvailability = false});
  final bool throwOnAvailability;
  final requests = <CalendarStudioTextSuggestionRequest>[];

  @override
  Future<bool> isAvailable() async {
    if (throwOnAvailability) throw StateError('Firebase not ready');
    return true;
  }

  @override
  Future<List<String>> suggest(
    CalendarStudioTextSuggestionRequest request,
  ) async {
    requests.add(request);
    return [for (var i = 1; i <= 3; i++) '${request.kind.name} $i'];
  }
}

class _HolidayData implements CalendarStudioDataProvider {
  @override
  Future<List<CalendarStudioDayData>> daysFor(
    CalendarStudioSource source, {
    required int month,
  }) async => [
    for (
      var day = 1;
      day <= DateUtils.getDaysInMonth(source.year, month);
      day++
    )
      CalendarStudioDayData(
        date: DateTime(source.year, month, day),
        gregorianLabel: '$day',
        holidayLabel: day == 1 ? 'New Year' : null,
        isSabbath: day == 8,
      ),
  ];
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
    final id = 'asset-${assets.length}';
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
