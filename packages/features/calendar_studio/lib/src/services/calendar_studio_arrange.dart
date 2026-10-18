import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';

enum CalendarStudioAlign { left, centerX, right, top, centerY, bottom }

enum CalendarStudioDistribute { horizontal, vertical }

/// Align and distribute maths on normalized bounds. Pure, so the controller
/// and tests share it.
abstract final class CalendarStudioArrange {
  /// The smallest rect holding every block; the page when there are none.
  static StudioRect boundsOf(Iterable<CalendarStudioBlock> blocks) {
    var left = double.infinity, top = double.infinity;
    var right = -double.infinity, bottom = -double.infinity;
    for (final b in blocks) {
      final r = b.bounds;
      if (r.left < left) left = r.left;
      if (r.top < top) top = r.top;
      if (r.left + r.width > right) right = r.left + r.width;
      if (r.top + r.height > bottom) bottom = r.top + r.height;
    }
    if (left == double.infinity) return _page;
    return StudioRect(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    );
  }

  static const _page = StudioRect(left: 0, top: 0, width: 1, height: 1);

  /// [blocks] aligned to each other, or to the page when there is only one.
  /// Locked blocks don't move but still count as the reference.
  static List<CalendarStudioBlock> align(
    List<CalendarStudioBlock> blocks,
    CalendarStudioAlign edge,
  ) {
    final target = blocks.length == 1 ? _page : boundsOf(blocks);
    return [
      for (final b in blocks)
        if (b.locked)
          b
        else
          b.copyWith(bounds: _aligned(b.bounds, target, edge)),
    ];
  }

  static StudioRect _aligned(
    StudioRect r,
    StudioRect t,
    CalendarStudioAlign edge,
  ) => switch (edge) {
    CalendarStudioAlign.left => r.copyWith(left: t.left),
    CalendarStudioAlign.centerX => r.copyWith(
      left: t.left + (t.width - r.width) / 2,
    ),
    CalendarStudioAlign.right => r.copyWith(left: t.left + t.width - r.width),
    CalendarStudioAlign.top => r.copyWith(top: t.top),
    CalendarStudioAlign.centerY => r.copyWith(
      top: t.top + (t.height - r.height) / 2,
    ),
    CalendarStudioAlign.bottom => r.copyWith(top: t.top + t.height - r.height),
  };

  /// Equal gaps between [blocks] along [axis], keeping the first and last in
  /// place. Needs three or more; fewer come back unchanged.
  static List<CalendarStudioBlock> distribute(
    List<CalendarStudioBlock> blocks,
    CalendarStudioDistribute axis,
  ) {
    if (blocks.length < 3) return blocks;
    final horizontal = axis == CalendarStudioDistribute.horizontal;
    double start(StudioRect r) => horizontal ? r.left : r.top;
    double size(StudioRect r) => horizontal ? r.width : r.height;
    final sorted = [...blocks]
      ..sort((a, b) => start(a.bounds).compareTo(start(b.bounds)));
    final first = sorted.first.bounds, last = sorted.last.bounds;
    final span = start(last) + size(last) - start(first);
    final used = sorted.fold<double>(0, (sum, b) => sum + size(b.bounds));
    final gap = (span - used) / (sorted.length - 1);
    final moved = <String, CalendarStudioBlock>{};
    var cursor = start(first);
    for (final b in sorted) {
      final r = b.bounds;
      moved[b.id] = b.locked
          ? b
          : b.copyWith(
              bounds: horizontal
                  ? r.copyWith(left: cursor)
                  : r.copyWith(top: cursor),
            );
      cursor += size(r) + gap;
    }
    return [for (final b in blocks) moved[b.id]!];
  }
}
