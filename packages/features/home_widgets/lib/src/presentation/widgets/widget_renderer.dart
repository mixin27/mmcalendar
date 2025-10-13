import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:home_widget/home_widget.dart';

import 'moon_phase_widget.dart';

/// Renders Flutter widgets to images for Android widget display
class WidgetRenderer {
  /// Render moon phase to image file
  static Future<String?> renderMoonPhase({
    required int moonPhase,
    required int fortnightDay,
    double size = 80,
    Color? moonColor,
    Color? shadowColor,
  }) async {
    try {
      // Create the widget
      final widget = MoonPhaseWidget(
        moonPhase: moonPhase,
        size: size,
        moonColor: moonColor,
        shadowColor: shadowColor,
        showGlow: true,
      );

      // Render to image
      final bytes = await _widgetToImage(widget, Size(size, size));

      if (bytes == null) return null;

      // Save to file and return path
      return await HomeWidget.renderFlutterWidget(
        widget,
        key: 'moon_phase_image',
        logicalSize: Size(size, size),
        pixelRatio: 3.0,
      );
    } catch (e) {
      debugPrint('❌ Error rendering moon phase: $e');
      return null;
    }
  }

  /// Convert widget to image bytes
  static Future<Uint8List?> _widgetToImage(Widget widget, Size size) async {
    try {
      final repaintBoundary = RenderRepaintBoundary();
      final view = ui.PlatformDispatcher.instance.views.first;
      final renderView = RenderView(
        view: view,
        child: RenderPositionedBox(
          alignment: Alignment.center,
          child: repaintBoundary,
        ),
        configuration: ViewConfiguration.fromView(view),
      );

      final pipelineOwner = PipelineOwner();
      final buildOwner = BuildOwner(focusManager: FocusManager());

      pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();

      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(color: Colors.transparent, child: widget),
        ),
      ).attachToRenderTree(buildOwner);

      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();

      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      final image = await repaintBoundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ Error converting widget to image: $e');
      return null;
    }
  }
}
