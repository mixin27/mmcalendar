import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../theme/calendar_studio_font_catalog.dart';
import 'calendar_studio_raster_renderer.dart';

/// Static TrueType files for the editable PDF.
///
/// The pdf package can't apply a variable font's axes, so variable families
/// need one static file per weight and style (`tool/build_export_fonts.py`),
/// which [download] fetches by name. Static families come from the bundle.
class CalendarStudioExportFonts {
  const CalendarStudioExportFonts({this.download, this.hostFont});

  /// Fetches a generated static font by [fileName], or null when it can't.
  final Future<Uint8List?> Function(String fileName)? download;

  /// Fonts outside Studio's catalog, such as the host's Noto Sans Myanmar.
  final Future<Uint8List?> Function(String family, int weight, bool italic)?
  hostFont;

  static String fileName(String fontId, int weight, {required bool italic}) =>
      '$fontId-$weight${italic ? '-italic' : ''}.ttf';

  /// Variable families with an italic file; the others are slanted.
  static const _variableItalics = {
    'cormorant-garamond',
    'fraunces',
    'newsreader',
  };

  /// Static bundled files by family: weight to file, then italic files.
  static const _static = {
    'Spectral': (
      'spectral',
      {400: 'Spectral-Regular.ttf', 700: 'Spectral-Bold.ttf'},
      {400: 'Spectral-Italic.ttf'},
    ),
    'Italiana': ('italiana', {400: 'Italiana-Regular.ttf'}, <int, String>{}),
    'Noto Serif Myanmar': (
      'notoserifmyanmar',
      {
        400: 'NotoSerifMyanmar-Regular.ttf',
        600: 'NotoSerifMyanmar-SemiBold.ttf',
        700: 'NotoSerifMyanmar-Bold.ttf',
      },
      <int, String>{},
    ),
  };

  /// The face Flutter draws for [family] at [weight]: its bytes and whether
  /// it must be slanted to look italic. Null when no file is available.
  Future<(Uint8List, bool)?> load(
    String family, {
    required int weight,
    required bool italic,
  }) async {
    final name = family.replaceFirst(
      'packages/${CalendarStudioFontCatalog.package}/',
      '',
    );
    final font = CalendarStudioFontCatalog.byFamily(name);
    if (font == null) {
      final bytes = await hostFont?.call(name, weight, italic);
      return bytes == null ? null : (bytes, false);
    }
    if (font.variable) {
      final hasItalic = _variableItalics.contains(font.id);
      final rounded = ((weight / 100).round() * 100).clamp(400, 700);
      final bytes = await download?.call(
        fileName(font.id, rounded, italic: italic && hasItalic),
      );
      return bytes == null ? null : (bytes, italic && !hasItalic);
    }
    final (folder, romans, italics) = _static[name]!;
    final files = italic && italics.isNotEmpty ? italics : romans;
    // CSS matching, as Flutter does: up to 500 looks lighter first.
    final weights = files.keys.toList()..sort();
    final lighter = weights.where((w) => w <= weight).toList();
    final heavier = weights.where((w) => w >= weight).toList();
    final chosen = weight <= 500
        ? (lighter.isNotEmpty ? lighter.last : heavier.first)
        : (heavier.isNotEmpty ? heavier.first : lighter.last);
    final data = await rootBundle.load(
      'packages/${CalendarStudioFontCatalog.package}/assets/fonts/'
      '$folder/${files[chosen]}',
    );
    return (data.buffer.asUint8List(), italic && italics.isEmpty);
  }
}

/// What the editable PDF couldn't keep as vectors, by reason.
class CalendarStudioVectorReport {
  final rasterized = <String, int>{};
  void _add(String reason) =>
      rasterized.update(reason, (n) => n + 1, ifAbsent: () => 1);

  @override
  String toString() => rasterized.isEmpty
      ? 'all vector'
      : rasterized.entries.map((e) => '${e.value} × ${e.key}').join(', ');
}

