import 'package:flutter/material.dart';
import 'package:flutter_box_transform/flutter_box_transform.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_landscape_decoration_area_side.dart';
import '../../domain/entities/calendar_page_model.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import '../../domain/entities/calendar_preview_theme.dart';
import '../../rendering/export/calendar_export_layout.dart';
import '../widgets/calendar_generation_preview_page.dart';

class CalendarLayoutEditorResult {
  const CalendarLayoutEditorResult({
    required this.theme,
    required this.pageIndex,
  });

  final CalendarPreviewTheme theme;
  final int pageIndex;
}

class CalendarLayoutEditorPage extends StatefulWidget {
  const CalendarLayoutEditorPage({
    required this.request,
    required this.pages,
    required this.initialPageIndex,
    super.key,
  });

  final CalendarGenerationRequest request;
  final List<CalendarPageModel> pages;
  final int initialPageIndex;

  @override
  State<CalendarLayoutEditorPage> createState() =>
      _CalendarLayoutEditorPageState();
}

class _CalendarLayoutEditorPageState extends State<CalendarLayoutEditorPage> {
  static const String _calendarElementId = 'calendar_panel';
  static const String _freeBoxPrefix = 'free_box:';
  static const double _minCanvasScale = 0.6;
  static const double _maxCanvasScale = 4.0;

  late final TransformationController _canvasController;
  final Map<String, TransformableBoxController> _controllers =
      <String, TransformableBoxController>{};
  String? _interactingElementId;
  bool _updatingControllers = false;
  double _canvasScale = 1.0;

