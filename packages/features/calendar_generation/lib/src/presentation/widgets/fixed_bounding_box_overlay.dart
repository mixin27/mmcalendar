import 'dart:math';

import 'package:bounding_box/bounding_box_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FixedBoundingBoxOverlay extends StatefulWidget {
  const FixedBoundingBoxOverlay({
    required this.builder,
    required this.controller,
    this.onTap,
    super.key,
  });

  final Widget Function(Size size, Offset position, double rotation) builder;
  final BoundingBoxController controller;
  final VoidCallback? onTap;

  @override
  State<FixedBoundingBoxOverlay> createState() =>
      _FixedBoundingBoxOverlayState();
}

class _FixedBoundingBoxOverlayState extends State<FixedBoundingBoxOverlay> {
  late BoundingBoxController _controller;

  Offset? _rotateStartLocal;
  Offset? _dragStartLocal;
  Offset? _dragBase;

  Offset? _resizeStartLocal;
  Size? _resizeBaseSize;
  Offset? _resizeBasePosition;
  int? _resizeHandleIndex;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant FixedBoundingBoxOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_onControllerUpdate);
    _controller = widget.controller;
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Offset _toLocal(Offset globalPosition) {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      return renderObject.globalToLocal(globalPosition);
    }
    return globalPosition;
  }

  Offset get center =>
      _controller.position +
      Offset(_controller.size.width / 2, _controller.size.height / 2);

  List<Offset> getHandlePositions() {
    final w = _controller.size.width;
    final h = _controller.size.height;
    final localPoints = <Offset>[
      const Offset(0, 0),
      Offset(w / 2, 0),
      Offset(w, 0),
      Offset(0, h / 2),
      Offset(w, h / 2),
      Offset(0, h),
      Offset(w / 2, h),
      Offset(w, h),
    ];
    return localPoints
        .map((local) {
          final rotated = _rotate(
            local - Offset(w / 2, h / 2),
            _controller.rotation,
          );
          return center + rotated;
        })
        .toList(growable: false);
  }

  Offset _rotate(Offset point, double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return Offset(
      point.dx * cosA - point.dy * sinA,
      point.dx * sinA + point.dy * cosA,
    );
  }

  void _resizeFromHandleDelta(int index, Offset delta) {
    final baseSize = _resizeBaseSize;
    final basePosition = _resizeBasePosition;
    if (baseSize == null || basePosition == null) {
      return;
    }

    final dx = delta.dx;
    final dy = delta.dy;
    var newW = baseSize.width;
    var newH = baseSize.height;
    var newPos = basePosition;

    switch (index) {
      case 0:
        newW -= dx;
        newH -= dy;
        newPos += Offset(dx, dy);
        break;
      case 1:
        newH -= dy;
        newPos += Offset(0, dy);
        break;
      case 2:
        newW += dx;
        newH -= dy;
        newPos += Offset(0, dy);
        break;
      case 3:
        newW -= dx;
        newPos += Offset(dx, 0);
        break;
      case 4:
        newW += dx;
        break;
      case 5:
        newW -= dx;
        newH += dy;
        newPos += Offset(dx, 0);
        break;
      case 6:
        newH += dy;
        break;
      case 7:
        newW += dx;
        newH += dy;
        break;
    }

    _controller.update(
      newPosition: newPos,
      newSize: Size(max(30, newW), max(30, newH)),
    );
  }

  SystemMouseCursor _mouseSizeTranslation(int index) {
    return switch (index) {
      0 => SystemMouseCursors.resizeUpLeftDownRight,
      1 => SystemMouseCursors.resizeUpDown,
      2 => SystemMouseCursors.resizeUpRightDownLeft,
      3 => SystemMouseCursors.resizeLeftRight,
      4 => SystemMouseCursors.resizeLeftRight,
      5 => SystemMouseCursors.resizeUpRightDownLeft,
      6 => SystemMouseCursors.resizeUpDown,
      7 => SystemMouseCursors.resizeUpLeftDownRight,
      _ => SystemMouseCursors.basic,
    };
  }

  void _onRotateStart(DragStartDetails details) {
    _rotateStartLocal = _toLocal(details.globalPosition);
  }

  void _onRotateUpdate(DragUpdateDetails details) {
    final prev = _rotateStartLocal;
    if (prev == null) {
      return;
    }
    final curr = _toLocal(details.globalPosition);
    final a = atan2(prev.dy - center.dy, prev.dx - center.dx);
    final b = atan2(curr.dy - center.dy, curr.dx - center.dx);
    _controller.update(newRotation: _controller.rotation + (b - a));
    _rotateStartLocal = curr;
  }

  void _onDragStart(DragStartDetails details) {
    _dragStartLocal = _toLocal(details.globalPosition);
    _dragBase = _controller.position;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final start = _dragStartLocal;
    final base = _dragBase;
    if (start == null || base == null) {
      return;
    }
    final curr = _toLocal(details.globalPosition);
    _controller.update(newPosition: base + (curr - start));
  }

  void _onResizeStart(int index, DragStartDetails details) {
    _resizeHandleIndex = index;
    _resizeStartLocal = _toLocal(details.globalPosition);
    _resizeBaseSize = _controller.size;
    _resizeBasePosition = _controller.position;
  }

  void _onResizeUpdate(int index, DragUpdateDetails details) {
    if (_resizeHandleIndex != index) {
      return;
    }
    final start = _resizeStartLocal;
    if (start == null) {
      return;
    }
    final curr = _toLocal(details.globalPosition);
    _resizeFromHandleDelta(index, curr - start);
  }

  void _onResizeEnd(DragEndDetails details) {
    _resizeHandleIndex = null;
    _resizeStartLocal = null;
    _resizeBaseSize = null;
    _resizeBasePosition = null;
  }

  List<Widget> _actionWidgets() {
    return [
      if (_controller.enableRotate == true)
        MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: GestureDetector(
            onPanStart: _onRotateStart,
            onPanUpdate: _onRotateUpdate,
            onTap: widget.onTap,
            child:
                _controller.customHandleRotate ??
                Container(
                  width: widget.controller.actionSize,
                  height: widget.controller.actionSize,
                  decoration: BoxDecoration(
                    color:
                        _controller.handleRotateBackgroundColor ?? Colors.white,
                    border: Border.all(
                      color: _controller.handleRotateStrokeColor ?? Colors.blue,
                      width: _controller.handleRotateStrokeWidth ?? 1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child:
                        _controller.rotateIcon ??
                        const Icon(
                          Icons.rotate_right,
                          size: 12,
                          color: Colors.blue,
                        ),
                  ),
                ),
          ),
        ),
      if (_controller.enableRotate == true && _controller.enableMove == true)
        const SizedBox(width: 5),
      if (_controller.enableMove == true)
        MouseRegion(
          cursor: SystemMouseCursors.move,
          child: GestureDetector(
            onPanStart: _onDragStart,
            onPanUpdate: _onDragUpdate,
            child:
                _controller.customHandleMove ??
                Container(
                  width: widget.controller.actionSize,
                  height: widget.controller.actionSize,
                  decoration: BoxDecoration(
                    color:
                        _controller.handleMoveBackgroundColor ?? Colors.white,
                    border: Border.all(
                      color: _controller.handleMoveStrokeColor ?? Colors.blue,
                      width: _controller.handleMoveStrokeWidth ?? 1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child:
                        _controller.moveIcon ??
                        const Icon(
                          Icons.drag_indicator_rounded,
                          size: 12,
                          color: Colors.blue,
                        ),
                  ),
                ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final handles = getHandlePositions();
    final actionSize = widget.controller.actionSize;

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: _controller.position.dx,
            top: _controller.position.dy,
            child: Transform.rotate(
              angle: _controller.rotation,
              child: GestureDetector(
                onPanStart: (details) {
                  widget.onTap?.call();
                  _onDragStart(details);
                },
                onPanUpdate: _onDragUpdate,
                onTap: widget.onTap,
                child: widget.builder(
                  _controller.size,
                  _controller.position,
                  _controller.rotation,
                ),
              ),
            ),
          ),
          if (_controller.enable) ...[
            Positioned(
              left: _controller.position.dx,
              top: _controller.position.dy,
              child: IgnorePointer(
                ignoring: true,
                child: Transform.rotate(
                  angle: _controller.rotation,
                  alignment: Alignment.center,
                  child: Container(
                    width: _controller.size.width,
                    height: _controller.size.height,
                    decoration:
                        _controller.customDecoration ??
                        BoxDecoration(
                          border: Border.all(
                            color: _controller.strokeColor ?? Colors.blue,
                            width: _controller.strokeWidth ?? 2,
                          ),
                        ),
                  ),
                ),
              ),
            ),
            for (var index = 0; index < handles.length; index++)
              Positioned(
                left: handles[index].dx - actionSize / 2,
                top: handles[index].dy - actionSize / 2,
                child: MouseRegion(
                  cursor: _mouseSizeTranslation(index),
                  child: GestureDetector(
                    onPanStart: (details) => _onResizeStart(index, details),
                    onPanUpdate: (details) => _onResizeUpdate(index, details),
                    onPanEnd: _onResizeEnd,
                    child:
                        _controller.customHandleResize ??
                        Container(
                          width: actionSize,
                          height: actionSize,
                          decoration: BoxDecoration(
                            color:
                                _controller.handleResizeBackgroundColor ??
                                Colors.white,
                            border: Border.all(
                              color:
                                  _controller.handleResizeStrokeColor ??
                                  Colors.blue,
                              width: _controller.handleResizeStrokeWidth ?? 1,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                  ),
                ),
              ),
            Positioned(
              left:
                  center.dx -
                  ((_controller.enableRotate == true ? actionSize : 0) +
                          (_controller.enableMove == true
                              ? actionSize + 5
                              : 0)) /
                      2,
              top:
                  center.dy +
                  ((_controller.size.height / 2) + 10 + (actionSize / 2)) +
                  (_controller.handlePosition ?? 0),
              child: Row(children: _actionWidgets()),
            ),
          ],
        ],
      ),
    );
  }
}