/// Editable PDF: text stays text, shapes stay paths and photos stay the
/// original files, so the page opens as artwork in Illustrator.
///
/// The page is laid out by the same Flutter scene as preview and raster
/// export, then painted into a canvas that writes PDF operators instead of
/// pixels. Anything PDF can't express as vectors (Myanmar text, which needs
/// shaping the pdf package lacks; gradients; shadows) is embedded as a
/// 300 dpi image at the same place, and counted in the report.
class CalendarStudioVectorPdfRenderer {
  const CalendarStudioVectorPdfRenderer({
    required this.layout,
    this.fonts = const CalendarStudioExportFonts(),
  });

  final CalendarStudioRasterRenderer layout;
  final CalendarStudioExportFonts fonts;

  Future<(Uint8List, CalendarStudioVectorReport)> render(
    CalendarStudioProject project,
    List<CalendarStudioPage> pages,
    CalendarStudioExportPreset preset, {
    VoidCallback? onPage,
    bool compress = true,
  }) async {
    final document = PdfDocument(compress: compress);
    final report = CalendarStudioVectorReport();
    final fontCache = <String, Future<_Face?>>{};
    final pdfImages = <Uint8List, PdfImage>{};
    for (final page in pages) {
      final size = preset.pixelSizeFor(page.canvas);
      await layout.layOutPage(
        project,
        page,
        width: size.width,
        height: size.height,
        use: (laidOut) async {
          final faces = <_FontKey, _Face?>{};
          for (final key in _fontKeys(laidOut.boundary)) {
            faces[key] = await fontCache.putIfAbsent(
              key.id,
              () => _loadFace(document, key),
            );
          }
          final canvas = _PdfCanvas(document, report, faces, (image) {
            for (final (handle, bytes) in laidOut.images) {
              if (image.isCloneOf(handle)) {
                return pdfImages.putIfAbsent(
                  bytes,
                  () => PdfImage.file(document, bytes: bytes),
                );
              }
            }
            return null;
          });
          _VectorPaintingContext(
            canvas,
          ).paintChild(laidOut.boundary, Offset.zero);
          await canvas.finish();
          final widthPt = size.width / preset.dpi * PdfPageFormat.inch;
          final heightPt = size.height / preset.dpi * PdfPageFormat.inch;
          final pdfPage = PdfPage(
            document,
            pageFormat: PdfPageFormat(widthPt, heightPt),
          );
          final graphics = pdfPage.getGraphics();
          final scale = widthPt / laidOut.logicalSize.width;
          // Canvas space: design units from the top left, y down.
          graphics.setTransform(
            Matrix4.translationValues(0, heightPt, 0)
              ..scaleByDouble(scale, -scale, 1, 1),
          );
          canvas.replay(graphics);
        },
      );
      onPage?.call();
    }
    return (await document.save(), report);
  }

  Future<_Face?> _loadFace(PdfDocument document, _FontKey key) async {
    try {
      final loaded = await fonts.load(
        key.family,
        weight: key.weight,
        italic: key.italic,
      );
      if (loaded == null) return null;
      final (bytes, slant) = loaded;
      return _Face(PdfTtfFont(document, ByteData.sublistView(bytes)), slant);
    } catch (error) {
      debugPrint('Calendar Studio: no export font for ${key.id}: $error');
      return null;
    }
  }

  static Set<_FontKey> _fontKeys(RenderObject root) {
    final keys = <_FontKey>{};
    void visit(RenderObject object) {
      if (object is RenderParagraph) {
        for (final run in _runs(object.text)) {
          if (_FontKey.of(run.style) case final key?) keys.add(key);
        }
      }
      object.visitChildren(visit);
    }

    visit(root);
    return keys;
  }
}

class _FontKey {
  const _FontKey(this.family, this.weight, this.italic);
  final String family;
  final int weight;
  final bool italic;

  static _FontKey? of(TextStyle? style) {
    final family = style?.fontFamily;
    if (family == null) return null;
    // Variable fonts take weight from the axis; it wins over fontWeight.
    final axis = style!.fontVariations
        ?.where((v) => v.axis == 'wght')
        .firstOrNull;
    return _FontKey(
      family,
      axis?.value.round() ?? style.fontWeight?.value ?? 400,
      style.fontStyle == FontStyle.italic,
    );
  }

