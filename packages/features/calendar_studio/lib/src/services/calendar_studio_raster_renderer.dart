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
    final assets = <String, Uint8List>{};
    for (final block in page.blocks) {
      final assetId = block.content['assetId'] as String?;
      if (assetId == null || assets.containsKey(assetId)) continue;
      final bytes = await assetStore?.loadBytes(assetId);
      if (bytes != null && bytes.isNotEmpty) {
        assets[assetId] = Uint8List.fromList(bytes);
      }
    }
    if (kIsWeb) {
      for (final bytes in assets.values) {
        await _cacheAsPixels(bytes);
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
                      resolvedAssets: assets,
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
    for (final bytes in assets.values) {
      await precacheImage(MemoryImage(bytes), root);
    }
    buildOwner.buildScope(root);
    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();

    final image = _exactly(
      await boundary.toImage(pixelRatio: pixelRatio),
      width,
      height,
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    buildOwner.finalizeTree();
    if (kIsWeb) {
      for (final bytes in assets.values) {
        PaintingBinding.instance.imageCache.evict(MemoryImage(bytes));
      }
    }
    if (data == null) throw StateError('Could not encode calendar page');
    return data.buffer.asUint8List();
  }

  /// Caches [bytes] for the scene's `Image.memory` as an image built from
  /// pixels.
  ///
  /// The web engine keeps images the browser decodes on the GPU, and
  /// `toImage` draws them as nothing, so exported pages lost their photos.
  /// Images made from pixels draw everywhere.
  static Future<void> _cacheAsPixels(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final decoded = frame.image;
    final pixels = await decoded.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = decoded.width;
    final height = decoded.height;
    decoded.dispose();
    if (pixels == null) return;
    final image = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(pixels.offsetInBytes, pixels.lengthInBytes),
      width,
      height,
      ui.PixelFormat.rgba8888,
      image.complete,
    );
    final info = ImageInfo(image: await image.future);
    PaintingBinding.instance.imageCache.putIfAbsent(
      MemoryImage(bytes),
      () => OneFrameImageStreamCompleter(Future.value(info)),
    );
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
