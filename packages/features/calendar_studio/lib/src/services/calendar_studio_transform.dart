import 'dart:math' as math;
import 'dart:ui';

import '../models/calendar_studio_types.dart';

/// An alignment line shown while a block snaps to it, in normalised page
/// units (0..1) along [axis]: vertical lines carry an x, horizontal a y.
class StudioGuide {
  const StudioGuide.vertical(this.position) : axis = StudioGuideAxis.vertical;
  const StudioGuide.horizontal(this.position)
    : axis = StudioGuideAxis.horizontal;

  final StudioGuideAxis axis;
  final double position;

  @override
  bool operator ==(Object other) =>
      other is StudioGuide &&
      other.axis == axis &&
      (other.position - position).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(axis, (position * 1e6).round());
}

enum StudioGuideAxis { vertical, horizontal }

class StudioSnapResult {
  const StudioSnapResult(this.bounds, [this.guides = const []]);
  final StudioRect bounds;
  final List<StudioGuide> guides;
}

/// Pure geometry for moving, resizing, rotating and snapping blocks.
///
/// Every function takes the bounds captured when the gesture started plus the
/// total pointer travel in design pixels, so snapping never feeds back into
/// the next frame and slow drags cannot stall.
abstract final class CalendarStudioTransform {
  static const minWidth = .06;
  static const minHeight = .04;
  static const gridStep = .01;
  static const rotationStep = math.pi / 12; // 15°
  static const rotationTolerance = math.pi / 60; // 3°

  /// Moves without touching the size, so callers can tell a move from a
  /// resize by comparing dimensions with the start bounds.
  static StudioRect move(StudioRect start, Offset delta, Size design) =>
      start.copyWith(
        left: (start.left + delta.dx / design.width)
            .clamp(0, 1 - start.width)
            .toDouble(),
        top: (start.top + delta.dy / design.height)
            .clamp(0, 1 - start.height)
            .toDouble(),
      );

  /// Resizes from handle ([handleX], [handleY] in {0, .5, 1}) by [delta],
  /// measured along the block's own rotated axes so the opposite edge stays
  /// anchored on screen.
  static StudioRect resize(
    StudioRect start, {
    required double handleX,
    required double handleY,
    required Offset delta,
    required double rotation,
    required Size design,
  }) {
    final rect = start.resolve(design);
    final cos = math.cos(rotation);
    final sin = math.sin(rotation);
    final localX = delta.dx * cos + delta.dy * sin;
    final localY = -delta.dx * sin + delta.dy * cos;
    final signX = _sign(handleX);
    final signY = _sign(handleY);
    final minW = minWidth * design.width;
    final minH = minHeight * design.height;
    // Unrotated blocks keep the dragged edge inside the page.
    final maxW = rotation == 0
        ? (signX < 0 ? rect.right : design.width - rect.left)
        : double.infinity;
    final maxH = rotation == 0
        ? (signY < 0 ? rect.bottom : design.height - rect.top)
        : double.infinity;
    final width = signX == 0
        ? rect.width
        : (rect.width + signX * localX)
              .clamp(minW, math.max(minW, maxW))
              .toDouble();
    final height = signY == 0
        ? rect.height
        : (rect.height + signY * localY)
              .clamp(minH, math.max(minH, maxH))
              .toDouble();
    final shiftX = signX * (width - rect.width) / 2;
    final shiftY = signY * (height - rect.height) / 2;
    final center =
        rect.center +
        Offset(shiftX * cos - shiftY * sin, shiftX * sin + shiftY * cos);
    return _clampToPage(
      Rect.fromCenter(center: center, width: width, height: height),
      design,
    );
  }

  /// Angle for a rotate handle that sits above the block's top edge.
  static double rotationFor(Offset center, Offset pointer) => normalizeAngle(
    math.atan2(pointer.dy - center.dy, pointer.dx - center.dx) + math.pi / 2,
  );

  /// Snaps to 15° steps when within 3°.
  static double snapRotation(double angle) {
    final nearest = (angle / rotationStep).round() * rotationStep;
    return (angle - nearest).abs() <= rotationTolerance
        ? normalizeAngle(nearest)
        : angle;
  }