  String get id => '$family|$weight|$italic';

  @override
  bool operator ==(Object other) => other is _FontKey && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class _Face {
  const _Face(this.font, this.slant);
  final PdfFont font;

  /// No italic file: slant the upright face, as Flutter's synthetic italic.
  final bool slant;
}

class _Run {
  const _Run(this.start, this.end, this.style);
  final int start;
  final int end;
  final TextStyle? style;
}

/// [span]'s text ranges with their effective styles, in code units.
List<_Run> _runs(InlineSpan span) {
  final runs = <_Run>[];
  var offset = 0;
  void walk(InlineSpan span, TextStyle? parent) {
    final style = parent == null ? span.style : parent.merge(span.style);
    if (span is TextSpan) {
      final text = span.text;
      if (text != null && text.isNotEmpty) {
        runs.add(_Run(offset, offset + text.length, style));
        offset += text.length;
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        walk(child, style);
      }
    } else if (span is PlaceholderSpan) {
      offset += 1;
    }
  }

  walk(span, null);
  return runs;
}

bool _isMyanmar(int unit) =>
    (unit >= 0x1000 && unit <= 0x109F) ||
    (unit >= 0xA9E0 && unit <= 0xA9FF) ||
    (unit >= 0xAA60 && unit <= 0xAA7F);

/// Paints render objects straight into [_PdfCanvas]: no layers, no
/// compositing, so clips and transforms reach the canvas as calls.
class _VectorPaintingContext extends PaintingContext {
  _VectorPaintingContext(this._canvas) : super(ContainerLayer(), Rect.largest);

  final _PdfCanvas _canvas;

  @override
  Canvas get canvas => _canvas;

  @override
  void paintChild(RenderObject child, Offset offset) {
    final previous = _canvas.paragraph;
    if (child is RenderParagraph) _canvas.paragraph = child;
    child.paint(this, offset);
    _canvas.paragraph = previous;
  }

  // Never records a picture, so the base call has nothing to stop.
  @override
  void stopRecordingIfNeeded() => super.stopRecordingIfNeeded();

  @override
  void addLayer(Layer layer) => _canvas.report._add('platform layer');

  @override
  void pushLayer(
    ContainerLayer childLayer,
    PaintingContextCallback painter,
    Offset offset, {
    Rect? childPaintBounds,
  }) {
    // Layer effects (shader masks, filters) aren't kept; the content is.
    _canvas.report._add('layer effect');
    painter(this, offset);
  }

  @override
  ClipRectLayer? pushClipRect(
    bool needsCompositing,
    Offset offset,
    Rect clipRect,
    PaintingContextCallback painter, {
    Clip clipBehavior = Clip.hardEdge,
    ClipRectLayer? oldLayer,
  }) => super.pushClipRect(
    false,
    offset,
    clipRect,
    painter,
    clipBehavior: clipBehavior,
  );

  @override
  ClipRRectLayer? pushClipRRect(
    bool needsCompositing,
    Offset offset,
    Rect bounds,
    RRect clipRRect,
    PaintingContextCallback painter, {
    Clip clipBehavior = Clip.antiAlias,
    ClipRRectLayer? oldLayer,
  }) => super.pushClipRRect(
    false,
    offset,
    bounds,
    clipRRect,
    painter,
    clipBehavior: clipBehavior,
  );

  @override
  ClipRSuperellipseLayer? pushClipRSuperellipse(
    bool needsCompositing,
    Offset offset,
    Rect bounds,
    RSuperellipse clipRSuperellipse,
    PaintingContextCallback painter, {
    Clip clipBehavior = Clip.antiAlias,
    ClipRSuperellipseLayer? oldLayer,
  }) => super.pushClipRSuperellipse(
    false,
    offset,
    bounds,
    clipRSuperellipse,
    painter,
    clipBehavior: clipBehavior,
  );

  @override
  ClipPathLayer? pushClipPath(
    bool needsCompositing,
    Offset offset,
    Rect bounds,
    Path clipPath,
    PaintingContextCallback painter, {
    Clip clipBehavior = Clip.antiAlias,
    ClipPathLayer? oldLayer,
  }) => super.pushClipPath(
    false,
    offset,
    bounds,
    clipPath,
    painter,
    clipBehavior: clipBehavior,
  );

