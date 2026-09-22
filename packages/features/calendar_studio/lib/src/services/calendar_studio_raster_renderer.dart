import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/calendar_studio_document.dart';
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
    final days = await dataProvider?.daysFor(source, month: page.month);
    final assets = <String, Uint8List>{};
    for (final block in page.blocks) {
      final assetId = block.content['assetId'] as String?;
      if (assetId == null || assets.containsKey(assetId)) continue;
      final bytes = await assetStore?.loadBytes(assetId);
      if (bytes != null && bytes.isNotEmpty) {
        assets[assetId] = Uint8List.fromList(bytes);
      }
    }

    final logicalSize = Size(595, 595 * height / width);
    final pixelRatio = width / logicalSize.width;
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
            child: SizedBox.fromSize(
              size: logicalSize,
              child: CalendarStudioScene(
                page: page,
                source: project.source,
                resolvedDays: days,
                resolvedAssets: assets,
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

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    buildOwner.finalizeTree();
    if (data == null) throw StateError('Could not encode calendar page');
    return data.buffer.asUint8List();
  }
}
