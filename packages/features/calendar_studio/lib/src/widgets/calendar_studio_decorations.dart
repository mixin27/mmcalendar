import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/calendar_studio_document.dart';

/// Recolourable decoration art for the round-2 presets.
///
/// Every painter draws inside its block's box, keeps its own aspect where
/// stretching would distort it (weave, wave stroke, rings), and reads
/// `style.color`, `style.accent` and `style.opacity`.
abstract final class CalendarStudioDecorations {
  static const kinds = {
    'ringsLinked',
    'frame',
    'paperLantern',
    'halftoneBurst',
    'leafSprig',
    'crescent',
    'ghostWisp',
    'horizonWave',
    'diamondWeave',
    'starField',
    'zodiacWheel',
    'stupa',
    'sunRays',
    'steamCurl',
    'compassStar',
  };

  /// The decoration for [block], or null when its kind isn't one of [kinds].
  static Widget? build(CalendarStudioBlock block) {
    final kind = block.content['kind'];
    if (kind is! String || !kinds.contains(kind)) return null;
    final opacity = ((block.style['opacity'] as num?)?.toDouble() ?? 1).clamp(
      0.0,
      1.0,
    );
    Color read(String key, int fallback) =>
        Color(block.style[key] as int? ?? fallback).withValues(
          alpha: Color(block.style[key] as int? ?? fallback).a * opacity,
        );
    final palette = _Palette(
      color: read('color', 0xFF15201D),
      accent: read('accent', 0xFFB98A25),
      seed: block.content['seed'] as int? ?? 7,
      avoid: _avoidRect(block.content['avoid']),
    );
    return CustomPaint(
      painter: _DecorationPainter(kind, palette),
      size: Size.infinite,
    );
  }

  static Rect? _avoidRect(Object? value) {
    if (value is! List || value.length != 4) return null;
    final v = [for (final item in value) (item as num).toDouble()];
    return Rect.fromLTWH(v[0], v[1], v[2], v[3]);
  }
}

class _Palette {
  const _Palette({
    required this.color,
    required this.accent,
    required this.seed,
    this.avoid,
  });
  final Color color;
  final Color accent;
  final int seed;

  /// Area (0..1 of the box) a scatter decoration leaves clear, e.g. the grid.
  final Rect? avoid;

  @override
  bool operator ==(Object other) =>
      other is _Palette &&
      other.color == color &&
      other.accent == accent &&
      other.seed == seed &&
      other.avoid == avoid;

  @override
  int get hashCode => Object.hash(color, accent, seed, avoid);
}

class _DecorationPainter extends CustomPainter {
  const _DecorationPainter(this.kind, this.palette);
  final String kind;
  final _Palette palette;