  @override
  TransformLayer? pushTransform(
    bool needsCompositing,
    Offset offset,
    Matrix4 transform,
    PaintingContextCallback painter, {
    TransformLayer? oldLayer,
  }) => super.pushTransform(false, offset, transform, painter);

  @override
  OpacityLayer pushOpacity(
    Offset offset,
    int alpha,
    PaintingContextCallback painter, {
    OpacityLayer? oldLayer,
  }) {
    _canvas.saveLayer(null, Paint()..color = Color.fromARGB(alpha, 0, 0, 0));
    painter(this, offset);
    _canvas.restore();
    return OpacityLayer();
  }

  @override
  ColorFilterLayer pushColorFilter(
    Offset offset,
    ColorFilter colorFilter,
    PaintingContextCallback painter, {
    ColorFilterLayer? oldLayer,
  }) {
    _canvas.report._add('colour filter');
    painter(this, offset);
    return ColorFilterLayer();
  }
}

typedef _Op = void Function(PdfGraphics g);

/// A [Canvas] that records PDF drawing operations.
///
/// Canvas calls are synchronous but rasterizing a fallback is not, so calls
/// become operations that [replay] writes once [finish] has prepared every
/// image. Coordinates stay in canvas space; the page transform flips y.
class _PdfCanvas implements Canvas {
  _PdfCanvas(this.document, this.report, this.faces, this.imageFor);

  final PdfDocument document;
  final CalendarStudioVectorReport report;
  final Map<_FontKey, _Face?> faces;
  final PdfImage? Function(ui.Image image) imageFor;

  /// The paragraph being painted, so drawParagraph knows its text.
  RenderParagraph? paragraph;

  final _ops = <_Op>[];
  final _pending = <Future<void>>[];
  final _matrices = <Matrix4>[Matrix4.identity()];
  final _alphas = <double>[1];

  Matrix4 get _matrix => _matrices.last;
  double get _alpha => _alphas.last;

  Future<void> finish() => Future.wait(_pending);

  void replay(PdfGraphics g) {
    for (final op in _ops) {
      op(g);
    }
  }

  // State.

  @override
  void save() {
    _matrices.add(_matrix.clone());
    _alphas.add(_alpha);
    _ops.add((g) => g.saveContext());
  }

  @override
  void saveLayer(Rect? bounds, Paint paint) {
    save();
    // Group opacity, applied to each drawing inside.
    _alphas.last = _alpha * paint.color.a;
  }

  @override
  void restore() {
    if (_matrices.length == 1) return;
    _matrices.removeLast();
    _alphas.removeLast();
    _ops.add((g) => g.restoreContext());
  }

  @override
  void restoreToCount(int count) {
    while (_matrices.length > math.max(count, 1)) {
      restore();
    }
  }

  @override
  int getSaveCount() => _matrices.length;

  void _concat(Matrix4 m) {
    _matrix.multiply(m);
    _ops.add((g) => g.setTransform(m));
  }

  @override
  void translate(double dx, double dy) =>
      _concat(Matrix4.translationValues(dx, dy, 0));

  @override
  void scale(double sx, [double? sy]) =>
      _concat(Matrix4.diagonal3Values(sx, sy ?? sx, 1));

  @override
  void rotate(double radians) => _concat(Matrix4.rotationZ(radians));

  @override
  void skew(double sx, double sy) => _concat(
    Matrix4.identity()
      ..setEntry(0, 1, sx)
      ..setEntry(1, 0, sy),
  );

  @override
  void transform(Float64List matrix4) =>
      _concat(Matrix4.fromFloat64List(matrix4));

  @override
  Float64List getTransform() => Float64List.fromList(_matrix.storage);

  // Clips.

  @override
  void clipRect(
    Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    if (clipOp == ui.ClipOp.difference) return;
    _ops.add((g) {
      g.drawRect(rect.left, rect.top, rect.width, rect.height);
      g.clipPath();
    });
  }

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) => _ops.add((g) {
    _rrect(g, rrect);
    g.clipPath();
  });

