import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart'
    show DragStartBehavior, PointerDeviceKind, kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart'
    show TranslationService;
import 'package:shared_moon/shared_moon.dart';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../services/calendar_studio_cache.dart';
import '../services/calendar_studio_contracts.dart';
import '../templates/calendar_studio_bindings.dart';
import '../services/calendar_studio_transform.dart';
import '../theme/calendar_studio_font_catalog.dart';
import 'calendar_studio_decorations.dart';
import 'calendar_studio_theme_blocks.dart';

/// The single Flutter render path for editable canvases and page previews.
class CalendarStudioScene extends StatelessWidget {
  const CalendarStudioScene({
    required this.page,
    required this.source,
    this.selectedBlockId,
    this.selectedBlockIds = const {},
    this.showSafeArea = false,
    this.onSelect,
    this.dataProvider,
    this.assetStore,
    this.resolvedDays,
    this.resolvedDaysByMonth = const {},
    this.resolvedAssets = const {},
    this.resolvedImages = const {},
    this.onTransform,
    this.onTransformStart,
    this.onTransformEnd,
    this.onDuplicate,
    this.onToggleLock,
    this.onToggleVisibility,
    this.onMove,
    this.onDelete,
    this.guides = const [],
    this.displayWidth,
    this.onToggleSelect,
    this.onGroupMove,
    this.onMarquee,
    this.editingBlockId,
    this.onTextChanged,
    this.onTextDone,
    super.key,
  });
  final CalendarStudioPage page;
  final CalendarStudioSource source;
  final String? selectedBlockId;

  /// Every selected block when several are; [selectedBlockId] is the one
  /// with handles.
  final Set<String> selectedBlockIds;
  final bool showSafeArea;
  final ValueChanged<CalendarStudioBlock?>? onSelect;
  final CalendarStudioDataProvider? dataProvider;
  final CalendarStudioAssetStore? assetStore;
  final List<CalendarStudioDayData>? resolvedDays;
  final Map<int, List<CalendarStudioDayData>> resolvedDaysByMonth;
  final Map<String, Uint8List> resolvedAssets;

  /// Decoded images by asset id, drawn at once (export). The scene borrows
  /// them; the caller disposes them.
  final Map<String, ui.Image> resolvedImages;
  final ValueChanged<CalendarStudioBlock>? onTransform;
  final VoidCallback? onTransformStart;
  final VoidCallback? onTransformEnd;
  final VoidCallback? onDuplicate;
  final VoidCallback? onToggleLock;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;

  /// Smart-guide lines to draw while a block snaps to them.
  final List<StudioGuide> guides;

  /// The page's width on screen, when the caller knows it (thumbnails).
  /// Photos then decode near that size instead of the full page size.
  final double? displayWidth;

  /// Shift/Ctrl/Cmd-click or long-press: add or remove a block from the
  /// selection.
  final ValueChanged<CalendarStudioBlock>? onToggleSelect;

  /// Dragging one of several selected blocks: the pointer's travel in
  /// design pixels since the drag began.
  final ValueChanged<Offset>? onGroupMove;

  /// A mouse drag across the page, as a rect in page fractions.
  final ValueChanged<Rect>? onMarquee;

  /// The text block being typed into on the page.
  final String? editingBlockId;
  final ValueChanged<String>? onTextChanged;
  final VoidCallback? onTextDone;

  static const double designWidth = 595;

  static Size designSizeFor(StudioCanvas canvas) {
    final ratio = canvas.aspectRatio;
    if ((ratio - 1).abs() < .01) return const Size(600, 600);
    if ((ratio - 9 / 16).abs() < .01) return const Size(360, 640);
    if (ratio > 1) return const Size(842, 595);
    return const Size(595, 842);
  }

  @override
  Widget build(BuildContext context) {
    final blocks = [...page.blocks]
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final designSize = designSizeFor(page.canvas);
    final scene = _scene(context, designSize, blocks);
    final width = displayWidth;
    // How big one design unit is on screen; photos decode to match.
    return width == null
        ? scene
        : _SceneScale(scale: width / designSize.width, child: scene);
  }