  Paint _fill(Color color) => Paint()
    ..color = color
    ..isAntiAlias = true;

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    switch (kind) {
      case 'ringsLinked':
        _rings(canvas, size);
      case 'frame':
        _frame(canvas, size);
      case 'paperLantern':
        _lanterns(canvas, size);
      case 'halftoneBurst':
        _halftone(canvas, size);
      case 'leafSprig':
        _sprig(canvas, size);
      case 'crescent':
        _crescent(canvas, size);
      case 'ghostWisp':
        _ghost(canvas, size);
      case 'horizonWave':
        _wave(canvas, size);
      case 'diamondWeave':
        _weave(canvas, size);
      case 'starField':
        _stars(canvas, size);
      case 'zodiacWheel':
        _zodiac(canvas, size);
      case 'stupa':
        _stupa(canvas, size);
      case 'sunRays':
        _sunRays(canvas, size);
      case 'steamCurl':
        _steam(canvas, size);
      case 'compassStar':
        _compass(canvas, size);
    }
    canvas.restore();
  }

  /// Square area centred in the box, so round art never stretches.
  Rect _square(Size size) {
    final side = size.shortestSide;
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side,
      height: side,
    );
  }

  void _rings(Canvas canvas, Size size) {
    final r = math.min(size.width / 3.4, size.height / 2.2);
    final width = r * .14;
    final center = size.center(Offset.zero);
    final offset = Offset(r * .62, 0);
    canvas
      ..drawCircle(center - offset, r - width, _stroke(palette.color, width))
      ..drawCircle(center + offset, r - width, _stroke(palette.accent, width));
    // Redraw the left ring's lower arc on top so the rings interlock.
    canvas.drawArc(
      Rect.fromCircle(center: center - offset, radius: r - width),
      -.35,
      .7,
      false,
      _stroke(palette.color, width),
    );
  }

  void _frame(Canvas canvas, Size size) {
    final stroke = math.max(1.5, size.shortestSide * .012);
    final outer = (Offset.zero & size).deflate(stroke);
    final inner = outer.deflate(stroke * 3.5);
    canvas
      ..drawRect(outer, _stroke(palette.color, stroke))
      ..drawRect(inner, _stroke(palette.color, stroke * .5));
    final d = stroke * 4;
    for (final corner in [
      outer.topLeft,
      outer.topRight,
      outer.bottomLeft,
      outer.bottomRight,
    ]) {
      final path = Path()
        ..moveTo(corner.dx, corner.dy - d)
        ..lineTo(corner.dx + d, corner.dy)
        ..lineTo(corner.dx, corner.dy + d)
        ..lineTo(corner.dx - d, corner.dy)
        ..close();
      canvas.drawPath(path, _fill(palette.accent));
    }
  }

  void _lanterns(Canvas canvas, Size size) {
    final count = 3;
    final slot = size.width / count;
    for (var i = 0; i < count; i++) {
      final cx = slot * (i + .5);
      final drop = size.height * (i.isOdd ? .18 : .06);
      final w = math.min(slot * .62, size.height * .5);
      final h = w * 1.25;
      final top = drop + size.height * .14;
      final stroke = math.max(1.0, w * .05);
      canvas.drawLine(
        Offset(cx, 0),
        Offset(cx, top),
        _stroke(palette.color, stroke * .6),
      );
      final body = Rect.fromCenter(
        center: Offset(cx, top + h / 2),
        width: w,
        height: h,
      );
      canvas
        ..drawOval(body, _fill(palette.accent))
        ..drawOval(body, _stroke(palette.color, stroke));
      for (final f in [.3, .7]) {
        final y = body.top + body.height * f;
        final half = w / 2 * math.sqrt(1 - math.pow(2 * f - 1, 2));
        canvas.drawLine(
          Offset(cx - half, y),
          Offset(cx + half, y),
          _stroke(palette.color, stroke * .7),
        );
      }
      final cap = Rect.fromCenter(
        center: Offset(cx, body.top),
        width: w * .42,
        height: h * .1,
      );
      canvas
        ..drawRect(cap, _fill(palette.color))
        ..drawRect(cap.shift(Offset(0, h)), _fill(palette.color))
        ..drawLine(
          Offset(cx, body.bottom + h * .05),
          Offset(cx, math.min(size.height, body.bottom + h * .3)),
          _stroke(palette.color, stroke * .6),
        );
    }
  }

  void _halftone(Canvas canvas, Size size) {
    final center = Offset(size.width * .78, size.height * .32);
    final maxR = (Offset.zero & size).bottomLeft - center;
    final reach = maxR.distance;
    final step = size.shortestSide / 9;
    for (var ring = 1; ring * step < reach; ring++) {
      final radius = ring * step;
      final count = (2 * math.pi * radius / step).floor();
      final dot = step * .42 * (1 - radius / reach).clamp(.08, 1);
      for (var i = 0; i < count; i++) {
        final angle = i / count * 2 * math.pi + ring * .3;
        final p = center + Offset(math.cos(angle), math.sin(angle)) * radius;
        canvas.drawCircle(p, dot, _fill(palette.color));
      }
    }
    canvas.drawCircle(center, step * .45, _fill(palette.accent));
  }

  void _sprig(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = math.max(1.2, size.shortestSide * .025);
    final stem = Path()
      ..moveTo(w * .15, h * .95)
      ..cubicTo(w * .35, h * .7, w * .45, h * .35, w * .8, h * .05);
    canvas.drawPath(stem, _stroke(palette.color, stroke));
    final metric = stem.computeMetrics().first;
    for (var i = 0; i < 5; i++) {
      final t = .18 + i * .17;
      final tangent = metric.getTangentForOffset(metric.length * t)!;
      final side = i.isEven ? 1.0 : -1.0;
      final leafLength = size.shortestSide * (.34 - i * .03);
      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(-tangent.angle + side * .9);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(leafLength * .5, -leafLength * .28, leafLength, 0)
        ..quadraticBezierTo(leafLength * .5, leafLength * .28, 0, 0);
      canvas
        ..drawPath(
          leaf,
          _fill(palette.accent.withValues(alpha: palette.accent.a * .35)),
        )
        ..drawPath(leaf, _stroke(palette.color, stroke * .8))
        ..drawLine(
          Offset.zero,
          Offset(leafLength * .8, 0),
          _stroke(palette.color, stroke * .45),
        );
      canvas.restore();
    }
  }

  void _crescent(Canvas canvas, Size size) {
    final box = _square(size);
    final r = box.width / 2;
    final outer = Path()..addOval(box);
    final inner = Path()
      ..addOval(
        Rect.fromCircle(
          center: box.center + Offset(r * .45, -r * .2),
          radius: r * .88,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      _fill(palette.color),
    );
  }

  void _ghost(Canvas canvas, Size size) {
    final w = math.min(size.width, size.height * .8);
    final h = w * 1.25;
    final origin = Offset((size.width - w) / 2, (size.height - h) / 2);
    final body = Path()
      ..moveTo(origin.dx, origin.dy + h * .45)
      ..arcToPoint(origin + Offset(w, h * .45), radius: Radius.circular(w / 2))
      ..lineTo(origin.dx + w, origin.dy + h * .92);
    const waves = 4;
    for (var i = waves; i > 0; i--) {
      final x0 = origin.dx + w * i / waves;
      final x1 = origin.dx + w * (i - 1) / waves;
      body.quadraticBezierTo(
        (x0 + x1) / 2,
        origin.dy + h * (i.isEven ? 1.0 : .84),
        x1,
        origin.dy + h * .92,
      );
    }
    body.close();
    final eyes = Path()
      ..addOval(
        Rect.fromCenter(
          center: origin + Offset(w * .36, h * .4),
          width: w * .1,
          height: w * .15,
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: origin + Offset(w * .64, h * .4),
          width: w * .1,
          height: w * .15,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, body, eyes),
      _fill(palette.color),
    );
  }

  /// Fills below a gentle wave so a band's straight edge never cuts the
  /// stroke; the accent line follows the crest at a constant width.
  void _wave(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final amplitude = h * .28;
    final wavelength = math.max(h * 4, w / 4);
    Path crest() {
      final path = Path()..moveTo(0, h * .45);
      for (var x = 0.0; x <= w + 1; x += 2) {
        path.lineTo(
          x,
          h * .45 + math.sin(x / wavelength * 2 * math.pi) * amplitude,
        );
      }
      return path;
    }

    final fill = crest()
      ..lineTo(w, 0)
      ..lineTo(0, 0)
      ..close();
    canvas
      ..drawPath(fill, _fill(palette.color))
      ..drawPath(crest(), _stroke(palette.accent, math.max(1.5, h * .08)));
  }

  /// Diamonds keep their shape and repeat across the band, inset from the
  /// ends so print trimming doesn't cut one in half.
  void _weave(Canvas canvas, Size size) {
    final h = size.height * .78;
    final dw = h * 1.15;
    final count = math.max(1, (size.width / dw).floor());
    final spare = size.width - count * dw;
    final top = (size.height - h) / 2;
    for (var i = 0; i < count; i++) {
      final left = spare / 2 + i * dw;
      final path = Path()
        ..moveTo(left + dw / 2, top)
        ..lineTo(left + dw, top + h / 2)
        ..lineTo(left + dw / 2, top + h)
        ..lineTo(left, top + h / 2)
        ..close();
      final color = i.isEven ? palette.color : palette.accent;
      canvas.drawPath(
        path,
        _fill(color.withValues(alpha: color.a * (i.isEven ? .9 : .55))),
      );
    }
  }

  void _stars(Canvas canvas, Size size) {
    final random = math.Random(palette.seed);
    final count = (size.width * size.height / 900).clamp(24, 160).round();
    final unit = size.shortestSide;
    for (var i = 0; i < count; i++) {
      final p = Offset(random.nextDouble(), random.nextDouble());
      final r = (unit * (.003 + random.nextDouble() * .008)).clamp(.6, 3.0);
      final alpha = .35 + random.nextDouble() * .65;
      if (palette.avoid?.contains(p) ?? false) continue;
      final color = i % 9 == 0 ? palette.accent : palette.color;
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        r,
        _fill(color.withValues(alpha: color.a * alpha)),
      );
    }
  }

  void _zodiac(Canvas canvas, Size size) {
    final box = _square(size).deflate(size.shortestSide * .04);
    final r = box.width / 2;
    final c = box.center;
    final stroke = math.max(1.0, r * .025);
    canvas
      ..drawCircle(c, r, _stroke(palette.color, stroke))
      ..drawCircle(c, r * .72, _stroke(palette.color, stroke * .6));
    for (var i = 0; i < 12; i++) {
      final angle = i / 12 * 2 * math.pi - math.pi / 2;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final cardinal = i % 3 == 0;
      canvas.drawLine(
        c + dir * r * (cardinal ? .58 : .72),
        c + dir * r,
        _stroke(
          cardinal ? palette.accent : palette.color,
          cardinal ? stroke * 1.6 : stroke,
        ),
      );
      final mid = (i + .5) / 12 * 2 * math.pi - math.pi / 2;
      canvas.drawCircle(
        c + Offset(math.cos(mid), math.sin(mid)) * r * .86,
        stroke * 1.2,
        _fill(palette.color),
      );
    }
    canvas.drawCircle(c, r * .06, _fill(palette.accent));
  }

  void _stupa(Canvas canvas, Size size) {
    final w = math.min(size.width, size.height * .85);
    final h = w / .85;
    final o = Offset((size.width - w) / 2, (size.height - h) / 2);
    final paint = _fill(palette.color);
    Rect r(double l, double t, double width, double height) =>
        Rect.fromLTWH(o.dx + w * l, o.dy + h * t, w * width, h * height);
    canvas
      ..drawRect(r(0, .9, 1, .1), paint)
      ..drawRect(r(.08, .82, .84, .08), paint)
      ..drawRect(r(.16, .75, .68, .07), paint);
    final bell = Path()
      ..moveTo(o.dx + w * .2, o.dy + h * .75)
      ..cubicTo(
        o.dx + w * .2,
        o.dy + h * .5,
        o.dx + w * .38,
        o.dy + h * .42,
        o.dx + w * .5,
        o.dy + h * .4,
      )
      ..cubicTo(
        o.dx + w * .62,
        o.dy + h * .42,
        o.dx + w * .8,
        o.dy + h * .5,
        o.dx + w * .8,
        o.dy + h * .75,
      )
      ..close();
    canvas
      ..drawPath(bell, paint)
      ..drawRect(r(.42, .35, .16, .06), paint);
    final spire = Path()
      ..moveTo(o.dx + w * .44, o.dy + h * .35)
      ..lineTo(o.dx + w * .5, o.dy + h * .06)
      ..lineTo(o.dx + w * .56, o.dy + h * .35)
      ..close();
    canvas
      ..drawPath(spire, paint)
      ..drawCircle(
        Offset(o.dx + w * .5, o.dy + h * .04),
        w * .025,
        _fill(palette.accent),
      );
    for (final t in [.16, .22, .28]) {
      canvas.drawLine(
        Offset(o.dx + w * .45, o.dy + h * t),
        Offset(o.dx + w * .55, o.dy + h * t),
        _stroke(palette.accent, math.max(1, h * .008)),
      );
    }
  }

  /// Rays fan from the box's top-left corner, so the sun sits in the corner
  /// of the canvas when the block is placed there.
  void _sunRays(Canvas canvas, Size size) {
    final reach = size.longestSide;
    for (var i = 0; i < 10; i++) {
      final angle = (i + .5) / 10 * math.pi / 2;
      final long = i.isEven;
      final length = reach * (long ? .95 : .62);
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(angle), math.sin(angle)) * length,
        _stroke(palette.color, size.shortestSide * (long ? .03 : .016)),
      );
    }
    canvas.drawCircle(
      Offset.zero,
      size.shortestSide * .3,
      _fill(palette.accent),
    );
  }

  void _steam(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = math.max(1.2, w * .035);
    final cup = Path()
      ..moveTo(w * .18, h * .62)
      ..lineTo(w * .74, h * .62)
      ..lineTo(w * .68, h * .9)
      ..quadraticBezierTo(w * .46, h * .96, w * .24, h * .9)
      ..close();
    canvas
      ..drawPath(cup, _fill(palette.color))
      ..drawArc(
        Rect.fromCenter(
          center: Offset(w * .76, h * .74),
          width: w * .2,
          height: h * .14,
        ),
        -math.pi / 2,
        math.pi,
        false,
        _stroke(palette.color, stroke),
      )
      ..drawLine(
        Offset(w * .06, h * .97),
        Offset(w * .9, h * .97),
        _stroke(palette.color, stroke),
      );
    for (final (x, alpha) in [(.36, 1.0), (.56, .6)]) {
      final curl = Path()
        ..moveTo(w * x, h * .56)
        ..cubicTo(w * (x - .12), h * .44, w * (x + .12), h * .3, w * x, h * .18)
        ..cubicTo(
          w * (x - .1),
          h * .1,
          w * (x + .04),
          h * .04,
          w * (x + .02),
          0,
        );
      canvas.drawPath(
        curl,
        _stroke(
          palette.accent.withValues(alpha: palette.accent.a * alpha),
          stroke,
        ),
      );
    }
  }

  void _compass(Canvas canvas, Size size) {
    final box = _square(size);
    final c = box.center;
    final r = box.width / 2;
    for (var i = 0; i < 8; i++) {
      final angle = i / 8 * 2 * math.pi - math.pi / 2;
      final length = i.isEven ? r : r * .55;
      final side = r * .14;
      final tip = c + Offset(math.cos(angle), math.sin(angle)) * length;
      final left =
          c +
          Offset(math.cos(angle - math.pi / 2), math.sin(angle - math.pi / 2)) *
              side;
      final right =
          c +
          Offset(math.cos(angle + math.pi / 2), math.sin(angle + math.pi / 2)) *
              side;
      final half = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(tip.dx, tip.dy)
        ..close();
      final other = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(right.dx, right.dy)
        ..lineTo(tip.dx, tip.dy)
        ..close();
      final base = i.isEven ? palette.color : palette.accent;
      canvas
        ..drawPath(half, _fill(base))
        ..drawPath(other, _fill(base.withValues(alpha: base.a * .55)));
    }
    canvas.drawCircle(c, r * .08, _fill(palette.accent));
  }

  @override
  bool shouldRepaint(covariant _DecorationPainter oldDelegate) =>
      kind != oldDelegate.kind || palette != oldDelegate.palette;
}
