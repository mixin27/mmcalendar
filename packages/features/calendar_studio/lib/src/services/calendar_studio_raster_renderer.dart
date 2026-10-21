import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../widgets/calendar_studio_scene.dart';
import 'calendar_studio_contracts.dart';

/// Renders the exact Flutter scene used by preview, preserving Skia's Myanmar
/// OpenType shaping in every exported format.
abstract interface class CalendarStudioPageRasterizer {
  Future<Uint8List> renderPage(
    CalendarStudioProject project,
    CalendarStudioPage page, {
    required int width,
    required int height,
  });
}

/// A page built and laid out offscreen, as export sees it.
class CalendarStudioLaidOutPage {
  const CalendarStudioLaidOutPage({
    required this.boundary,
    required this.logicalSize,
    required this.pixelRatio,
    required this.images,
  });

  /// The page's root; its size is [logicalSize].
  final RenderRepaintBoundary boundary;
  final Size logicalSize;
  final double pixelRatio;

  /// Each placed image as the scene paints it, with its original bytes.
  final List<(ui.Image, Uint8List)> images;
}

class CalendarStudioRasterRenderer implements CalendarStudioPageRasterizer {
  const CalendarStudioRasterRenderer({this.dataProvider, this.assetStore});

  final CalendarStudioDataProvider? dataProvider;
  final CalendarStudioAssetStore? assetStore;

  @override
  Future<Uint8List> renderPage(
    CalendarStudioProject project,
    CalendarStudioPage page, {
    required int width,
    required int height,
  }) => layOutPage(
    project,
    page,
    width: width,
    height: height,
    // The web engine keeps images the browser decodes on the GPU, and
    // `toImage` draws them as nothing, so exported pages lost their photos.
    // Images made from pixels draw everywhere.
    imagesFromPixels: kIsWeb,
    use: (laidOut) async {
      final image = _exactly(
        await laidOut.boundary.toImage(pixelRatio: laidOut.pixelRatio),
        width,
        height,
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('Could not encode calendar page');
      return data.buffer.asUint8List();
    },
  );

  /// Builds [page] offscreen at the shape of [width] × [height] pixels, lays
  /// it out with every image decoded, and hands it to [use].
  Future<T> layOutPage<T>(
    CalendarStudioProject project,
    CalendarStudioPage page, {
    required int width,
    required int height,
    required Future<T> Function(CalendarStudioLaidOutPage page) use,
    bool imagesFromPixels = false,
  }) async {
    final source = project.source.copyWith(year: page.year, month: page.month);
    final calendarMonths = page.blocks
        .where((block) => block.type == CalendarStudioBlockType.calendarGrid)
        .map((block) => block.content['month'] as int? ?? page.month)
        .toSet();
    final daysByMonth = <int, List<CalendarStudioDayData>>{};
    if (dataProvider != null) {
      for (final month in calendarMonths) {
        daysByMonth[month] = await dataProvider!.daysFor(
          source.copyWith(month: month),
          month: month,
        );
      }
    }
    // Decoded before the scene is built, so every image is there on the
    // first frame; an `Image` widget loads asynchronously, and offscreen
    // pages were painted before it arrived.
    final images = <String, ui.Image>{};
    final originals = <(ui.Image, Uint8List)>[];
    for (final block in page.blocks) {
      final assetId = block.content['assetId'] as String?;
      if (assetId == null || images.containsKey(assetId)) continue;
      final bytes = await assetStore?.loadBytes(assetId);
      if (bytes == null || bytes.isEmpty) continue;
      final original = Uint8List.fromList(bytes);
      try {
        final image = await _decode(original, fromPixels: imagesFromPixels);
        images[assetId] = image;
        originals.add((image, original));
      } catch (_) {
        // Damaged bytes draw the empty-image placeholder, as in the editor.
      }
    }

    final logicalSize = Size(595, 595 * height / width);
    final pixelRatio = width / logicalSize.width;
    // The page keeps its own shape: an output of another shape gets the
    // page centred in it, with the page colour around it, rather than a
    // stretched page with oval circles and squashed text.
    // Shapes within 1% count as the same, so rounding (A4's 595 × 842
    // design size, pixel sizes) never adds a hairline border.
    final pageRatio = page.canvas.aspectRatio;
    final sameShape =
        (pageRatio - logicalSize.aspectRatio).abs() / pageRatio < .01;
    final pageSize = sameShape
        ? logicalSize
        : pageRatio >= logicalSize.aspectRatio
        ? Size(logicalSize.width, logicalSize.width / pageRatio)
        : Size(logicalSize.height * pageRatio, logicalSize.height);
    final boundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(logicalSize),
        physicalConstraints: BoxConstraints.tight(
          Size(width * 1.0, height * 1.0),
        ),
        devicePixelRatio: pixelRatio,
      ),
      child: RenderPositionedBox(alignment: Alignment.center, child: boundary),
    );
    final pipelineOwner = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(size: logicalSize, devicePixelRatio: 1),
          child: Material(
            type: MaterialType.transparency,
            child: ColoredBox(
              color: Color(page.canvas.backgroundColor),
              child: SizedBox.fromSize(
                size: logicalSize,
                child: Center(
                  child: SizedBox.fromSize(
                    size: pageSize,
                    child: CalendarStudioScene(
                      page: page,
                      source: project.source,
                      resolvedDaysByMonth: daysByMonth,
                      resolvedImages: images,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(root);
    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();

    try {
      return await use(
        CalendarStudioLaidOutPage(
          boundary: boundary,
          logicalSize: logicalSize,
          pixelRatio: pixelRatio,
          images: originals,
        ),
      );
    } finally {
      buildOwner.finalizeTree();
      for (final image in images.values) {
        image.dispose();
      }
    }
  }

  /// Decodes [bytes]; with [fromPixels] the image is rebuilt from its
  /// pixels.
  static Future<ui.Image> _decode(
    Uint8List bytes, {
    required bool fromPixels,
  }) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final image = frame.image;
    if (!fromPixels) return image;
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    final height = image.height;
    image.dispose();
    if (pixels == null) throw StateError('Could not read an image');
    final rebuilt = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(pixels.offsetInBytes, pixels.lengthInBytes),
      width,
      height,
      ui.PixelFormat.rgba8888,
      rebuilt.complete,
    );
    return rebuilt.future;
  }

  /// [image] at exactly [width] × [height]: the ratio from design units to
  /// pixels is rarely exact, and rounding can add a pixel.
  static ui.Image _exactly(ui.Image image, int width, int height) {
    if (image.width == width && image.height == height) return image;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width * 1.0, image.height * 1.0),
      Rect.fromLTWH(0, 0, width * 1.0, height * 1.0),
      Paint()..filterQuality = FilterQuality.high,
    );
    image.dispose();
    final picture = recorder.endRecording();
    final exact = picture.toImageSync(width, height);
    picture.dispose();
    return exact;
  }
}