  Widget _scene(
    BuildContext context,
    Size designSize,
    List<CalendarStudioBlock> blocks,
  ) {
    return AspectRatio(
      aspectRatio: page.canvas.aspectRatio,
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox.fromSize(
          size: designSize,
          child: _DesignSpace(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSelect == null ? null : () => onSelect!(null),
              child: _Marquee(
                onMarquee: onMarquee,
                designSize: designSize,
                blocked: (point) => _onSelection(point, designSize),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(page.canvas.backgroundColor),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final block in blocks)
                        if (block.visible)
                          _buildBlock(context, designSize, block),
                      if (showSafeArea)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Padding(
                              padding: EdgeInsets.all(
                                designSize.width * page.canvas.safeInset,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: .75),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (guides.isNotEmpty)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _GuidePainter(
                                guides,
                                const Color(0xFFD6336C),
                              ),
                            ),
                          ),
                        ),
                      if (page.canvas.bleed > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFA96300),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(
    BuildContext context,
    Size size,
    CalendarStudioBlock block,
  ) {
    final interactive = onSelect != null || onTransform != null;
    final multi = selectedBlockIds.length > 1;
    final selected = selectedBlockId == block.id;
    final inGroup = multi && selectedBlockIds.contains(block.id);
    final editing = editingBlockId == block.id;
    final editable =
        selected && !multi && !editing && !block.locked && onTransform != null;
    final groupDrag = inGroup && !block.locked && onGroupMove != null;
    final rect = block.bounds.resolve(size);
    final contents = editing
        ? CalendarStudioInlineText(
            key: ValueKey('calendar-studio-inline-text-${block.id}'),
            block: block,
            onChanged: onTextChanged,
            onDone: onTextDone,
          )
        : _contents(block);
    final body = _DesignDrag(
      key: ValueKey('calendar-studio-block-${block.id}'),
      value: block,
      enabled: editable || groupDrag,
      onStart: onTransformStart,
      onUpdate: groupDrag
          ? (start, from, to) => onGroupMove!(to - from)
          : (start, from, to) => onTransform?.call(
              start.copyWith(
                bounds: CalendarStudioTransform.move(
                  start.bounds,
                  to - from,
                  size,
                ),
              ),
            ),
      onEnd: onTransformEnd,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: editing ? null : () => _tap(block),
        onLongPress: onToggleSelect == null || editing
            ? null
            : () => onToggleSelect!(block),
        child: Transform.rotate(
          angle: block.rotation,
          child: interactive
              // Static content keeps its own layer, so moving a block or
              // its selection chrome never repaints it.
              ? RepaintBoundary(child: contents)
              : contents,
        ),
      ),
    );
    if (!interactive) {
      return Positioned(
        key: ValueKey('calendar-studio-layer-${block.id}'),
        left: rect.left,
        top: rect.top,
        width: rect.width,
        height: rect.height,
        child: body,
      );
    }
    // Interactive blocks reserve a margin for handles and quick actions so
    // they receive hits outside the block; empty margin stays transparent.
    const margin = _chromeMargin;
    return Positioned(
      key: ValueKey('calendar-studio-layer-${block.id}'),
      left: rect.left - margin,
      top: rect.top - margin,
      width: rect.width + margin * 2,
      height: rect.height + margin * 2,
      child: RepaintBoundary(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(margin),
                child: body,
              ),
            ),
            if (selected && !multi)
              _chrome(context, size, block, rect, editable)
            else if (inGroup)
              _outline(context, block, rect),
          ],
        ),
      ),
    );
  }

  void _tap(CalendarStudioBlock block) {
    final keys = HardwareKeyboard.instance;
    if (onToggleSelect != null &&
        (keys.isShiftPressed || keys.isMetaPressed || keys.isControlPressed)) {
      onToggleSelect!(block);
    } else {
      onSelect?.call(block);
    }
  }

  /// Whether [point] (design pixels) is on a selected block or its
  /// handles, where a drag moves the block instead of starting a marquee.
  bool _onSelection(Offset point, Size size) {
    for (final block in page.blocks) {
      if (!block.visible) continue;
      final primary = block.id == selectedBlockId;
      if (!primary && !selectedBlockIds.contains(block.id)) continue;
      if (block.bounds
          .resolve(size)
          .inflate(primary ? 48 : 0)
          .contains(point)) {
        return true;
      }
    }
    return false;
  }

  /// A thinner outline for blocks in a multiple selection.
  Widget _outline(BuildContext context, CalendarStudioBlock block, Rect rect) =>
      Positioned(
        left: _chromeMargin,
        top: _chromeMargin,
        width: rect.width,
        height: rect.height,
        child: IgnorePointer(
          child: Transform.rotate(
            angle: block.rotation,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _chrome(
    BuildContext context,
    Size size,
    CalendarStudioBlock block,
    Rect rect,
    bool editable,
  ) {
    const margin = _chromeMargin;
    final color = Theme.of(context).colorScheme.primary;
    final width = rect.width;
    final height = rect.height;
    return Positioned.fill(
      child: Transform.rotate(
        angle: block.rotation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: margin,
              top: margin,
              width: width,
              height: height,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: 2),
                  ),
                ),
              ),
            ),
            if (editable) ...[
              Positioned(
                left: margin + width / 2 - 1,
                top: margin - 26,
                width: 2,
                height: 26,
                child: IgnorePointer(child: ColoredBox(color: color)),
              ),
              Positioned(
                left: margin + width / 2 - 14,
                top: margin - 42,
                width: 28,
                height: 28,
                child: _handle(
                  key: const ValueKey('calendar-studio-rotate'),
                  block: block,
                  cursor: SystemMouseCursors.grab,
                  onUpdate: (start, from, to) => onTransform!(
                    start.copyWith(
                      rotation: CalendarStudioTransform.rotationFor(
                        start.bounds.resolve(size).center,
                        to,
                      ),
                    ),
                  ),
                  child: _HandleDot(
                    color: color,
                    size: 22,
                    icon: Icons.rotate_right,
                  ),
                ),
              ),
              for (final handle in _ResizeHandle.values)
                Positioned(
                  left: margin + handle.x * width - 11,
                  top: margin + handle.y * height - 11,
                  width: 22,
                  height: 22,
                  child: _handle(
                    key: ValueKey('calendar-studio-resize-${handle.name}'),
                    block: block,
                    cursor: handle.cursor,
                    onUpdate: (start, from, to) => onTransform!(
                      start.copyWith(
                        bounds: CalendarStudioTransform.resize(
                          start.bounds,
                          handleX: handle.x,
                          handleY: handle.y,
                          delta: to - from,
                          rotation: start.rotation,
                          design: size,
                        ),
                      ),
                    ),
                    child: _HandleDot(color: color, size: 12),
                  ),
                ),
            ],
            if (onDuplicate != null)
              Positioned(
                left: 0,
                right: 0,
                top: margin + height + 8,
                height: 48,
                child: Center(
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    child: _SelectionActions(
                      locked: block.locked,
                      visible: block.visible,
                      onDuplicate: onDuplicate!,
                      onToggleLock: onToggleLock!,
                      onToggleVisibility: onToggleVisibility!,
                      onMove: onMove,
                      onDelete: onDelete!,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _handle({
    required Key key,
    required CalendarStudioBlock block,
    required MouseCursor cursor,
    required _DesignDragUpdate onUpdate,
    required Widget child,
  }) => MouseRegion(
    cursor: cursor,
    // Wins the tap arena so pressing a handle never deselects the block.
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: _DesignDrag(
        key: key,
        value: block,
        enabled: true,
        onStart: onTransformStart,
        onUpdate: onUpdate,
        onEnd: onTransformEnd,
        child: Center(child: child),
      ),
    ),
  );

  Widget _contents(CalendarStudioBlock block) => switch (block.type) {
    CalendarStudioBlockType.calendarGrid => _CalendarGrid(
      block: block,
      source: source.copyWith(year: page.year, month: page.month),
      dataProvider: dataProvider,
      resolvedDays: _resolvedDaysFor(block),
    ),
    CalendarStudioBlockType.text => _TextBlock(block: block),
    CalendarStudioBlockType.shape => _ShapeBlock(block: block),
    CalendarStudioBlockType.image || CalendarStudioBlockType.logo => _framed(
      block,
      _AssetImageBlock(
        assetId: block.content['assetId'] as String?,
        assetStore: assetStore,
        resolvedBytes: resolvedAssets[block.content['assetId']],
        resolvedImage: resolvedImages[block.content['assetId']],
        fit: switch (block.style['imageFit'] as String? ?? 'crop') {
          'fill' => BoxFit.fill,
          'fit' => BoxFit.contain,
          _ => BoxFit.cover,
        },
        opacity: (block.style['opacity'] as num?)?.toDouble() ?? 1,
      ),
    ),
    CalendarStudioBlockType.eventList =>
      block.content.containsKey('title') ||
              block.content.containsKey('placeholder') ||
              block.content['kind'] == 'notes'
          ? StudioEventList(
              block: block,
              source: source.copyWith(year: page.year, month: page.month),
              dataProvider: dataProvider,
              resolvedDays: _resolvedDaysFor(block),
            )
          : const _ListBlock(icon: Icons.event_outlined, label: 'My events'),
    CalendarStudioBlockType.holidayLegend =>
      block.content['kind'] == 'themed'
          ? StudioThemedLegend(
              block: block,
              source: source.copyWith(year: page.year, month: page.month),
            )
          : _TemplateLegend(block: block),
    CalendarStudioBlockType.decoration => _TemplateDecoration(block: block),
  };

  /// Rounded corners and a border for images (`cornerRadius`,
  /// `borderWidth`, `borderColor`, in design pixels).
  static Widget _framed(CalendarStudioBlock block, Widget image) {
    final radius = (block.style['cornerRadius'] as num?)?.toDouble() ?? 0;
    final border = (block.style['borderWidth'] as num?)?.toDouble() ?? 0;
    if (radius <= 0 && border <= 0) return image;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: shape,
        border: border <= 0
            ? null
            : Border.all(
                color:
                    _color(block.style['borderColor']) ??
                    const Color(0xFFFFFFFF),
                width: border,
              ),
      ),
      child: ClipRRect(borderRadius: shape, child: image),
    );
  }

  List<CalendarStudioDayData>? _resolvedDaysFor(CalendarStudioBlock block) {
    final month = block.content['month'] as int? ?? page.month;
    return resolvedDaysByMonth[month] ??
        (month == page.month ? resolvedDays : null);
  }
}

typedef _DesignDragUpdate =
    void Function(CalendarStudioBlock start, Offset from, Offset to);

const double _chromeMargin = 64;