  late CalendarPreviewTheme _theme;
  late int _pageIndex;
  String? _selectedElementId;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _theme = widget.request.theme;
    _pageIndex = widget.initialPageIndex.clamp(
      0,
      (widget.pages.length - 1).clamp(0, 999),
    );
    _canvasController = TransformationController();
    _canvasController.addListener(_onCanvasTransformChanged);
  }

  @override
  void dispose() {
    _canvasController.removeListener(_onCanvasTransformChanged);
    _canvasController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Layout Editor')),
        body: const Center(
          child: Text('No pages available for layout editor.'),
        ),
      );
    }

    final page = widget.pages[_pageIndex];
    final request = widget.request.copyWith(theme: _theme);
    final canvasSizeData = CalendarExportLayout.resolvePreviewCanvasSize(
      request,
    );
    final canvasSize = Size(canvasSizeData.width, canvasSizeData.height);

    return PopScope<void>(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_hasChanges) {
          return;
        }
        final discard = await _confirmDiscardChanges();
        if (!context.mounted || !discard) {
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Layout Editor'),
          actions: [
            IconButton(
              onPressed: _selectedElementId == null
                  ? null
                  : () => setState(() => _selectedElementId = null),
              tooltip: 'Deselect',
              icon: const Icon(Icons.deselect_outlined),
            ),
            IconButton(
              onPressed: _zoomOutCanvas,
              tooltip: 'Zoom out canvas',
              icon: const Icon(Icons.zoom_out),
            ),
            Center(
              child: Text(
                '${(_canvasScale * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            IconButton(
              onPressed: _zoomInCanvas,
              tooltip: 'Zoom in canvas',
              icon: const Icon(Icons.zoom_in),
            ),
            IconButton(
              onPressed: _resetCanvasTransform,
              tooltip: 'Reset canvas view',
              icon: const Icon(Icons.center_focus_strong_outlined),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _finishEditing,
              icon: const Icon(Icons.check),
              label: const Text('Done'),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildPageNavigation(page),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: _buildCanvasCard(
                    page: page,
                    request: request,
                    canvasSize: canvasSize,
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageNavigation(CalendarPageModel page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: _pageIndex > 0
                    ? () => setState(() {
                        _pageIndex -= 1;
                        _selectedElementId = null;
                      })
                    : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Prev'),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Page ${_pageIndex + 1}/${widget.pages.length}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        page.westernTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _pageIndex < widget.pages.length - 1
                    ? () => setState(() {
                        _pageIndex += 1;
                        _selectedElementId = null;
                      })
                    : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
                iconAlignment: IconAlignment.end,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasCard({
    required CalendarPageModel page,
    required CalendarGenerationRequest request,
    required Size canvasSize,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: InteractiveViewer(
          constrained: true,
          boundaryMargin: const EdgeInsets.all(80),
          minScale: _minCanvasScale,
          maxScale: _maxCanvasScale,
          panEnabled: _selectedElementId == null,
          scaleEnabled: _selectedElementId == null,
          transformationController: _canvasController,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: SizedBox(
                width: canvasSize.width,
                height: canvasSize.height,
                child: _buildCanvasScene(
                  page: page,
                  request: request,
                  canvasSize: canvasSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasScene({
    required CalendarPageModel page,
    required CalendarGenerationRequest request,
    required Size canvasSize,
  }) {
    final geometry = _resolveLayoutGeometry(
      canvasSize: canvasSize,
      request: request,
    );
    final elements = _elements(geometry);
    _syncControllers(elements: elements, geometry: geometry);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CalendarGenerationPreviewPage(
            model: page,
            request: request,
            margin: EdgeInsets.zero,
            elevation: 0,
            contentPadding: const EdgeInsets.all(12),
            useCardChrome: false,
          ),
        ),
        for (final element in elements) _buildLayoutElement(element, geometry),
      ],
    );
  }

  Widget _buildLayoutElement(_LayoutElement element, _LayoutGeometry geometry) {
    final isSelected = _selectedElementId == element.id;
    final controller = _controllers[element.id];
    if (controller == null) {
      return const SizedBox.shrink();
    }

    final content = _buildElementContent(
      element: element,
      selected: isSelected,
    );
    if (!isSelected) {
      return Positioned.fromRect(
        rect: controller.rect,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => setState(() => _selectedElementId = element.id),
          child: content,
        ),
      );
    }

    return TransformableBox(
      key: ValueKey<String>('layout_element_${element.id}'),
      controller: controller,
      allowFlippingWhileResizing: false,
      draggable: true,
      resizable: true,
      visibleHandles: const <HandlePosition>{
        HandlePosition.topLeft,
        HandlePosition.topRight,
        HandlePosition.bottomLeft,
        HandlePosition.bottomRight,
      },
      enabledHandles: const <HandlePosition>{
        HandlePosition.topLeft,
        HandlePosition.topRight,
        HandlePosition.bottomLeft,
        HandlePosition.bottomRight,
      },
      onTap: () => setState(() => _selectedElementId = element.id),
      onDragStart: (_) => _interactingElementId = element.id,
      onResizeStart: (_, _) => _interactingElementId = element.id,
      onChanged: (result, _) => _updateElementFromRect(
        element: element,
        rect: result.rect,
        geometry: geometry,
      ),
      onDragEnd: (_) => setState(() => _interactingElementId = null),
      onResizeEnd: (_, _) => setState(() => _interactingElementId = null),
      contentBuilder: (buildContext, rect, flip) =>
          _buildElementContent(element: element, selected: true),
      cornerHandleBuilder: (buildContext, handle) => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildElementContent({
    required _LayoutElement element,
    required bool selected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = selected
        ? colorScheme.primary
        : colorScheme.outlineVariant.withValues(alpha: 0.8);
    final fillColor = selected
        ? colorScheme.primary.withValues(alpha: 0.08)
        : colorScheme.surface.withValues(alpha: 0.02);
    final labelColor = selected ? colorScheme.primary : colorScheme.onSurface;
    return Transform.rotate(
      angle: element.rotation,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1.0),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 4,
              top: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2.5,
                  ),
                  child: Text(
                    element.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final selectedIsCalendar = _selectedElementId == _calendarElementId;
    final selectedFreeBoxId = _selectedFreeBoxId;
    final canDeleteSelectedBox = selectedFreeBoxId != null;
    final selectedBox = selectedFreeBoxId == null
        ? null
        : _theme.freeSpaceBoxes
              .where((box) => box.id == selectedFreeBoxId)
              .firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _EditorActionButton(
                  icon: Icons.add_box_outlined,
                  label: 'Add Box',
                  onTap: _addFreeBox,
                ),
                _EditorActionButton(
                  icon: Icons.rotate_left_outlined,
                  label: 'Rotate -',
                  onTap: _selectedElementId == null
                      ? null
                      : () => _rotateSelected(-0.08),
                ),
                _EditorActionButton(
                  icon: Icons.rotate_right_outlined,
                  label: 'Rotate +',
                  onTap: _selectedElementId == null
                      ? null
                      : () => _rotateSelected(0.08),
                ),
                _EditorActionButton(
                  icon: Icons.visibility_outlined,
                  label: selectedBox?.visible == false
                      ? 'Show Box'
                      : 'Hide Box',
                  onTap: selectedFreeBoxId == null
                      ? null
                      : () => _toggleBoxVisibility(selectedFreeBoxId),
                ),
                _EditorActionButton(
                  icon: Icons.delete_outline,
                  label: selectedIsCalendar ? 'Reset Cal Rot' : 'Delete Box',
                  onTap: selectedIsCalendar
                      ? _resetCalendarRotation
                      : (canDeleteSelectedBox ? _deleteSelectedBox : null),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_LayoutElement> _elements(_LayoutGeometry geometry) {
    final items = <_LayoutElement>[
      _LayoutElement(
        id: _calendarElementId,
        type: _LayoutElementType.calendarPanel,
        rect: _calendarPanelRect(geometry),
        rotation: _theme.calendarContentRotation,
        label: 'Calendar',
      ),
    ];

    for (var i = 0; i < _theme.freeSpaceBoxes.length; i++) {
      final box = _theme.freeSpaceBoxes[i];
      items.add(
        _LayoutElement(
          id: '$_freeBoxPrefix${box.id}',
          type: _LayoutElementType.freeBox,
          rect: _freeBoxRect(box, geometry),
          rotation: box.rotation,
          label: 'Box ${i + 1}',
        ),
      );
    }
    return items;
  }

  void _syncControllers({
    required List<_LayoutElement> elements,
    required _LayoutGeometry geometry,
  }) {
    final ids = elements.map((e) => e.id).toSet();
    final staleIds = _controllers.keys
        .where((id) => !ids.contains(id))
        .toList();
    for (final staleId in staleIds) {
      _controllers.remove(staleId)?.dispose();
    }

    if (_selectedElementId != null && !ids.contains(_selectedElementId)) {
      _selectedElementId = null;
    }

    final clampRect = Rect.fromLTWH(
      0,
      0,
      geometry.canvasSize.width,
      geometry.canvasSize.height,
    );

    for (final element in elements) {
      final existing = _controllers[element.id];
      final maxWidth = element.type == _LayoutElementType.calendarPanel
          ? geometry.calendarSlotRect.width
          : geometry.decorationRect.width;
      final maxHeight = element.type == _LayoutElementType.calendarPanel
          ? geometry.calendarSlotRect.height
          : geometry.decorationRect.height;
      if (existing == null) {
        _controllers[element.id] = TransformableBoxController(
          rect: element.rect,
          clampingRect: clampRect,
          constraints: BoxConstraints(
            minWidth: 28,
            minHeight: 28,
            maxWidth: maxWidth <= 0 ? geometry.canvasSize.width : maxWidth,
            maxHeight: maxHeight <= 0 ? geometry.canvasSize.height : maxHeight,
          ),
          allowFlippingWhileResizing: false,
        );
        continue;
      }
      if (_interactingElementId == element.id) {
        continue;
      }
      try {
        _updatingControllers = true;
        existing.setRect(element.rect, notify: false, recalculate: false);
        existing.setClampingRect(clampRect, notify: false, recalculate: false);
        existing.setConstraints(
          BoxConstraints(
            minWidth: 28,
            minHeight: 28,
            maxWidth: maxWidth <= 0 ? geometry.canvasSize.width : maxWidth,
            maxHeight: maxHeight <= 0 ? geometry.canvasSize.height : maxHeight,
          ),
          notify: false,
        );
      } finally {
        _updatingControllers = false;
      }
    }
  }

  void _updateElementFromRect({
    required _LayoutElement element,
    required Rect rect,
    required _LayoutGeometry geometry,
  }) {
    if (_updatingControllers) {
      return;
    }

    if (element.type == _LayoutElementType.calendarPanel) {
      final slot = geometry.calendarSlotRect;
      if (slot.width <= 0 || slot.height <= 0) {
        return;
      }
      final widthFactor = (rect.width / slot.width).clamp(0.4, 1.0);
      final heightFactor = (rect.height / slot.height).clamp(0.4, 1.0);
      final centerX = ((rect.center.dx - slot.left) / slot.width)
          .clamp(0.0, 1.0)
          .toDouble();
      final centerY = ((rect.center.dy - slot.top) / slot.height)
          .clamp(0.0, 1.0)
          .toDouble();
      _applyTheme(
        _theme.copyWith(
          calendarContentOffsetX: (centerX * 2) - 1,
          calendarContentOffsetY: (centerY * 2) - 1,
          calendarContentWidthFactor: widthFactor,
          calendarContentHeightFactor: heightFactor,
        ),
      );
      return;
    }

    final boxId = _freeBoxIdFromElementId(element.id);
    if (boxId == null) {
      return;
    }
    final slot = geometry.decorationRect;
    if (slot.width <= 0 || slot.height <= 0) {
      return;
    }
    final minWidth = (slot.width * 0.05).clamp(28.0, slot.width).toDouble();
    final minHeight = (slot.height * 0.05).clamp(28.0, slot.height).toDouble();
    final clamped = _clampRect(
      rect: rect,
      bounds: slot,
      minWidth: minWidth,
      minHeight: minHeight,
    );
    final x = ((clamped.left - slot.left) / slot.width).clamp(0.0, 1.0);
    final y = ((clamped.top - slot.top) / slot.height).clamp(0.0, 1.0);
    final width = (clamped.width / slot.width).clamp(0.05, 1.0);
    final height = (clamped.height / slot.height).clamp(0.05, 1.0);

    final nextBoxes = _theme.freeSpaceBoxes
        .map(
          (box) => box.id == boxId
              ? box.copyWith(x: x, y: y, width: width, height: height)
              : box,
        )
        .toList(growable: false);
    _applyTheme(_theme.copyWith(freeSpaceBoxes: nextBoxes));
  }

  void _applyTheme(CalendarPreviewTheme next) {
    setState(() {
      _theme = next;
      _hasChanges = true;
    });
  }

  void _addFreeBox() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final box = CalendarFreeSpaceBox(
      id: 'box_$now',
      x: 0.2,
      y: 0.2,
      width: 0.6,
      height: 0.55,
      fillColorValue: 0x1AFFFFFF,
      borderColorValue: 0x661E293B,
      borderWidth: 1.4,
      cornerRadius: 8,
      borderDesign: CalendarBorderDesign.solid,
      visible: true,
    );
    _applyTheme(
      _theme.copyWith(
        freeSpaceBoxes: <CalendarFreeSpaceBox>[..._theme.freeSpaceBoxes, box],
      ),
    );
    setState(() => _selectedElementId = '$_freeBoxPrefix${box.id}');
  }

  void _deleteSelectedBox() {
    final boxId = _selectedFreeBoxId;
    if (boxId == null) {
      return;
    }
    final nextBoxes = _theme.freeSpaceBoxes
        .where((box) => box.id != boxId)
        .toList(growable: false);
    _controllers.remove('$_freeBoxPrefix$boxId')?.dispose();
    _applyTheme(_theme.copyWith(freeSpaceBoxes: nextBoxes));
    setState(() => _selectedElementId = null);
  }

  void _toggleBoxVisibility(String boxId) {
    final nextBoxes = _theme.freeSpaceBoxes
        .map(
          (box) => box.id == boxId ? box.copyWith(visible: !box.visible) : box,
        )
        .toList(growable: false);
    _applyTheme(_theme.copyWith(freeSpaceBoxes: nextBoxes));
  }

  void _rotateSelected(double delta) {
    final id = _selectedElementId;
    if (id == null) {
      return;
    }
    if (id == _calendarElementId) {
      _applyTheme(
        _theme.copyWith(
          calendarContentRotation: _theme.calendarContentRotation + delta,
        ),
      );
      return;
    }
    final boxId = _freeBoxIdFromElementId(id);
    if (boxId == null) {
      return;
    }
    final nextBoxes = _theme.freeSpaceBoxes
        .map(
          (box) => box.id == boxId
              ? box.copyWith(rotation: box.rotation + delta)
              : box,
        )
        .toList(growable: false);
    _applyTheme(_theme.copyWith(freeSpaceBoxes: nextBoxes));
  }

  void _resetCalendarRotation() {
    _applyTheme(_theme.copyWith(calendarContentRotation: 0));
  }

  String? get _selectedFreeBoxId => _freeBoxIdFromElementId(_selectedElementId);

  String? _freeBoxIdFromElementId(String? id) {
    if (id == null || !id.startsWith(_freeBoxPrefix)) {
      return null;
    }
    final boxId = id.substring(_freeBoxPrefix.length).trim();
    return boxId.isEmpty ? null : boxId;
  }

  Rect _calendarPanelRect(_LayoutGeometry geometry) {
    final slot = geometry.calendarSlotRect;
    if (slot.width <= 0 || slot.height <= 0) {
      return Rect.zero;
    }
    final normalizedX = _theme.calendarContentOffsetX.clamp(-1.0, 1.0);
    final normalizedY = _theme.calendarContentOffsetY.clamp(-1.0, 1.0);
    final widthFactor = _theme.calendarContentWidthFactor.clamp(0.4, 1.0);
    final heightFactor = _theme.calendarContentHeightFactor.clamp(0.4, 1.0);
    final centerX = ((normalizedX + 1) / 2).clamp(0.0, 1.0);
    final centerY = ((normalizedY + 1) / 2).clamp(0.0, 1.0);
    final leftFactor = centerX - (widthFactor / 2);
    final topFactor = centerY - (heightFactor / 2);
    return Rect.fromLTWH(
      slot.left + (leftFactor * slot.width),
      slot.top + (topFactor * slot.height),
      slot.width * widthFactor,
      slot.height * heightFactor,
    );
  }

  Rect _freeBoxRect(CalendarFreeSpaceBox box, _LayoutGeometry geometry) {
    final slot = geometry.decorationRect;
    if (slot.width <= 0 || slot.height <= 0) {
      return Rect.zero;
    }
    return Rect.fromLTWH(
      slot.left + (box.x.clamp(0.0, 1.0) * slot.width),
      slot.top + (box.y.clamp(0.0, 1.0) * slot.height),
      (box.width.clamp(0.05, 1.0) * slot.width),
      (box.height.clamp(0.05, 1.0) * slot.height),
    );
  }

  _LayoutGeometry _resolveLayoutGeometry({
    required Size canvasSize,
    required CalendarGenerationRequest request,
  }) {
    final contentRect = Rect.fromLTWH(
      12,
      12,
      (canvasSize.width - 24).clamp(0, canvasSize.width).toDouble(),
      (canvasSize.height - 24).clamp(0, canvasSize.height).toDouble(),
    );
    const portraitCalendarFlex = 72.0;
    const landscapeCalendarFlex = 76.0;
    const gap = 8.0;
    final isLandscape =
        request.pageOrientation == CalendarPageOrientation.landscape;
    final isDecorationOnLeft =
        request.landscapeDecorationAreaSide ==
        CalendarLandscapeDecorationAreaSide.left;

    if (!isLandscape) {
      final availableHeight = (contentRect.height - gap).clamp(
        0.0,
        contentRect.height,
      );
      final calendarHeight = availableHeight * (portraitCalendarFlex / 100);
      final decorationHeight = (availableHeight - calendarHeight).clamp(
        0.0,
        contentRect.height,
      );
      final calendarRect = Rect.fromLTWH(
        contentRect.left,
        contentRect.top,
        contentRect.width,
        calendarHeight,
      );
      final decorationRect = Rect.fromLTWH(
        contentRect.left,
        contentRect.top + calendarHeight + gap,
        contentRect.width,
        decorationHeight,
      );
      return _LayoutGeometry(
        canvasSize: canvasSize,
        contentRect: contentRect,
        calendarSlotRect: calendarRect,
        decorationRect: decorationRect,
      );
    }

    final availableWidth = (contentRect.width - gap).clamp(
      0.0,
      contentRect.width,
    );
    final calendarWidth = availableWidth * (landscapeCalendarFlex / 100);
    final decorationWidth = (availableWidth - calendarWidth).clamp(
      0.0,
      contentRect.width,
    );

    final decorationRect = Rect.fromLTWH(
      isDecorationOnLeft
          ? contentRect.left
          : contentRect.left + calendarWidth + gap,
      contentRect.top,
      decorationWidth,
      contentRect.height,
    );
    final calendarRect = Rect.fromLTWH(
      isDecorationOnLeft
          ? contentRect.left + decorationWidth + gap
          : contentRect.left,
      contentRect.top,
      calendarWidth,
      contentRect.height,
    );
    return _LayoutGeometry(
      canvasSize: canvasSize,
      contentRect: contentRect,
      calendarSlotRect: calendarRect,
      decorationRect: decorationRect,
    );
  }

  Rect _clampRect({
    required Rect rect,
    required Rect bounds,
    required double minWidth,
    required double minHeight,
  }) {
    final width = rect.width.clamp(minWidth, bounds.width).toDouble();
    final height = rect.height.clamp(minHeight, bounds.height).toDouble();
    final left = rect.left.clamp(bounds.left, bounds.right - width).toDouble();
    final top = rect.top.clamp(bounds.top, bounds.bottom - height).toDouble();
    return Rect.fromLTWH(left, top, width, height);
  }

  void _finishEditing() {
    Navigator.of(
      context,
    ).pop(CalendarLayoutEditorResult(theme: _theme, pageIndex: _pageIndex));
  }

  Future<bool> _confirmDiscardChanges() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard layout changes?'),
        content: const Text('You have unsaved layout changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  void _onCanvasTransformChanged() {
    final nextScale = _canvasController.value.getMaxScaleOnAxis();
    if ((nextScale - _canvasScale).abs() < 0.001) {
      return;
    }
    setState(() => _canvasScale = nextScale);
  }

  void _zoomInCanvas() {
    _setCanvasScale(
      (_canvasScale * 1.2).clamp(_minCanvasScale, _maxCanvasScale),
    );
  }

  void _zoomOutCanvas() {
    _setCanvasScale(
      (_canvasScale / 1.2).clamp(_minCanvasScale, _maxCanvasScale),
    );
  }

  void _resetCanvasTransform() {
    _canvasController.value = Matrix4.identity();
    setState(() => _canvasScale = 1.0);
  }

  void _setCanvasScale(double scale) {
    final safeScale = scale.clamp(_minCanvasScale, _maxCanvasScale);
    _canvasController.value = Matrix4.diagonal3Values(safeScale, safeScale, 1);
    setState(() => _canvasScale = safeScale);
  }
}

enum _LayoutElementType { calendarPanel, freeBox }

class _LayoutElement {
  const _LayoutElement({
    required this.id,
    required this.type,
    required this.rect,
    required this.rotation,
    required this.label,
  });

  final String id;
  final _LayoutElementType type;
  final Rect rect;
  final double rotation;
  final String label;
}

class _LayoutGeometry {
  const _LayoutGeometry({
    required this.canvasSize,
    required this.contentRect,
    required this.calendarSlotRect,
    required this.decorationRect,
  });

  final Size canvasSize;
  final Rect contentRect;
  final Rect calendarSlotRect;
  final Rect decorationRect;
}

class _EditorActionButton extends StatelessWidget {
  const _EditorActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
