// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../presentation/widgets/previews/compact_preview_widget.dart';
import '../presentation/widgets/previews/full_calendar_preview_widget.dart';
import '../presentation/widgets/previews/moon_phase_preview_widget.dart';
import '../presentation/widgets/previews/myanmar_month_preview_widget.dart';

class WidgetPreviewGenerator {
  /// Generate all widget previews
  Future<Map<String, String>> generateAllPreviews(BuildContext context) async {
    final previews = <String, String>{};

    try {
      debugPrint('🎨 Generating widget previews...');

      // Generate preview for each widget type
      previews['compact'] = await generateCompactPreview(context);
      previews['full_calendar'] = await generateFullCalendarPreview(context);
      previews['moon_phase'] = await generateMoonPhasePreview(context);
      previews['myanmar_month'] = await generateMyanmarMonthPreview(context);

      debugPrint('✅ All previews generated successfully');
      return previews;
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating previews: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Generate Compact Date Widget preview
  Future<String> generateCompactPreview(BuildContext context) async {
    final widget = CompactPreviewWidget();
    return await _captureWidget(
      context,
      widget,
      'preview_compact_widget',
      width: 250,
      height: 110,
    );
  }

  /// Generate Full Calendar Widget preview
  Future<String> generateFullCalendarPreview(BuildContext context) async {
    final widget = FullCalendarPreviewWidget();
    return await _captureWidget(
      context,
      widget,
      'preview_full_calendar_widget',
      width: 450,
      height: 250,
    );
  }

  /// Generate Moon Phase Widget preview
  Future<String> generateMoonPhasePreview(BuildContext context) async {
    final widget = MoonPhasePreviewWidget();
    return await _captureWidget(
      context,
      widget,
      'preview_moon_phase_widget',
      width: 180,
      height: 250,
    );
  }

  /// Generate Myanmar Month Widget preview
  Future<String> generateMyanmarMonthPreview(BuildContext context) async {
    final widget = MyanmarMonthPreviewWidget();
    return await _captureWidget(
      context,
      widget,
      'preview_myanmar_month_widget',
      width: 450,
      height: 450,
    );
  }

  /// Capture widget as image using overlay
  Future<String> _captureWidget(
    BuildContext context,
    Widget widget,
    String filename, {
    required double width,
    required double height,
  }) async {
    try {
      debugPrint('📸 Capturing preview: $filename');

      final key = GlobalKey();

      // Create overlay entry using the provided context
      final overlayEntry = OverlayEntry(
        builder: (_) => Positioned(
          left: -width * 2,
          top: -height * 2,
          child: Material(
            color: Colors.transparent,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(width: width, height: height, child: widget),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlayEntry);

      // Wait for rendering
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        final boundary =
            key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) {
          throw Exception('Failed to find RenderRepaintBoundary');
        }

        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) {
          throw Exception('Failed to convert image to bytes');
        }

        final bytes = byteData.buffer.asUint8List();
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$filename.png';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        debugPrint('✅ Preview saved: $filePath');
        return filePath;
      } finally {
        overlayEntry.remove();
      }
    } catch (e) {
      debugPrint('❌ Error capturing preview: $e');
      rethrow;
    }
  }

  /// Copy previews to Android res/drawable
  Future<void> copyPreviewsToAndroid(Map<String, String> previews) async {
    try {
      debugPrint('📋 Copying previews to Android resources...');

      for (final entry in previews.entries) {
        final sourceFile = File(entry.value);
        if (!await sourceFile.exists()) {
          debugPrint('⚠️ Preview file not found: ${entry.value}');
          continue;
        }

        // Determine Android res path
        // You'll need to adjust this path based on your project structure
        final androidResPath =
            'android/app/src/main/res/drawable/${entry.key}.png';
        final destFile = File(androidResPath);

        // Create directory if it doesn't exist
        await destFile.parent.create(recursive: true);

        // Copy file
        await sourceFile.copy(destFile.path);
        debugPrint('✅ Copied ${entry.key} to Android resources');
      }

      debugPrint('✅ All previews copied to Android');
    } catch (e) {
      debugPrint('❌ Error copying previews: $e');
      rethrow;
    }
  }

  /// Copy previews to a shareable location
  Future<Map<String, String>> copyPreviewsToShareable(
    Map<String, String> previews,
  ) async {
    try {
      debugPrint('📋 Preparing previews for sharing...');

      final Map<String, String> shareablePaths = {};

      // Get external storage directory (accessible to user)
      Directory? externalDir;

      if (Platform.isAndroid) {
        // Use Downloads directory on Android
        externalDir = Directory('/storage/emulated/0/Download/widget_previews');
      } else if (Platform.isIOS) {
        // Use Documents directory on iOS
        externalDir = await getApplicationDocumentsDirectory();
      }

      if (externalDir == null) {
        throw Exception('Could not find shareable directory');
      }

      // Create directory if it doesn't exist
      if (!await externalDir.exists()) {
        await externalDir.create(recursive: true);
      }

      for (final entry in previews.entries) {
        final sourceFile = File(entry.value);
        if (!await sourceFile.exists()) {
          debugPrint('⚠️ Preview file not found: ${entry.value}');
          continue;
        }

        // Copy to shareable location
        final destPath = '${externalDir.path}/${entry.key}.png';
        final destFile = await sourceFile.copy(destPath);

        shareablePaths[entry.key] = destFile.path;
        debugPrint('✅ Copied ${entry.key} to ${destFile.path}');
      }

      debugPrint(
        '✅ All previews copied to shareable location: ${externalDir.path}',
      );
      return shareablePaths;
    } catch (e) {
      debugPrint('❌ Error copying previews: $e');
      rethrow;
    }
  }
}