/// Pointer tracking in page design pixels. Positions are mapped through the
/// page box, so the result is correct at any zoom or fitted scale, and every
/// update is measured from the gesture's start rather than accumulated.
/// A mouse drag across empty page draws a selection rectangle. Touch keeps
/// its pan and zoom; there, long-press adds blocks to the selection.
class _Marquee extends StatefulWidget {
  const _Marquee({
    required this.onMarquee,
    required this.designSize,
    required this.blocked,
    required this.child,
  });
  final ValueChanged<Rect>? onMarquee;
  final Size designSize;
  final bool Function(Offset point) blocked;
  final Widget child;

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> {
  Offset? _from;
  Offset? _to;

  @override
  Widget build(BuildContext context) {
    final onMarquee = widget.onMarquee;
    if (onMarquee == null) return widget.child;
    final from = _from, to = _to;
    return GestureDetector(
      supportedDevices: const {PointerDeviceKind.mouse},
      // The rectangle starts where the button went down, not after slop.
      dragStartBehavior: DragStartBehavior.down,
      onPanStart: (details) {
        if (widget.blocked(details.localPosition)) return;
        setState(() => _from = _to = details.localPosition);
      },
      onPanUpdate: (details) {
        if (_from != null) setState(() => _to = details.localPosition);
      },
      onPanEnd: (_) {
        final a = _from, b = _to;
        setState(() => _from = _to = null);
        if (a == null || b == null || (a - b).distance < 4) return;
        final size = widget.designSize;
        final r = Rect.fromPoints(a, b);
        onMarquee(
          Rect.fromLTRB(
            r.left / size.width,
            r.top / size.height,
            r.right / size.width,
            r.bottom / size.height,
          ),
        );
      },
      onPanCancel: () => setState(() => _from = _to = null),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (from != null && to != null)
            Positioned.fromRect(
              key: const ValueKey('calendar-studio-marquee'),
              rect: Rect.fromPoints(from, to),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .08),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DesignDrag extends StatefulWidget {
  const _DesignDrag({
    required this.value,
    required this.enabled,
    required this.onUpdate,
    required this.child,
    this.onStart,
    this.onEnd,
    super.key,
  });
  final CalendarStudioBlock value;
  final bool enabled;
  final _DesignDragUpdate onUpdate;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final Widget child;

  @override
  State<_DesignDrag> createState() => _DesignDragState();
}

class _DesignDragState extends State<_DesignDrag> {
  int? _pointer;
  Offset _downPosition = Offset.zero;
  double _slop = kTouchSlop;
  CalendarStudioBlock? _start;
  Offset? _from;
  var _active = false;

  void _down(PointerDownEvent event) {
    if (!widget.enabled || _pointer != null) return;
    _pointer = event.pointer;
    _downPosition = event.position;
    _slop = event.kind == PointerDeviceKind.mouse ? 1 : kTouchSlop;
    _start = widget.value;
    _from = _DesignSpace.toDesign(context, event.position);
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    final start = _start;
    final from = _from;
    if (start == null || from == null) return;
    if (!_active) {
      if ((event.position - _downPosition).distance < _slop) return;
      _active = true;
      widget.onStart?.call();
    }
    final to = _DesignSpace.toDesign(context, event.position);
    if (to != null) widget.onUpdate(start, from, to);
  }

  void _finish(PointerEvent event) {
    if (event.pointer != _pointer) return;
    final wasActive = _active;
    _pointer = null;
    _start = null;
    _from = null;
    _active = false;
    if (wasActive) widget.onEnd?.call();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: _down,
    onPointerMove: _move,
    onPointerUp: _finish,
    onPointerCancel: _finish,
    child: widget.child,
  );
}

/// Marks the page's design-size box so descendants can map global pointer
/// positions into design pixels.
/// The on-screen size of one design unit for the scene below.
class _SceneScale extends InheritedWidget {
  const _SceneScale({required this.scale, required super.child});
  final double scale;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SceneScale>()?.scale ?? 1;

  @override
  bool updateShouldNotify(_SceneScale oldWidget) => scale != oldWidget.scale;
}

class _DesignSpace extends StatelessWidget {
  const _DesignSpace({required this.child});
  final Widget child;

  static Offset? toDesign(BuildContext context, Offset global) {
    final scope = context.getInheritedWidgetOfExactType<_DesignSpaceScope>();
    final box = scope?.anchor.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.globalToLocal(global);
  }

  @override
  Widget build(BuildContext context) =>
      _DesignSpaceScope(anchor: context, child: child);
}

class _DesignSpaceScope extends InheritedWidget {
  const _DesignSpaceScope({required this.anchor, required super.child});
  final BuildContext anchor;

  @override
  bool updateShouldNotify(_DesignSpaceScope oldWidget) => false;
}

class _HandleDot extends StatelessWidget {
  const _HandleDot({required this.color, required this.size, this.icon});
  final Color color;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 2),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3)],
    ),
    child: icon == null ? null : Icon(icon, size: size * .62, color: color),
  );
}

class _GuidePainter extends CustomPainter {
  const _GuidePainter(this.guides, this.color);
  final List<StudioGuide> guides;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (final guide in guides) {
      if (guide.axis == StudioGuideAxis.vertical) {
        final x = guide.position * size.width;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      } else {
        final y = guide.position * size.height;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter oldDelegate) =>
      !listEquals(guides, oldDelegate.guides) || color != oldDelegate.color;
}

class _ShapeBlock extends StatelessWidget {
  const _ShapeBlock({required this.block});
  final CalendarStudioBlock block;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ShapePainter(
      shape: block.content['shape'] as String? ?? 'rectangle',
      color: Color((block.style['color'] as int?) ?? 0xFF0E6B5C),
      strokeColor: Color((block.style['strokeColor'] as int?) ?? 0xFF15201D),
      strokeWidth: (block.style['strokeWidth'] as num?)?.toDouble() ?? 0,
      opacity: (block.style['opacity'] as num?)?.toDouble() ?? 1,
      filled: block.style['fill'] != 'none',
    ),
  );
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter({
    required this.shape,
    required this.color,
    required this.strokeColor,
    required this.strokeWidth,
    required this.opacity,
    this.filled = true,
  });