  static double normalizeAngle(double angle) {
    var value = angle % (2 * math.pi);
    if (value > math.pi) value -= 2 * math.pi;
    if (value <= -math.pi) value += 2 * math.pi;
    return value.abs() < 1e-9 ? 0 : value;
  }

  /// Snaps a moving block's edges and centre to the page centre and edges,
  /// the safe area, and other blocks; falls back to the grid when enabled.
  static StudioSnapResult snapMove(
    StudioRect raw, {
    required Iterable<StudioRect> others,
    required Size design,
    double safeInset = 0,
    bool grid = false,
    double thresholdPx = 6,
  }) {
    final safeY = safeInset * design.width / design.height;
    final xTargets = <double>[
      0,
      .5,
      1,
      if (safeInset > 0) ...[safeInset, 1 - safeInset],
    ];
    final yTargets = <double>[
      0,
      .5,
      1,
      if (safeInset > 0) ...[safeY, 1 - safeY],
    ];
    for (final other in others) {
      xTargets.addAll([other.left, other.left + other.width / 2, other.right]);
      yTargets.addAll([other.top, other.top + other.height / 2, other.bottom]);
    }
    final x = _nearest(
      [raw.left, raw.left + raw.width / 2, raw.right],
      xTargets,
      thresholdPx / design.width,
    );
    final y = _nearest(
      [raw.top, raw.top + raw.height / 2, raw.bottom],
      yTargets,
      thresholdPx / design.height,
    );
    var left = raw.left;
    var top = raw.top;
    final guides = <StudioGuide>[];
    if (x != null) {
      left += x.shift;
      guides.add(StudioGuide.vertical(x.target));
    } else if (grid) {
      left = _roundToGrid(left);
    }
    if (y != null) {
      top += y.shift;
      guides.add(StudioGuide.horizontal(y.target));
    } else if (grid) {
      top = _roundToGrid(top);
    }
    return StudioSnapResult(
      StudioRect(
        left: left.clamp(0, 1 - raw.width),
        top: top.clamp(0, 1 - raw.height),
        width: raw.width,
        height: raw.height,
      ),
      guides,
    );
  }

  /// Rounds only the edges a resize actually moved, so untouched edges of
  /// off-grid template blocks never jump.
  static StudioRect snapResizeToGrid(StudioRect start, StudioRect raw) {
    var left = raw.left;
    var top = raw.top;
    var right = raw.right;
    var bottom = raw.bottom;
    if ((left - start.left).abs() > 1e-9) left = _roundToGrid(left);
    if ((top - start.top).abs() > 1e-9) top = _roundToGrid(top);
    if ((right - start.right).abs() > 1e-9) right = _roundToGrid(right);
    if ((bottom - start.bottom).abs() > 1e-9) bottom = _roundToGrid(bottom);
    if (right - left < minWidth || bottom - top < minHeight) return raw;
    return StudioRect(
      left: left.clamp(0, 1),
      top: top.clamp(0, 1),
      width: right.clamp(0, 1) - left.clamp(0, 1),
      height: bottom.clamp(0, 1) - top.clamp(0, 1),
    );
  }

  static int _sign(double handle) => handle == 0
      ? -1
      : handle == 1
      ? 1
      : 0;

  static double _roundToGrid(double value) =>
      ((value / gridStep).round() * gridStep).clamp(0, 1);

  static ({double shift, double target})? _nearest(
    List<double> anchors,
    List<double> targets,
    double threshold,
  ) {
    ({double shift, double target})? best;
    for (final anchor in anchors) {
      for (final target in targets) {
        final shift = target - anchor;
        if (shift.abs() <= threshold &&
            (best == null || shift.abs() < best.shift.abs())) {
          best = (shift: shift, target: target);
        }
      }
    }
    return best;
  }

  static StudioRect _clampToPage(Rect rect, Size design) {
    final width = math.min(rect.width, design.width);
    final height = math.min(rect.height, design.height);
    final left = rect.left.clamp(0, design.width - width);
    final top = rect.top.clamp(0, design.height - height);
    return StudioRect(
      left: left / design.width,
      top: top / design.height,
      width: width / design.width,
      height: height / design.height,
    );
  }
}
