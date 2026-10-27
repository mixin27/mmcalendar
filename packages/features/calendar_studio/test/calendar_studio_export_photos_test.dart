import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Exported pages must show the photos placed in them. Offscreen export
/// used to build the page before its photos had loaded, so PDF, PNG and
/// JPEG pages came out with empty frames (2.3.0).
void main() {
  testWidgets('exported pages include their photos', (tester) async {
    const red = (196, 32, 40);
    final photo = Uint8List.fromList(
      img.encodeJpg(
        img.Image(width: 200, height: 120)
          ..clear(img.ColorRgb8(red.$1, red.$2, red.$3)),
        quality: 95,
      ),
    );
    final created = CalendarStudioTemplates.byId('family').create(
      id: 'photos',
      source: const CalendarStudioSource(
        year: 2027,
        month: 1,
        period: CalendarStudioPeriod.month,
      ),
      now: DateTime(2027),
    );
    final page = created.pages.first;
    final frame = page.blocks.firstWhere(
      (block) => block.type == CalendarStudioBlockType.image,
    );
    final project = created.copyWith(
      pages: [
        page.copyWith(
          blocks: [
            for (final block in page.blocks)
              block.id == frame.id
                  ? block.copyWith(content: {...block.content, 'assetId': 'a'})
                  : block,
          ],
        ),
      ],
    );

    const width = 600;
    const height = 848;
    final png = (await tester.runAsync(
      () => CalendarStudioRasterRenderer(
        assetStore: _OnePhoto(photo),
      ).renderPage(project, project.pages.first, width: width, height: height),
    ))!;

    final image = img.decodePng(png)!;
    final centre = frame.bounds;
    final pixel = image.getPixel(
      ((centre.left + centre.width / 2) * width).round(),
      ((centre.top + centre.height / 2) * height).round(),
    );
    expect(
      (pixel.r - red.$1).abs() +
          (pixel.g - red.$2).abs() +
          (pixel.b - red.$3).abs(),
      lessThan(40),
      reason: 'expected the photo, found $pixel in the frame',
    );
  });
}

class _OnePhoto implements CalendarStudioAssetStore {
  _OnePhoto(this.bytes);
  final Uint8List bytes;
  @override
  Future<List<int>?> loadBytes(String assetId) async => bytes;
  @override
  Future<CalendarStudioAsset?> load(String assetId) async => null;
  @override
  Future<CalendarStudioAsset> importAsset(CalendarStudioAssetInput input) =>
      throw UnimplementedError();
  @override
  Future<void> deleteUnusedAssets(Set<String> usedAssetIds) async {}
}