  /// False draws only the outline (e.g. a planet ring or stamp).
  final bool filled;
  final String shape;
  final Color color;
  final Color strokeColor;
  final double strokeWidth;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect =
        Offset(inset, inset) &
        Size(
          (size.width - strokeWidth).clamp(0, double.infinity),
          (size.height - strokeWidth).clamp(0, double.infinity),
        );
    final path = switch (shape) {
      'circle' || 'oval' => Path()..addOval(rect),
      'rounded' =>
        Path()..addRRect(
          RRect.fromRectAndRadius(
            rect,
            Radius.circular(size.shortestSide * .18),
          ),
        ),
      'triangle' =>
        Path()
          ..moveTo(size.width / 2, inset)
          ..lineTo(size.width - inset, size.height - inset)
          ..lineTo(inset, size.height - inset)
          ..close(),
      'diamond' =>
        Path()
          ..moveTo(size.width / 2, inset)
          ..lineTo(size.width - inset, size.height / 2)
          ..lineTo(size.width / 2, size.height - inset)
          ..lineTo(inset, size.height / 2)
          ..close(),
      'pentagon' => _polygonPath(size, inset, 5),
      'hexagon' =>
        Path()
          ..moveTo(size.width * .25, inset)
          ..lineTo(size.width * .75, inset)
          ..lineTo(size.width - inset, size.height / 2)
          ..lineTo(size.width * .75, size.height - inset)
          ..lineTo(size.width * .25, size.height - inset)
          ..lineTo(inset, size.height / 2)
          ..close(),
      'octagon' => _polygonPath(size, inset, 8),
      'star' => _starPath(size, inset),
      'heart' => _heartPath(size, inset),
      'arrow' => _arrowPath(size, inset),
      'line' =>
        Path()
          ..moveTo(inset, size.height / 2)
          ..lineTo(size.width - inset, size.height / 2),
      _ => Path()..addRect(rect),
    };
    final fill = Paint()
      ..color = color.withValues(alpha: opacity.clamp(0, 1))
      ..style = shape == 'line' ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = shape == 'line' ? (strokeWidth > 0 ? strokeWidth : 4) : 0
      ..strokeCap = StrokeCap.round;
    if (filled || shape == 'line') canvas.drawPath(path, fill);
    if (strokeWidth > 0 && shape != 'line') {
      canvas.drawPath(
        path,
        Paint()
          ..color = strokeColor.withValues(alpha: opacity.clamp(0, 1))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }

  static Path _starPath(Size size, double inset) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - inset;
    final inner = outer * .45;
    final path = Path();
    for (var index = 0; index < 10; index++) {
      final radius = index.isEven ? outer : inner;
      final angle = -1.5707963267948966 + index * 0.6283185307179586;
      final point = center + Offset(radius * cos(angle), radius * sin(angle));
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  static Path _polygonPath(Size size, double inset, int sides) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - inset;
    final path = Path();
    for (var index = 0; index < sides; index++) {
      final angle = -pi / 2 + index * (2 * pi / sides);
      final point = center + Offset(radius * cos(angle), radius * sin(angle));
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  static Path _heartPath(Size size, double inset) => Path()
    ..moveTo(size.width / 2, size.height - inset)
    ..cubicTo(
      inset,
      size.height * .68,
      inset,
      size.height * .22,
      size.width * .28,
      size.height * .22,
    )
    ..cubicTo(
      size.width * .42,
      size.height * .22,
      size.width * .5,
      size.height * .34,
      size.width / 2,
      size.height * .34,
    )
    ..cubicTo(
      size.width * .58,
      size.height * .22,
      size.width - inset,
      size.height * .22,
      size.width - inset,
      size.height * .5,
    )
    ..cubicTo(
      size.width - inset,
      size.height * .68,
      size.width * .7,
      size.height * .88,
      size.width / 2,
      size.height - inset,
    )
    ..close();

  static Path _arrowPath(Size size, double inset) => Path()
    ..moveTo(inset, size.height * .35)
    ..lineTo(size.width * .58, size.height * .35)
    ..lineTo(size.width * .58, inset)
    ..lineTo(size.width - inset, size.height / 2)
    ..lineTo(size.width * .58, size.height - inset)
    ..lineTo(size.width * .58, size.height * .65)
    ..lineTo(inset, size.height * .65)
    ..close();

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) =>
      shape != oldDelegate.shape ||
      color != oldDelegate.color ||
      strokeColor != oldDelegate.strokeColor ||
      strokeWidth != oldDelegate.strokeWidth ||
      opacity != oldDelegate.opacity ||
      filled != oldDelegate.filled;
}

class _AssetImageBlock extends StatefulWidget {
  const _AssetImageBlock({
    required this.assetId,
    required this.assetStore,
    required this.resolvedBytes,
    required this.resolvedImage,
    required this.fit,
    required this.opacity,
  });
  final String? assetId;
  final CalendarStudioAssetStore? assetStore;
  final Uint8List? resolvedBytes;
  final ui.Image? resolvedImage;
  final BoxFit fit;
  final double opacity;

  @override
  State<_AssetImageBlock> createState() => _AssetImageBlockState();
}

class _AssetImageBlockState extends State<_AssetImageBlock> {
  Future<List<int>?>? _load;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _prepareLoad();
  }

  @override
  void didUpdateWidget(covariant _AssetImageBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId ||
        oldWidget.assetStore != widget.assetStore) {
      _prepareLoad();
    }
  }

  void _prepareLoad() {
    final id = widget.assetId;
    final store = widget.assetStore;
    _bytes = id != null && store is CachedCalendarStudioAssetStore
        ? store.peekBytes(id)
        : null;
    _load = _bytes != null || id == null || store == null
        ? null
        : store.loadBytes(id).then((bytes) {
            // Keep one stable instance so MemoryImage hits the image cache.
            if (bytes == null || bytes.isEmpty) return null;
            return _bytes = bytes is Uint8List
                ? bytes
                : Uint8List.fromList(bytes);
          });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resolvedImage case final image?) {
      // Export path: already decoded at full resolution, drawn this frame.
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) => RawImage(
            // RenderImage disposes what it holds; the original stays with
            // the caller.
            image: image.clone(),
            fit: widget.fit,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            opacity: AlwaysStoppedAnimation(widget.opacity.clamp(0, 1)),
          ),
        ),
      );
    }
    if (widget.resolvedBytes case final bytes? when bytes.isNotEmpty) {
      // Export path: decode at full resolution.
      return _image(bytes, constrainDecode: false);
    }
    if (_bytes case final bytes?) return _image(bytes);
    if (_load == null) return _placeholder();
    return FutureBuilder<List<int>?>(
      future: _load,
      builder: (_, snapshot) {
        final bytes = _bytes;
        if (bytes == null) return _placeholder();
        return _image(bytes);
      },
    );
  }

  Widget _image(Uint8List bytes, {bool constrainDecode = true}) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: LayoutBuilder(
      builder: (context, constraints) {
        // Decode near display size (with headroom for zoom) instead of the
        // full print-resolution original.
        // Constraints are in design units; the scene's scale turns them into
        // screen size, so a tiny thumbnail never decodes a full-size photo.
        final cacheWidth = constrainDecode && constraints.hasBoundedWidth
            ? (constraints.maxWidth *
                      _SceneScale.of(context) *
                      MediaQuery.devicePixelRatioOf(context) *
                      2)
                  .round()
                  .clamp(64, 4096)
            : null;
        return Image.memory(
          bytes,
          fit: widget.fit,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          cacheWidth: cacheWidth,
          gaplessPlayback: true,
          opacity: AlwaysStoppedAnimation(widget.opacity.clamp(0, 1)),
          // Damaged or unsupported bytes (e.g. from an imported file) show
          // the empty-image placeholder instead of a broken image.
          errorBuilder: (_, _, _) => _placeholder(),
        );
      },
    ),
  );

  Widget _placeholder() => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFE1E8E4),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(child: Icon(Icons.image_outlined)),
  );
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.block});
  final CalendarStudioBlock block;

  static TextAlign textAlignOf(CalendarStudioBlock block) =>
      switch (block.style['align']) {
        'center' => TextAlign.center,
        'right' => TextAlign.right,
        _ => TextAlign.left,
      };

  static Alignment alignmentOf(CalendarStudioBlock block) {
    final top = block.style['vAlign'] == 'top';
    return switch (block.style['align']) {
      'center' => top ? Alignment.topCenter : Alignment.center,
      'right' => top ? Alignment.topRight : Alignment.centerRight,
      _ => top ? Alignment.topLeft : Alignment.centerLeft,
    };
  }

  /// The main line's style; the inline editor types in the same one.
  static TextStyle mainStyle(CalendarStudioBlock block) {
    final style = block.style;
    // Myanmar stacks marks above and below the base line, so themed titles
    // set a taller line height; italic is for Latin-only text.
    return CalendarStudioFontCatalog.style(
      family: style['fontFamily'] as String? ?? 'Noto Sans Myanmar',
      weight: _fontWeight(style['fontWeight'] as int? ?? 700),
      italic: style['italic'] == true,
    ).copyWith(
      fontSize: (style['fontSize'] as num?)?.toDouble() ?? 20,
      letterSpacing: (style['letterSpacing'] as num?)?.toDouble(),
      color: Color((style['color'] as int?) ?? 0xFF15201D),
      height: (style['lineHeight'] as num?)?.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = block.style;
    final align = style['align'] as String?;
    final textAlign = textAlignOf(block);
    final size = (style['fontSize'] as num?)?.toDouble() ?? 20;
    final color = Color((style['color'] as int?) ?? 0xFF15201D);
    final family = style['fontFamily'] as String? ?? 'Noto Sans Myanmar';
    final main = Text(
      (block.content['text'] as String?) ?? '',
      textAlign: textAlign,
      style: mainStyle(block),
    );
    final subtitle = block.content['subtitle'] as String?;
    // A bilingual title: the English line sits under the Myanmar one.
    final child = subtitle == null
        ? main
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: switch (align) {
              'center' => CrossAxisAlignment.center,
              'right' => CrossAxisAlignment.end,
              _ => CrossAxisAlignment.start,
            },
            children: [
              main,
              Text(
                subtitle,
                textAlign: textAlign,
                style:
                    CalendarStudioFontCatalog.style(
                      family: family,
                      weight: FontWeight.w500,
                      italic: style['subtitleItalic'] == true,
                    ).copyWith(
                      fontSize:
                          size *
                          ((style['subtitleScale'] as num?)?.toDouble() ?? .38),
                      height: 1.2,
                      color: _color(style['subtitleColor']) ?? color,
                    ),
              ),
            ],
          );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignmentOf(block),
      child: child,
    );
  }
}