  @override
  void clipRSuperellipse(
    RSuperellipse rsuperellipse, {
    bool doAntiAlias = true,
  }) => clipRRect(_approximate(rsuperellipse));

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) => _ops.add((g) {
    _path(g, path);
    g.clipPath(evenOdd: path.fillType == PathFillType.evenOdd);
  });

  @override
  Rect getLocalClipBounds() => Rect.largest;

  @override
  Rect getDestinationClipBounds() => Rect.largest;

  // Drawing.

  /// Draws [shape] with [paint] as vectors, or as an image when PDF can't
  /// express the paint (shaders, blurs, filters).
  void _draw(
    Paint paint,
    Rect bounds,
    void Function(PdfGraphics g) shape,
    void Function(Canvas c) raster, {
    bool evenOdd = false,
  }) {
    if (paint.shader != null ||
        paint.maskFilter != null ||
        paint.imageFilter != null ||
        paint.colorFilter != null) {
      report._add(paint.shader != null ? 'gradient' : 'effect');
      _rasterize(bounds, raster);
      return;
    }
    final alpha = paint.color.a * _alpha;
    if (alpha <= 0) return;
    final color = _color(paint.color);
    final stroke = paint.style == PaintingStyle.stroke;
    final width = paint.strokeWidth;
    final cap = paint.strokeCap;
    final join = paint.strokeJoin;
    _ops.add((g) {
      g.saveContext();
      if (alpha < 1) {
        g.setGraphicState(PdfGraphicState(opacity: alpha));
      }
      if (stroke) {
        g
          ..setStrokeColor(color)
          // Hairlines (0) draw one device pixel in Flutter; keep them thin.
          ..setLineWidth(width == 0 ? .25 : width)
          ..setLineCap(switch (cap) {
            StrokeCap.butt => PdfLineCap.butt,
            StrokeCap.round => PdfLineCap.round,
            StrokeCap.square => PdfLineCap.square,
          })
          ..setLineJoin(switch (join) {
            StrokeJoin.miter => PdfLineJoin.miter,
            StrokeJoin.round => PdfLineJoin.round,
            StrokeJoin.bevel => PdfLineJoin.bevel,
          });
        shape(g);
        g.strokePath();
      } else {
        g.setFillColor(color);
        shape(g);
        g.fillPath(evenOdd: evenOdd);
      }
      g.restoreContext();
    });
  }

  @override
  void drawColor(Color color, BlendMode blendMode) =>
      drawPaint(Paint()..color = color);

  @override
  void drawPaint(Paint paint) {
    const huge = Rect.fromLTRB(-1e5, -1e5, 1e5, 1e5);
    drawRect(huge, paint..style = PaintingStyle.fill);
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => _draw(
    paint..style = PaintingStyle.stroke,
    Rect.fromPoints(p1, p2).inflate(paint.strokeWidth),
    (g) => g
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy),
    (c) => c.drawLine(p1, p2, paint),
  );

  @override
  void drawRect(Rect rect, Paint paint) => _draw(
    paint,
    rect.inflate(paint.strokeWidth),
    (g) => g.drawRect(rect.left, rect.top, rect.width, rect.height),
    (c) => c.drawRect(rect, paint),
  );

  @override
  void drawRRect(RRect rrect, Paint paint) => _draw(
    paint,
    rrect.outerRect.inflate(paint.strokeWidth),
    (g) => _rrect(g, rrect),
    (c) => c.drawRRect(rrect, paint),
  );

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) => _draw(
    paint,
    outer.outerRect,
    (g) {
      _rrect(g, outer);
      _rrect(g, inner);
    },
    (c) => c.drawDRRect(outer, inner, paint),
    evenOdd: true,
  );

  @override
  void drawRSuperellipse(RSuperellipse rsuperellipse, Paint paint) =>
      drawRRect(_approximate(rsuperellipse), paint);

  @override
  void drawOval(Rect rect, Paint paint) => _draw(
    paint,
    rect.inflate(paint.strokeWidth),
    (g) => g.drawEllipse(
      rect.center.dx,
      rect.center.dy,
      rect.width / 2,
      rect.height / 2,
    ),
    (c) => c.drawOval(rect, paint),
  );

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      drawOval(Rect.fromCircle(center: c, radius: radius), paint);

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) {
    final path = Path();
    if (useCenter) path.moveTo(rect.center.dx, rect.center.dy);
    path.arcTo(rect, startAngle, sweepAngle, !useCenter);
    if (useCenter) path.close();
    drawPath(path, paint);
  }

  @override
  void drawPath(Path path, Paint paint) => _draw(
    paint,
    path.getBounds().inflate(paint.strokeWidth),
    (g) => _path(g, path),
    (c) => c.drawPath(path, paint),
    evenOdd: path.fillType == PathFillType.evenOdd,
  );

  @override
  void drawPoints(ui.PointMode pointMode, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    switch (pointMode) {
      case ui.PointMode.points:
        for (final point in points) {
          drawCircle(
            point,
            paint.strokeWidth / 2,
            Paint()..color = paint.color,
          );
        }
      case ui.PointMode.lines:
        for (var i = 0; i + 1 < points.length; i += 2) {
          drawLine(points[i], points[i + 1], paint);
        }
      case ui.PointMode.polygon:
        final path = Path()..addPolygon(points, false);
        drawPath(path, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, Paint paint) =>
      drawPoints(pointMode, [
        for (var i = 0; i + 1 < points.length; i += 2)
          Offset(points[i], points[i + 1]),
      ], paint);

  @override
  void drawImage(ui.Image image, Offset offset, Paint paint) => drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width * 1.0, image.height * 1.0),
    Rect.fromLTWH(offset.dx, offset.dy, image.width * 1.0, image.height * 1.0),
    paint,
  );

  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) {
    final pdfImage = imageFor(image);
    if (pdfImage == null) {
      report._add('image');
      _rasterize(dst, (c) => c.drawImageRect(image, src, dst, paint));
      return;
    }
    // The whole original placed so that [src] lands on [dst], clipped to
    // [dst]: Illustrator gets the full photo inside a clipping mask.
    final sx = dst.width / src.width;
    final sy = dst.height / src.height;
    final full = Rect.fromLTWH(
      dst.left - src.left * sx,
      dst.top - src.top * sy,
      image.width * sx,
      image.height * sy,
    );
    final alpha = paint.color.a * _alpha;
    _ops.add((g) {
      g
        ..saveContext()
        ..drawRect(dst.left, dst.top, dst.width, dst.height)
        ..clipPath();
      if (alpha < 1) g.setGraphicState(PdfGraphicState(opacity: alpha));
      _placeImage(g, pdfImage, full);
      g.restoreContext();
    });
  }

  @override
  void drawImageNine(ui.Image image, Rect center, Rect dst, Paint paint) {
    report._add('nine-patch image');
    _rasterize(dst, (c) => c.drawImageNine(image, center, dst, paint));
  }

  @override
  void drawPicture(ui.Picture picture) => report._add('picture (dropped)');

  @override
  void drawVertices(ui.Vertices vertices, BlendMode blendMode, Paint paint) =>
      report._add('vertices (dropped)');

  @override
  void drawAtlas(
    ui.Image atlas,
    List<RSTransform> transforms,
    List<Rect> rects,
    List<Color>? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) => report._add('atlas (dropped)');

  @override
  void drawRawAtlas(
    ui.Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) => report._add('atlas (dropped)');

  @override
  void drawShadow(
    Path path,
    Color color,
    double elevation,
    bool transparentOccluder,
  ) {
    report._add('shadow');
    _rasterize(
      path.getBounds().inflate(elevation * 2),
      (c) => c.drawShadow(path, color, elevation, transparentOccluder),
    );
  }

  // Text.

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    final owner = this.paragraph;
    final runs = owner == null ? const <_Run>[] : _runs(owner.text);
    final text = owner?.text.toPlainText(includePlaceholders: true) ?? '';
    final reason = owner == null
        ? 'text'
        : text.codeUnits.any(_isMyanmar)
        ? 'Myanmar text'
        : runs.any((run) => faces[_FontKey.of(run.style)] == null)
        ? 'text without export font'
        // Flutter draws a glyph the font lacks from a fallback font; the PDF
        // can only use the one font, so the paragraph keeps Flutter's look.
        : runs.any((run) => !_covers(faces[_FontKey.of(run.style)]!, text, run))
        ? 'text in a fallback font'
        : null;
    if (reason != null) {
      report._add(reason);
      _rasterize(
        _paragraphBounds(paragraph).shift(offset),
        (c) => c.drawParagraph(paragraph, offset),
        dpi: 600,
      );
      return;
    }
    final lines = paragraph.computeLineMetrics();
    final scaler = owner!.textScaler;
    for (final run in runs) {
      final face = faces[_FontKey.of(run.style)]!;
      final style = run.style!;
      final size = scaler.scale(style.fontSize ?? 14);
      final color = style.color ?? style.foreground?.color ?? Colors.black;
      final alpha = color.a * _alpha;
      if (alpha <= 0) continue;
      // One text object per line of the run, so Illustrator edits words,
      // not letters; spacing is fitted to where Flutter put the glyphs.
      int? line;
      var start = run.start;
      var left = 0.0;
      var right = 0.0;
      void flush(int end) {
        if (line == null || end <= start) return;
        final chunk = text.substring(start, end).replaceAll('\n', '');
        if (chunk.trim().isEmpty) return;
        final natural = face.font.stringMetrics(chunk).advanceWidth * size;
        final charSpace = (right - left - natural) / chunk.length;
        final x = offset.dx + left;
        final y = offset.dy + lines[line].baseline;
        final slant = face.slant;
        _ops.add((g) {
          g.saveContext();
          final m = Matrix4.translationValues(x, y, 0)
            ..scaleByDouble(1, -1, 1, 1);
          // Flutter's synthetic italic leans glyphs by a quarter.
          if (slant) m.setEntry(0, 1, .25);
          g.setTransform(m);
          if (alpha < 1) g.setGraphicState(PdfGraphicState(opacity: alpha));
          g
            ..setFillColor(_color(color))
            ..drawString(face.font, size, chunk, 0, 0, charSpace: charSpace);
          g.restoreContext();
        });
      }

      var i = run.start;
      while (i < run.end) {
        final unit = text.codeUnitAt(i);
        final step = unit >= 0xD800 && unit <= 0xDBFF ? 2 : 1;
        final boxes = paragraph.getBoxesForRange(i, i + step);
        final number = paragraph.getLineNumberAt(i);
        if (boxes.isNotEmpty && number != null) {
          if (number != line) {
            flush(i);
            line = number;
            start = i;
            left = boxes.first.left;
          }
          right = boxes.last.right;
        }
        i += step;
      }
      flush(run.end);
    }
  }

  static bool _covers(_Face face, String text, _Run run) {
    for (final rune in text.substring(run.start, run.end).runes) {
      // Spaces and line breaks need no glyph; placeholders aren't drawn.
      if (rune <= 0x20 || rune == 0xFFFC) continue;
      if (!face.font.isRuneSupported(rune)) return false;
    }
    return true;
  }

  static Rect _paragraphBounds(ui.Paragraph paragraph) {
    final lines = paragraph.computeLineMetrics();
    var bounds = Rect.zero;
    for (final line in lines) {
      bounds = bounds.expandToInclude(
        Rect.fromLTWH(
          line.left,
          line.baseline - line.ascent,
          line.width,
          line.ascent + line.descent,
        ),
      );
    }
    // Myanmar stacks marks above and below the line box.
    final pad = lines.isEmpty ? 0.0 : lines.first.height * .5;
    return bounds.inflate(pad);
  }

  // Fallback images.

  /// Draws [draw] into an image covering [bounds] at about [dpi] on the
  /// printed page, and places it there.
  void _rasterize(Rect bounds, void Function(Canvas c) draw, {int dpi = 300}) {
    if (bounds.isEmpty || !bounds.isFinite) return;
    // Design units are points before the page scale; the matrix adds the
    // scene's own scaling (fitted text, zoom).
    final unitScale = _matrix.getMaxScaleOnAxis();
    final pixelsPerUnit = unitScale * dpi / 72;
    final width = (bounds.width * pixelsPerUnit).ceil().clamp(1, 8000);
    final height = (bounds.height * pixelsPerUnit).ceil().clamp(1, 8000);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(width / bounds.width, height / bounds.height)
      ..translate(-bounds.left, -bounds.top);
    draw(canvas);
    final picture = recorder.endRecording();
    final alpha = _alpha;
    late final PdfImage image;
    _pending.add(() async {
      final raster = await picture.toImage(width, height);
      picture.dispose();
      final rgba = await raster.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      raster.dispose();
      image = PdfImage(
        document,
        image: rgba!.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes),
        width: width,
        height: height,
      );
    }());
    _ops.add((g) {
      g.saveContext();
      if (alpha < 1) g.setGraphicState(PdfGraphicState(opacity: alpha));
      _placeImage(g, image, bounds);
      g.restoreContext();
    });
  }

  /// Places [image] upright in [rect] (canvas space is y-down).
  static void _placeImage(PdfGraphics g, PdfImage image, Rect rect) {
    g
      ..saveContext()
      ..setTransform(
        Matrix4.translationValues(rect.left, rect.bottom, 0)
          ..scaleByDouble(1, -1, 1, 1),
      )
      ..drawImage(image, 0, 0, rect.width, rect.height)
      ..restoreContext();
  }

  // Geometry.

  static PdfColor _color(Color color) => PdfColor(color.r, color.g, color.b);

  static RRect _approximate(RSuperellipse shape) => RRect.fromLTRBAndCorners(
    shape.left,
    shape.top,
    shape.right,
    shape.bottom,
    topLeft: shape.tlRadius,
    topRight: shape.trRadius,
    bottomRight: shape.brRadius,
    bottomLeft: shape.blRadius,
  );

  /// Bézier handle length for a quarter circle.
  static const _k = .5522847498;

  static void _rrect(PdfGraphics g, RRect r) {
    if (r.isRect) {
      g.drawRect(r.left, r.top, r.width, r.height);
      return;
    }
    g
      ..moveTo(r.left + r.tlRadiusX, r.top)
      ..lineTo(r.right - r.trRadiusX, r.top)
      ..curveTo(
        r.right - r.trRadiusX * (1 - _k),
        r.top,
        r.right,
        r.top + r.trRadiusY * (1 - _k),
        r.right,
        r.top + r.trRadiusY,
      )
      ..lineTo(r.right, r.bottom - r.brRadiusY)
      ..curveTo(
        r.right,
        r.bottom - r.brRadiusY * (1 - _k),
        r.right - r.brRadiusX * (1 - _k),
        r.bottom,
        r.right - r.brRadiusX,
        r.bottom,
      )
      ..lineTo(r.left + r.blRadiusX, r.bottom)
      ..curveTo(
        r.left + r.blRadiusX * (1 - _k),
        r.bottom,
        r.left,
        r.bottom - r.blRadiusY * (1 - _k),
        r.left,
        r.bottom - r.blRadiusY,
      )
      ..lineTo(r.left, r.top + r.tlRadiusY)
      ..curveTo(
        r.left,
        r.top + r.tlRadiusY * (1 - _k),
        r.left + r.tlRadiusX * (1 - _k),
        r.top,
        r.left + r.tlRadiusX,
        r.top,
      )
      ..closePath();
  }

  /// [path] as straight segments half a design unit apart: a `ui.Path`
  /// can't report its curves (Phase 1 records them where shapes are built).
  static void _path(PdfGraphics g, Path path) {
    for (final metric in path.computeMetrics()) {
      final steps = math.max(2, (metric.length / .5).ceil());
      for (var i = 0; i <= steps; i++) {
        final point = metric
            .getTangentForOffset(metric.length * i / steps)!
            .position;
        if (i == 0) {
          g.moveTo(point.dx, point.dy);
        } else {
          g.lineTo(point.dx, point.dy);
        }
      }
      if (metric.isClosed) g.closePath();
    }
  }
}
