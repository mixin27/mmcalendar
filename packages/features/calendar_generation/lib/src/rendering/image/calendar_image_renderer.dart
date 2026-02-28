import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_image_quality.dart';
import '../../domain/entities/calendar_page_model.dart';
import '../../presentation/widgets/calendar_generation_preview_page.dart';
import '../export/background_image_loader.dart';

class CalendarImageRenderer {
  CalendarImageRenderer(this._backgroundImageLoader);

  final BackgroundImageLoader _backgroundImageLoader;

  Future<List<Uint8List>> renderPages({
    required CalendarGenerationRequest request,
    required List<CalendarPageModel> pages,
    int width = 1240,
    int height = 1754,
  }) async {
    final bytesByBackgroundUrl = <String, Uint8List?>{};
    final result = <Uint8List>[];

    for (final page in pages) {
      final backgroundUrl = request.theme.backgroundImageUrlForMonth(
        page.month,
      );
      Uint8List? backgroundBytes;
      if (backgroundUrl != null && backgroundUrl.trim().isNotEmpty) {
        if (bytesByBackgroundUrl.containsKey(backgroundUrl)) {
          backgroundBytes = bytesByBackgroundUrl[backgroundUrl];
        } else {
          backgroundBytes = await _backgroundImageLoader.loadBytes(
            backgroundUrl,
          );
          bytesByBackgroundUrl[backgroundUrl] = backgroundBytes;
        }
      }

      final renderedImage = await _renderWidgetPage(
        request: request,
        page: page,
        width: width,
        height: height,
        backgroundBytes: backgroundBytes,
      );
      final encoded = await _encodeRenderedImage(
        renderedImage,
        imageQuality: request.imageQuality,
      );
      renderedImage.dispose();
      result.add(encoded);
    }

    return result;
  }

  Future<ui.Image> _renderWidgetPage({
    required CalendarGenerationRequest request,
    required CalendarPageModel page,
    required int width,
    required int height,
    Uint8List? backgroundBytes,
  }) async {
    final exportPixelRatio = _exportPixelRatioFor(request.imageQuality);
    final logicalSize = Size(
      width / exportPixelRatio,
      height / exportPixelRatio,
    );

    final repaintBoundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(logicalSize),
        physicalConstraints: BoxConstraints.tight(
          Size(width.toDouble(), height.toDouble()),
        ),
        devicePixelRatio: exportPixelRatio,
      ),
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
    );

    final pipelineOwner = PipelineOwner();
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final buildOwner = BuildOwner(focusManager: FocusManager());
    final backgroundProvider = backgroundBytes == null
        ? null
        : MemoryImage(backgroundBytes);

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: _buildExportWidget(
        request: request,
        page: page,
        logicalSize: logicalSize,
        backgroundProvider: backgroundProvider,
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();

    if (backgroundProvider != null) {
      await precacheImage(backgroundProvider, rootElement);
      buildOwner.buildScope(rootElement);
      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
    }

    final image = await repaintBoundary.toImage(pixelRatio: exportPixelRatio);
    buildOwner.finalizeTree();
    return image;
  }

  Widget _buildExportWidget({
    required CalendarGenerationRequest request,
    required CalendarPageModel page,
    required Size logicalSize,
    ImageProvider<Object>? backgroundProvider,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: logicalSize, devicePixelRatio: 1),
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: logicalSize.width,
            height: logicalSize.height,
            child: CalendarGenerationPreviewPage(
              model: page,
              request: request,
              margin: EdgeInsets.zero,
              elevation: 0,
              contentPadding: const EdgeInsets.all(12),
              compact: false,
              useCardChrome: false,
              backgroundImageProvider: backgroundProvider,
            ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _encodeRenderedImage(
    ui.Image image, {
    required CalendarImageQuality imageQuality,
  }) async {
    final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (pngData == null) {
      throw StateError('Failed to encode rendered calendar image');
    }
    final pngBytes = pngData.buffer.asUint8List();
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) {
      return pngBytes;
    }

    final baseQuality = _jpegQualityFor(imageQuality);
    final targetBytes = _targetBytesFor(imageQuality);
    var working = decoded;
    var best = img.encodeJpg(working, quality: baseQuality);

    if (best.length <= targetBytes) {
      return Uint8List.fromList(best);
    }

    for (var quality = baseQuality - 6; quality >= 58; quality -= 6) {
      final compressed = img.encodeJpg(working, quality: quality);
      best = compressed;
      if (compressed.length <= targetBytes) {
        return Uint8List.fromList(compressed);
      }
    }

    const downscaleFactors = <double>[0.92, 0.85];
    for (final factor in downscaleFactors) {
      final resizedWidth = (decoded.width * factor).round();
      final resizedHeight = (decoded.height * factor).round();
      if (resizedWidth < 900 || resizedHeight < 1200) {
        continue;
      }
      working = img.copyResize(
        decoded,
        width: resizedWidth,
        height: resizedHeight,
        interpolation: img.Interpolation.average,
      );
      final compressed = img.encodeJpg(
        working,
        quality: (baseQuality - 8).clamp(58, 90).toInt(),
      );
      best = compressed;
      if (compressed.length <= targetBytes) {
        return Uint8List.fromList(compressed);
      }
    }

    return Uint8List.fromList(best);
  }

  double _exportPixelRatioFor(CalendarImageQuality quality) {
    return quality == CalendarImageQuality.print ? 3.0 : 2.0;
  }

  int _jpegQualityFor(CalendarImageQuality quality) {
    return quality == CalendarImageQuality.print ? 88 : 78;
  }

  int _targetBytesFor(CalendarImageQuality quality) {
    return quality == CalendarImageQuality.print ? 2600000 : 900000;
  }
}