/// Typing into a text block on the page, in the block's own font, size and
/// colour. Esc or Cmd/Ctrl+Enter finishes, as does tapping elsewhere.
class CalendarStudioInlineText extends StatefulWidget {
  const CalendarStudioInlineText({
    required this.block,
    this.onChanged,
    this.onDone,
    super.key,
  });
  final CalendarStudioBlock block;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onDone;

  @override
  State<CalendarStudioInlineText> createState() =>
      _CalendarStudioInlineTextState();
}

class _CalendarStudioInlineTextState extends State<CalendarStudioInlineText> {
  late final _text = TextEditingController(
    text: widget.block.content['text'] as String? ?? '',
  );
  final _focus = FocusNode(debugLabel: 'calendar-studio-inline-text');
  var _done = false;

  @override
  void initState() {
    super.initState();
    _text.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _text.text.length,
    );
    _focus.addListener(() {
      if (!_focus.hasFocus) _finish();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone?.call();
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _TextBlock.mainStyle(widget.block);
    return Align(
      alignment: _TextBlock.alignmentOf(widget.block),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): _finish,
          const SingleActivator(LogicalKeyboardKey.enter, meta: true): _finish,
          const SingleActivator(LogicalKeyboardKey.enter, control: true):
              _finish,
        },
        child: TextField(
          controller: _text,
          focusNode: _focus,
          style: style,
          textAlign: _TextBlock.textAlignOf(widget.block),
          maxLines: null,
          // iOS draws its autocorrect highlight in unscaled page space,
          // so it lands off the text; titles don't need correcting.
          autocorrect: false,
          enableSuggestions: false,
          cursorColor: style.color,
          decoration: const InputDecoration.collapsed(hintText: ''),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

FontWeight _fontWeight(int value) => switch (value) {
  <= 100 => FontWeight.w100,
  <= 200 => FontWeight.w200,
  <= 300 => FontWeight.w300,
  <= 400 => FontWeight.w400,
  <= 500 => FontWeight.w500,
  <= 600 => FontWeight.w600,
  <= 700 => FontWeight.w700,
  <= 800 => FontWeight.w800,
  _ => FontWeight.w900,
};

class _TemplateDecoration extends StatelessWidget {
  const _TemplateDecoration({required this.block});
  final CalendarStudioBlock block;

  @override
  Widget build(BuildContext context) => switch (block.content['kind']) {
    'jadeHero' => const CustomPaint(painter: _JadeHeroPainter()),
    'jadeLogo' => const CustomPaint(painter: _JadeLogoPainter()),
    'moonBackdrop' => const CustomPaint(painter: _MoonBackdropPainter()),
    'lacquerBackdrop' => const CustomPaint(painter: _LacquerBackdropPainter()),
    'notesDark' => const CustomPaint(
      painter: _NotesPainter(color: Color(0x38FFFFFF), lines: 6),
    ),
    'notesLight' => const CustomPaint(
      painter: _NotesPainter(color: Color(0x5915201D), lines: 5),
    ),
    'goldRule' => const ColoredBox(color: Color(0xFFB98A25)),
    'inkRule' => const ColoredBox(color: Color(0xFF15201D)),
    'storyEvents' => const _StoryEvents(),
    _ =>
      CalendarStudioDecorations.build(block) ??
          const Center(
            child: Icon(Icons.spa_outlined, color: Color(0xFFB98A25)),
          ),
  };
}

class _TemplateLegend extends StatelessWidget {
  const _TemplateLegend({required this.block});
  final CalendarStudioBlock block;

  @override
  Widget build(BuildContext context) => const FittedBox(
    alignment: Alignment.centerLeft,
    fit: BoxFit.scaleDown,
    child: Row(
      children: [
        _LegendItem(color: Color(0xFFB8322A), label: 'ပိတ်ရက်  Public holiday'),
        SizedBox(width: 18),
        _LegendItem(color: Color(0xFFB98A25), label: 'လပြည့်  Full moon'),
        SizedBox(width: 18),
        _LegendItem(outlined: true, label: 'လကွယ်  New moon'),
        SizedBox(width: 18),
        Text(
          'ဆန်း ၈  ဥပုသ် Sabbath',
          style: TextStyle(fontSize: 9, color: Color(0xFF0E6B5C)),
        ),
      ],
    ),
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, this.color, this.outlined = false});
  final String label;
  final Color? color;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          shape: BoxShape.circle,
          border: outlined ? Border.all(color: const Color(0xFF74847F)) : null,
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 9)),
    ],
  );
}

class _StoryEvents extends StatelessWidget {
  const _StoryEvents();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _StoryEvent(
        day: '01',
        myanmar: 'နှစ်သစ်ကူးနေ့',
        english: "New Year's Day",
      ),
      _StoryEvent(
        day: '04',
        myanmar: 'လွတ်လပ်ရေးနေ့',
        english: 'Independence Day',
      ),
      _StoryEvent(
        day: '23',
        myanmar: 'ပြာသိုလပြည့်နေ့',
        english: 'Pyatho full moon',
      ),
    ],
  );
}

class _StoryEvent extends StatelessWidget {
  const _StoryEvent({
    required this.day,
    required this.myanmar,
    required this.english,
  });
  final String day;
  final String myanmar;
  final String english;

