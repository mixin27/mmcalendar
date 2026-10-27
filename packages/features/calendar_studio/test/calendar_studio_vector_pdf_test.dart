import 'dart:io';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// The vector PDF keeps text as text, shapes as paths and photos as their
/// original files. Set VECTOR_PDF_OUT to a path to keep the PDF for review.
void main() {
  setUpAll(() async {
    // Real metrics, so text lands where the real fonts put it.
    for (final font in CalendarStudioFontCatalog.fonts) {
      final folder = font.family.toLowerCase().replaceAll(' ', '');
      final loader = FontLoader(
        CalendarStudioFontCatalog.resolve(font.family)!,
      );
      for (final file in Directory('assets/fonts/$folder').listSync()) {
        if (file.path.endsWith('.ttf')) {
          final bytes = File(file.path).readAsBytesSync();
          loader.addFont(Future.value(ByteData.sublistView(bytes)));
        }
      }
      await loader.load();
    }
  });

  // Embedding needs the export fonts, built by tool/build_export_fonts.py
  // into the web app (gitignored), so CI doesn't have them.
  final exportFonts = Directory(
    '../../../apps/myanmar_calendar/web/export-fonts',
  );

  testWidgets(
    'Hearth & Home exports as editable vectors',
    skip: !exportFonts.existsSync(),
    (tester) async {
      final photo = Uint8List.fromList(
        img.encodeJpg(
          img.Image(width: 300, height: 200)
            ..clear(img.ColorRgb8(40, 140, 120)),
        ),
      );
      var project = CalendarStudioTemplates.byId('family').create(
        id: 'vector',
        source: const CalendarStudioSource(
          year: 2027,
          month: 1,
          period: CalendarStudioPeriod.month,
        ),
        now: DateTime(2027),
      );
      final page = project.pages.first;
      project = project.copyWith(
        pages: [
          page.copyWith(
            blocks: [
              for (final block in page.blocks)
                block.type == CalendarStudioBlockType.image
                    ? block.copyWith(
                        content: {...block.content, 'assetId': 'photo'},
                      )
                    : block,
            ],
          ),
        ],
      );
      final renderer = CalendarStudioVectorPdfRenderer(
        layout: CalendarStudioRasterRenderer(
          dataProvider: const MyanmarCalendarStudioDataProvider(),
          assetStore: _OnePhoto(photo),
        ),
        fonts: CalendarStudioExportFonts(
          download: (name) async {
            final file = File('${exportFonts.path}/$name');
            return file.existsSync() ? file.readAsBytesSync() : null;
          },
        ),
      );

      final (bytes, report) = (await tester.runAsync(
        () => renderer.render(
          project,
          [project.pages.first],
          CalendarStudioExportPreset.pagePdf.copyWith(
            format: CalendarStudioExportFormat.pdfEditable,
          ),
          compress: false,
        ),
      ))!;
      if (Platform.environment['VECTOR_PDF_OUT'] case final out?) {
        File(out).writeAsBytesSync(bytes);
      }

      final pdf = String.fromCharCodes(bytes);
      expect(pdf, startsWith('%PDF'));
      // Fonts embedded as TrueType and real text operators, not a page image.
      expect(pdf, contains('/FontFile2'));
      expect(pdf, contains('Tj'));
      // The photo is the original JPEG.
      expect(pdf, contains('/DCTDecode'));
      // The display font is bundled with Studio, so its text stays text.
      expect(pdf, contains('/Fraunces-'));
    },
  );
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
