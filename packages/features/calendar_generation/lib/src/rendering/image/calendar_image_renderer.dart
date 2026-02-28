import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_page_model.dart';
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
    final backgroundImagesByUrl = <String, ui.Image?>{};
    Future<ui.Image?> resolveBackgroundImage(int month) async {
      final url = request.theme.backgroundImageUrlForMonth(month);
      if (url == null || url.isEmpty) {
        return null;
      }
      if (backgroundImagesByUrl.containsKey(url)) {
        return backgroundImagesByUrl[url];
      }
      final imageBytes = await _backgroundImageLoader.loadBytes(url);
      final image = await _decodeImage(imageBytes);
      backgroundImagesByUrl[url] = image;
      return image;
    }

    final generated = <Uint8List>[];
    for (final page in pages) {
      final backgroundImage = await resolveBackgroundImage(page.month);
      final bytes = await _renderSinglePage(
        request: request,
        page: page,
        width: width,
        height: height,
        backgroundImage: backgroundImage,
      );
      generated.add(bytes);
    }

    for (final image in backgroundImagesByUrl.values) {
      image?.dispose();
    }
    return generated;
  }

  Future<ui.Image?> _decodeImage(Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _renderSinglePage({
    required CalendarGenerationRequest request,
    required CalendarPageModel page,
    required int width,
    required int height,
    ui.Image? backgroundImage,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width.toDouble(), height.toDouble());
    final rect = Offset.zero & size;

    final backgroundColor = Color(request.theme.backgroundColorValue);
    final foregroundColor = Color(request.theme.foregroundColorValue);
    final accentColor = Color(request.theme.accentColorValue);

    canvas.drawRect(rect, Paint()..color = backgroundColor);

    if (backgroundImage != null) {
      canvas.saveLayer(
        rect,
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
      canvas.drawImageRect(
        backgroundImage,
        Rect.fromLTWH(
          0,
          0,
          backgroundImage.width.toDouble(),
          backgroundImage.height.toDouble(),
        ),
        rect,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    }

    const margin = 52.0;
    final contentWidth = size.width - (margin * 2);
    const titleHeight = 64.0;
    const weekdayHeight = 34.0;
    const spacing = 12.0;

    _paintCenteredText(
      canvas,
      text: page.title,
      top: margin,
      maxWidth: contentWidth,
      style: TextStyle(
        color: foregroundColor,
        fontSize: 44,
        fontWeight: FontWeight.w700,
      ),
      left: margin,
    );

    const weekdayTop = margin + titleHeight;
    for (var index = 0; index < page.weekdayLabels.length; index++) {
      final label = page.weekdayLabels[index];
      final columnLeft = margin + (index * (contentWidth / 7));
      _paintCenteredText(
        canvas,
        text: label,
        top: weekdayTop,
        maxWidth: contentWidth / 7,
        style: TextStyle(
          color: foregroundColor.withValues(alpha: 0.9),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        left: columnLeft,
      );
    }

    const gridTop = weekdayTop + weekdayHeight + spacing;
    final gridHeight = size.height - gridTop - margin;
    final cellWidth = contentWidth / 7;
    final cellHeight = gridHeight / 6;

    for (var index = 0; index < page.dayCells.length; index++) {
      final day = page.dayCells[index];
      final row = index ~/ 7;
      final column = index % 7;
      final cellLeft = margin + (column * cellWidth) + 1.5;
      final cellTop = gridTop + (row * cellHeight) + 1.5;
      final cellRect = Rect.fromLTWH(
        cellLeft,
        cellTop,
        cellWidth - 3,
        cellHeight - 3,
      );

      final hasMarker =
          (request.showHolidays && day.hasHoliday) ||
          (request.showAstrology && day.hasAstrology);
      final fillColor = day.isCurrentMonth
          ? backgroundColor.withValues(alpha: 0.92)
          : foregroundColor.withValues(alpha: 0.06);
      final borderColor = day.isToday
          ? accentColor
          : foregroundColor.withValues(alpha: 0.15);

      canvas.drawRRect(
        RRect.fromRectAndRadius(cellRect, const Radius.circular(8)),
        Paint()..color = fillColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(cellRect, const Radius.circular(8)),
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = day.isToday ? 2.2 : 1.0,
      );

      if (request.showWesternDates) {
        _paintText(
          canvas,
          text: day.westernDayLabel,
          left: cellRect.left + 7,
          top: cellRect.top + 6,
          maxWidth: cellRect.width - 12,
          style: TextStyle(
            color: foregroundColor.withValues(
              alpha: day.isCurrentMonth ? 0.95 : 0.5,
            ),
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.left,
        );
      }

      if (request.showMyanmarDates) {
        final painter = _layoutText(
          text: day.myanmarDayLabel,
          maxWidth: cellRect.width - 12,
          style: TextStyle(
            color: foregroundColor.withValues(
              alpha: day.isCurrentMonth ? 0.78 : 0.45,
            ),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.right,
        );
        painter.paint(
          canvas,
          Offset(
            cellRect.right - painter.width - 6,
            cellRect.bottom - painter.height - 6,
          ),
        );
      }

      if (hasMarker) {
        canvas.drawCircle(
          Offset(cellRect.right - 8, cellRect.top + 8),
          4.4,
          Paint()..color = accentColor,
        );
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('Failed to encode rendered calendar image');
    }
    return byteData.buffer.asUint8List();
  }

  void _paintCenteredText(
    Canvas canvas, {
    required String text,
    required double left,
    required double top,
    required double maxWidth,
    required TextStyle style,
  }) {
    final painter = _layoutText(
      text: text,
      style: style,
      maxWidth: maxWidth,
      textAlign: TextAlign.center,
    );
    painter.paint(canvas, Offset(left + ((maxWidth - painter.width) / 2), top));
  }

  void _paintText(
    Canvas canvas, {
    required String text,
    required double left,
    required double top,
    required double maxWidth,
    required TextStyle style,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = _layoutText(
      text: text,
      style: style,
      maxWidth: maxWidth,
      textAlign: textAlign,
    );
    painter.paint(canvas, Offset(left, top));
  }

  TextPainter _layoutText({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required TextAlign textAlign,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      ellipsis: '',
    )..layout(maxWidth: maxWidth);
    return painter;
  }
}