  @override
  Widget build(BuildContext context) => Expanded(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x47FFFFFF))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              day,
              style: CalendarStudioFontCatalog.style(
                family: CalendarStudioFontCatalog.numberFamily,
                weight: FontWeight.w600,
              ).copyWith(fontSize: 40, color: const Color(0xFFF7D98A)),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  myanmar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  english,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _NotesPainter extends CustomPainter {
  const _NotesPainter({required this.color, required this.lines});
  final Color color;
  final int lines;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var index = 1; index <= lines; index++) {
      final y = size.height * index / lines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NotesPainter oldDelegate) => false;
}

class _JadeHeroPainter extends CustomPainter {
  const _JadeHeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 595, size.height / 292);
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A5347), Color(0xFF2E9782), Color(0xFFF1CD70)],
        stops: [0, .62, 1],
      ).createShader(const Rect.fromLTWH(0, 0, 595, 292));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 595, 292), background);
    canvas.drawCircle(
      const Offset(446, 170),
      64,
      Paint()..color = const Color(0xEDF8DE95),
    );
    final hill = Path()
      ..moveTo(0, 214)
      ..cubicTo(90, 188, 170, 226, 280, 208)
      ..cubicTo(390, 190, 470, 186, 595, 216)
      ..lineTo(595, 292)
      ..lineTo(0, 292)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0x800B5B4E));
    _paintStupa(canvas, 30, 168, .52, const Color(0xCC0A4A40));
    _paintStupa(canvas, 238, 150, .66, const Color(0xD90A4A40));
    _paintStupa(canvas, 520, 176, .44, const Color(0xB30A4A40));
    _paintStupa(canvas, 112, 104, .92, const Color(0xFF06382F));
    final foreground = Path()
      ..moveTo(0, 250)
      ..cubicTo(120, 238, 240, 258, 360, 247)
      ..cubicTo(480, 236, 520, 242, 595, 252)
      ..lineTo(595, 292)
      ..lineTo(0, 292)
      ..close();
    canvas.drawPath(foreground, Paint()..color = const Color(0xFF062F28));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _JadeHeroPainter oldDelegate) => false;
}

class _JadeLogoPainter extends CustomPainter {
  const _JadeLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    canvas.drawCircle(const Offset(32, 32), 30, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(32, 32),
      30,
      Paint()
        ..color = const Color(0xFFD9A93A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    _paintStupa(canvas, 20, 14, .24, const Color(0xFF0E6B5C));
    canvas.drawLine(
      const Offset(18, 50),
      const Offset(46, 50),
      Paint()
        ..color = const Color(0xFFD9A93A)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _JadeLogoPainter oldDelegate) => false;
}

class _MoonBackdropPainter extends CustomPainter {
  const _MoonBackdropPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF151B3F), Color(0xFF2B2F68)],
        ).createShader(rect),
    );
    const stars = [
      Offset(.067, .083),
      Offset(.2, .05),
      Offset(.35, .117),
      Offset(.5, .043),
      Offset(.633, .1),
      Offset(.783, .057),
      Offset(.9, .133),
      Offset(.117, .2),
      Offset(.933, .25),
      Offset(.033, .333),
      Offset(.967, .4),
      Offset(.85, .033),
      Offset(.55, .183),
    ];
    for (var i = 0; i < stars.length; i++) {
      canvas.drawCircle(
        Offset(stars[i].dx * size.width, stars[i].dy * size.height),
        i % 3 == 0 ? 1.6 : 1,
        Paint()..color = Colors.white.withValues(alpha: .35 + (i % 4) * .15),
      );
    }
    canvas.drawCircle(
      Offset(size.width * .853, size.height * .187),
      size.width * .077,
      Paint()..color = const Color(0xFFF5D77E),
    );
    canvas.drawCircle(
      Offset(size.width * .883, size.height * .163),
      size.width * .067,
      Paint()..color = const Color(0xFF22275A),
    );
  }

  @override
  bool shouldRepaint(covariant _MoonBackdropPainter oldDelegate) => false;
}

class _LacquerBackdropPainter extends CustomPainter {
  const _LacquerBackdropPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5E0E1A), Color(0xFFA32A33), Color(0xFFE0A84A)],
          stops: [0, .6, 1],
        ).createShader(rect),
    );
    canvas.save();
    canvas.scale(size.width / 360, size.height / 640);
    _paintStupa(canvas, 214, 388, .9, const Color(0x594A0A14));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LacquerBackdropPainter oldDelegate) => false;
}

void _paintStupa(Canvas canvas, double x, double y, double scale, Color color) {
  canvas.save();
  canvas.translate(x, y);
  canvas.scale(scale);
  final paint = Paint()..color = color;
  canvas.drawPath(
    Path()
      ..moveTo(50, 2)
      ..lineTo(52.5, 26)
      ..lineTo(47.5, 26)
      ..close(),
    paint,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(44, 26, 12, 4),
      const Radius.circular(1),
    ),
    paint,
  );
  canvas.drawPath(
    Path()
      ..moveTo(40, 31)
      ..lineTo(60, 31)
      ..lineTo(56, 50)
      ..lineTo(44, 50)
      ..close(),
    paint,
  );
  final dome = Path()
    ..moveTo(29, 96)
    ..cubicTo(29, 66, 41, 50, 50, 50)
    ..cubicTo(59, 50, 71, 66, 71, 96)
    ..close();
  canvas.drawPath(dome, paint);
  canvas.drawRect(const Rect.fromLTWH(23, 96, 54, 8), paint);
  canvas.drawRect(const Rect.fromLTWH(17, 104, 66, 10), paint);
  canvas.drawRect(const Rect.fromLTWH(11, 114, 78, 14), paint);
  canvas.drawRect(const Rect.fromLTWH(5, 128, 90, 32), paint);
  canvas.restore();
}

String _myanmarNumber(Object value) => value.toString().replaceAllMapped(
  RegExp(r'\d'),
  (match) => '၀၁၂၃၄၅၆၇၈၉'[int.parse(match[0]!)],
);

class _ListBlock extends StatelessWidget {
  const _ListBlock({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16),
      const SizedBox(width: 5),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
    ],
  );
}

class _CalendarGrid extends StatefulWidget {
  const _CalendarGrid({
    required this.block,
    required this.source,
    this.dataProvider,
    this.resolvedDays,
  });
  final CalendarStudioBlock block;
  final CalendarStudioSource source;
  final CalendarStudioDataProvider? dataProvider;
  final List<CalendarStudioDayData>? resolvedDays;

  @override
  State<_CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<_CalendarGrid> {
  Future<List<CalendarStudioDayData>>? _days;
  List<CalendarStudioDayData>? _cachedDays;

  CalendarStudioBlock get block => widget.block;
  CalendarStudioSource get source => widget.source;

  int get _month => block.content['month'] as int? ?? source.month;

  @override
  void initState() {
    super.initState();
    _prepareDays();
  }

  @override
  void didUpdateWidget(covariant _CalendarGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldMonth =
        oldWidget.block.content['month'] as int? ?? oldWidget.source.month;
    if (oldWidget.dataProvider != widget.dataProvider ||
        oldWidget.source != widget.source ||
        oldMonth != _month) {
      _prepareDays();
    }
  }

  void _prepareDays() {
    final provider = widget.dataProvider;
    final effectiveSource = source.copyWith(month: _month);
    _cachedDays = provider is CachedCalendarStudioDataProvider
        ? provider.peek(effectiveSource, month: _month)
        : null;
    _days = _cachedDays != null || provider == null
        ? null
        : provider.daysFor(effectiveSource, month: _month);
  }

  @override
  Widget build(BuildContext context) {
    final rowHeight = (block.style['rowHeight'] as num?)?.toDouble() ?? 1;
    final month = block.content['month'] as int? ?? source.month;
    final effectiveSource = source.copyWith(month: month);
    final date = DateTime(effectiveSource.year, month);
    final first =
        (date.weekday % 7 - (effectiveSource.weekStartsMonday ? 1 : 0) + 7) % 7;
    final count = DateUtils.getDaysInMonth(effectiveSource.year, month);
    const englishHeaders = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const myanmarHeaders = ['နွေ', 'လာ', 'ဂါ', 'ဟူး', 'ကြာ', 'သော', 'နေ'];
    final weekdayOrder = effectiveSource.weekStartsMonday
        ? const [1, 2, 3, 4, 5, 6, 0]
        : const [0, 1, 2, 3, 4, 5, 6];
    final inkColor = Color(block.style['inkColor'] as int? ?? 0xFF15201D);
    final holidayColor = Color(
      block.style['holidayColor'] as int? ?? 0xFFB8322A,
    );
    final mini = block.content['mini'] as bool? ?? false;
    final weekendColor = _color(block.style['weekendColor']);
    final headerColor = _color(block.style['headerColor']) ?? inkColor;
    final mutedColor = _color(block.style['mutedColor']);
    final gridLines = block.style['gridLines'] as String? ?? 'light';
    final collapsed = gridLines == 'full' || gridLines == 'boxed';
    // "auto" draws only the weeks the month needs (4–6) instead of always 6.
    final rows = block.style['rows'] == 'auto' ? (first + count + 6) ~/ 7 : 6;
    final lineColor = Color(block.style['lineColor'] as int? ?? 0x2415201D);
    Color headerFor(int weekday) => weekendColor != null
        ? (weekday == 0 || weekday == 6 ? weekendColor : headerColor)
        : (weekday == 0 ? holidayColor : headerColor);
    Widget buildGrid(List<CalendarStudioDayData>? dayData) => Column(
      children: [
        SizedBox(
          height: (mini ? 14 : 30) / rowHeight.clamp(.75, 1.35),
          child: Row(
            children: [
              for (var index = 0; index < weekdayOrder.length; index++)
                Expanded(
                  child: Center(
                    child: _WeekdayLabel(
                      myanmar: effectiveSource.language.usesPackageText
                          // The package counts weekdays from Saturday.
                          ? TranslationService.getShortWeekdayName(
                              (weekdayOrder[index] + 1) % 7,
                              effectiveSource.language.calendarLanguage,
                            )
                          : myanmarHeaders[weekdayOrder[index]],
                      english: englishHeaders[weekdayOrder[index]],
                      language: effectiveSource.language,
                      mini: mini,
                      color: headerFor(weekdayOrder[index]),
                      subColor: mutedColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          // Boxed grids draw each cell's top and left edge and close the
          // right and bottom once here, so internal lines never double.
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: collapsed
                  ? Border(
                      right: BorderSide(color: lineColor),
                      bottom: BorderSide(color: lineColor),
                    )
                  : null,
            ),
            child: Column(
              children: [
                for (var row = 0; row < rows; row++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var column = 0; column < 7; column++)
                          Expanded(
                            child: _dayCell(
                              row * 7 + column - first + 1,
                              count,
                              dayData,
                              row: row,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
    if (widget.resolvedDays case final days?) return buildGrid(days);
    if (_cachedDays case final days?) return buildGrid(days);
    if (_days == null) return buildGrid(null);
    return FutureBuilder<List<CalendarStudioDayData>>(
      future: _days,
      builder: (_, snapshot) => buildGrid(snapshot.data),
    );
  }

  Widget _dayCell(
    int day,
    int count,
    List<CalendarStudioDayData>? dayData, {
    required int row,
  }) {
    final gridLines = block.style['gridLines'] as String? ?? 'light';
    final borderColor = Color(block.style['lineColor'] as int? ?? 0x2415201D);
    final border = switch (gridLines) {
      'none' => null,
      'full' || 'boxed' => Border(
        top: BorderSide(color: borderColor),
        left: BorderSide(color: borderColor),
      ),
      'lined' when row == 0 => null,
      _ => Border(top: BorderSide(color: borderColor)),
    };
    if (day < 1 || day > count) {
      // Blank cells keep their outline in boxed grids so the edge is even.
      return gridLines == 'full' || gridLines == 'boxed'
          ? DecoratedBox(
              decoration: BoxDecoration(border: border),
              child: const SizedBox.expand(),
            )
          : const SizedBox();
    }
    final month = block.content['month'] as int? ?? source.month;
    final weekday = DateTime(source.year, month, day).weekday;
    final sunday = weekday == 7;
    final weekendColor = _color(block.style['weekendColor']);
    final weekend = weekendColor != null ? weekday >= 6 : sunday;
    final data = dayData != null && day <= dayData.length
        ? dayData[day - 1]
        : null;
    final holiday = data?.holidayLabel?.isNotEmpty ?? false;
    final holidayColor = Color(
      block.style['holidayColor'] as int? ?? 0xFFB8322A,
    );
    final inkColor = Color(block.style['inkColor'] as int? ?? 0xFF15201D);
    final secondaryColor = Color(
      block.style['secondaryColor'] as int? ?? 0xB315201D,
    );
    final numberFont = block.style['numberFont'] as String? ?? 'serif';
    final rowHeight = (block.style['rowHeight'] as num?)?.toDouble() ?? 1;
    final mini = block.content['mini'] as bool? ?? false;
    final calendarStyle =
        block.content['calendarStyle'] as String? ?? 'standard';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: source.showHolidays && holiday
            ? holidayColor.withValues(alpha: .08)
            : null,
        border: border,
      ),
      child: Padding(
        padding: mini
            ? const EdgeInsets.fromLTRB(1, 1, 1, 0)
            : EdgeInsets.fromLTRB(5, 5 * rowHeight, 5, 3 * rowHeight),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalendarDayNumber(
                  family: block.style['numberFamily'] as String?,
                  label: source.language == CalendarStudioLanguage.myanmar
                      ? _myanmarNumber(day)
                      : source.language.usesPackageText
                      ? source.language.digits(day)
                      : '$day',
                  numberFont: numberFont,
                  mini: mini,
                  color: holiday
                      ? holidayColor
                      : weekend
                      ? weekendColor ?? holidayColor
                      : inkColor,
                  calendarStyle: calendarStyle,
                  moonPhase: data?.moonPhase,
                  // When the theme's holiday colour matches ordinary dates,
                  // an underline keeps holidays visible.
                  underline:
                      holiday &&
                      (holidayColor == inkColor ||
                          holidayColor == weekendColor),
                  emphasized: sunday || holiday,
                ),
                if (!mini)
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: _MyanmarDayIndicator(
                        data: data,
                        source: source,
                        color: secondaryColor,
                        sabbathColor: Color(
                          block.style['sabbathColor'] as int? ?? 0xFF8A6210,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (!mini && data != null && calendarStyle != 'moonlight')
              Positioned(
                right: 0,
                top: 0,
                child: _CalendarDayIndicators(
                  data: data,
                  source: source,
                  holidayColor: holidayColor,
                ),
              ),
            if (!mini &&
                source.showEvents &&
                (data?.events.isNotEmpty ?? false))
              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Color(
                      block.style['eventColor'] as int? ?? 0xFF0E6B5C,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayNumber extends StatelessWidget {
  const _CalendarDayNumber({
    required this.label,
    required this.numberFont,
    required this.mini,
    required this.color,
    required this.calendarStyle,
    required this.moonPhase,
    required this.emphasized,
    this.underline = false,
    this.family,
  });
  final bool underline;

  /// Preset numeral font; defaults to the Studio serif or sans.
  final String? family;
  final String label;
  final String numberFont;
  final bool mini;
  final Color color;
  final String calendarStyle;
  final int? moonPhase;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final isFull = calendarStyle == 'moonlight' && moonPhase == 1;
    final isNew = calendarStyle == 'moonlight' && moonPhase == 3;
    final text = Text(
      label,
      style:
          CalendarStudioFontCatalog.style(
            family:
                family ??
                (numberFont == 'serif'
                    ? CalendarStudioFontCatalog.numberFamily
                    : 'Noto Sans Myanmar'),
            weight: FontWeight.w700,
          ).copyWith(
            fontSize: mini ? 7 : 15,
            height: 1,
            color: isFull ? const Color(0xFF151B3F) : color,
            decoration: underline || calendarStyle == 'plain' && emphasized
                ? TextDecoration.underline
                : null,
            decorationColor: color,
          ),
    );
    if (!isFull && !isNew) return text;
    return Transform.translate(
      offset: const Offset(-4, -4),
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isFull ? const Color(0xFFF5D77E) : null,
          shape: BoxShape.circle,
          border: isNew
              ? Border.all(color: const Color(0x99EEF0FF), width: 1.5)
              : null,
        ),
        child: text,
      ),
    );
  }
}

/// Gold on paper for the lit part, a grey ring so a new moon still reads.
const _printMoonColors = MoonColors(
  lit: Color(0xFFD9A93A),
  shade: Color(0x1F5F6B67),
  rim: Color(0xFF5F6B67),
);

class _CalendarDayIndicators extends StatelessWidget {
  const _CalendarDayIndicators({
    required this.data,
    required this.source,
    required this.holidayColor,
  });
  final CalendarStudioDayData data;
  final CalendarStudioSource source;
  final Color holidayColor;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (source.showMoonPhases && (data.moonPhase == 1 || data.moonPhase == 3))
        MoonGlyph(date: data.date, size: 8, colors: _printMoonColors),
      if (source.showAstrology && data.hasAstrology)
        _dot(const Color(0xFF6847A8)),
    ],
  );

  Widget _dot(Color color) => Container(
    width: 5,
    height: 5,
    margin: const EdgeInsets.only(left: 2),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _MyanmarDayIndicator extends StatelessWidget {
  const _MyanmarDayIndicator({
    required this.data,
    required this.source,
    required this.color,
    required this.sabbathColor,
  });
  final CalendarStudioDayData? data;
  final CalendarStudioSource source;
  final Color color;
  final Color sabbathColor;

  @override
  Widget build(BuildContext context) {
    if (!source.showMyanmarDate || data == null) return const SizedBox();
    final fortnightDay = data!.fortnightDay;
    final moonPhase = data!.moonPhase;
    // Mon, Shan, Karen and Zawgyi use the provider's label in that language.
    if (fortnightDay == null ||
        moonPhase == null ||
        source.language.usesPackageText) {
      return Text(
        data!.myanmarLabel ?? '',
        style: TextStyle(
          fontFamily: 'Noto Sans Myanmar',
          fontSize: 8.5,
          height: 1.2,
          color: color,
        ),
      );
    }
    final label = switch (moonPhase) {
      1 => 'ပြည့်',
      3 => 'ကွယ်',
      2 => 'ဆုတ် ${_myanmarNumber(fortnightDay)}',
      _ => 'ဆန်း ${_myanmarNumber(fortnightDay)}',
    };
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: TextStyle(
        fontFamily: 'Noto Sans Myanmar',
        fontSize: 8.5,
        fontWeight: data!.isSabbath || data!.isSabbathEve
            ? FontWeight.w700
            : FontWeight.w500,
        height: 1.5,
        color: data!.isSabbath || data!.isSabbathEve ? sabbathColor : color,
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel({
    required this.myanmar,
    required this.english,
    required this.language,
    required this.mini,
    required this.color,
    this.subColor,
  });
  final String myanmar;
  final String english;
  final CalendarStudioLanguage language;
  final bool mini;
  final Color color;

  /// Colour of the English line under the Myanmar weekday.
  final Color? subColor;

  @override
  Widget build(BuildContext context) {
    if (language != CalendarStudioLanguage.both || mini) {
      return Text(
        language == CalendarStudioLanguage.english ? english : myanmar,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Noto Sans Myanmar',
          fontWeight: FontWeight.w700,
          fontSize: mini ? 6 : 10.5,
          height: 1.2,
          color: color,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          myanmar,
          style: TextStyle(
            fontFamily: 'Noto Sans Myanmar',
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
            height: 1.05,
            color: color,
          ),
        ),
        Text(
          english,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            height: 1.05,
            color: subColor ?? color.withValues(alpha: .65),
          ),
        ),
      ],
    );
  }
}

enum _ResizeHandle {
  topLeft(0, 0),
  top(.5, 0),
  topRight(1, 0),
  left(0, .5),
  right(1, .5),
  bottomLeft(0, 1),
  bottom(.5, 1),
  bottomRight(1, 1);

  const _ResizeHandle(this.x, this.y);
  final double x;
  final double y;

  MouseCursor get cursor => switch (this) {
    topLeft || bottomRight => SystemMouseCursors.resizeUpLeftDownRight,
    topRight || bottomLeft => SystemMouseCursors.resizeUpRightDownLeft,
    top || bottom => SystemMouseCursors.resizeUpDown,
    left || right => SystemMouseCursors.resizeLeftRight,
  };
}

class _SelectionActions extends StatelessWidget {
  const _SelectionActions({
    required this.locked,
    required this.visible,
    required this.onDuplicate,
    required this.onToggleLock,
    required this.onToggleVisibility,
    this.onMove,
    required this.onDelete,
  });
  final bool locked;
  final bool visible;
  final VoidCallback onDuplicate;
  final VoidCallback onToggleLock;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onMove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 4,
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(Icons.copy_outlined, 'Duplicate', onDuplicate),
        _button(
          locked ? Icons.lock_outline : Icons.lock_open_outlined,
          locked ? 'Unlock' : 'Lock',
          onToggleLock,
        ),
        _button(
          visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          visible ? 'Hide' : 'Show',
          onToggleVisibility,
        ),
        if (onMove != null) _button(Icons.open_with_outlined, 'Move', onMove!),
        Container(width: 1, height: 20, color: const Color(0xFFD5DEDA)),
        _button(Icons.delete_outline, 'Delete', onDelete, destructive: true),
      ],
    ),
  );

  Widget _button(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    bool destructive = false,
  }) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    iconSize: 18,
    color: destructive ? const Color(0xFFC0352B) : const Color(0xFF15201D),
    onPressed: onPressed,
    icon: Icon(icon),
  );
}

/// Reads an optional ARGB colour from block style.
Color? _color(Object? value) => value is int ? Color(value) : null;
