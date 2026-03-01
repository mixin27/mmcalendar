import 'dart:convert';
import 'dart:io';

import 'package:bounding_box/bounding_box.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_image_quality.dart';
import '../../domain/entities/calendar_overlay_element.dart';
import '../../domain/entities/calendar_page_model.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import '../../rendering/export/calendar_export_layout.dart';
import '../widgets/calendar_generation_preview_page.dart';

class CalendarOverlayEditorResult {
  const CalendarOverlayEditorResult({
    required this.overlayElementsByMonth,
    required this.pageIndex,
  });

  final Map<int, List<CalendarOverlayElement>> overlayElementsByMonth;
  final int pageIndex;
}

class CalendarOverlayEditorPage extends StatefulWidget {
  const CalendarOverlayEditorPage({
    required this.request,
    required this.pages,
    required this.initialPageIndex,
    super.key,
  });

  final CalendarGenerationRequest request;
  final List<CalendarPageModel> pages;
  final int initialPageIndex;

  @override
  State<CalendarOverlayEditorPage> createState() =>
      _CalendarOverlayEditorPageState();
}

class _CalendarOverlayEditorPageState extends State<CalendarOverlayEditorPage> {
  static const double _epsilon = 0.0001;
  static const double _minCanvasScale = 0.6;
  static const double _maxCanvasScale = 4.0;

  static final Map<String, ImageProvider<Object>> _imageProviderCache =
      <String, ImageProvider<Object>>{};
  static final List<String> _imageProviderCacheOrder = <String>[];
  static const int _maxImageProviderCacheSize = 24;

  late Map<int, List<CalendarOverlayElement>> _overlayElementsByMonth;
  late int _pageIndex;
  String? _selectedElementId;
  bool _hasChanges = false;

  final TransformationController _canvasController = TransformationController();
  double _canvasScale = 1.0;

  final Map<String, BoundingBoxController> _activeControllers =
      <String, BoundingBoxController>{};
  int? _activeControllerMonth;
  bool _isSyncingControllers = false;

  @override
  void initState() {
    super.initState();
    _overlayElementsByMonth = _cloneOverlayElementsByMonth(
      widget.request.overlayElementsByMonth,
    );
    _pageIndex = widget.initialPageIndex.clamp(
      0,
      (widget.pages.length - 1).clamp(0, 9999),
    );
    _canvasController.addListener(_onCanvasTransformChanged);
  }

  @override
  void dispose() {
    _canvasController.removeListener(_onCanvasTransformChanged);
    _canvasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Overlay Editor')),
        body: const Center(child: Text('No pages available for editing.')),
      );
    }

    final page = widget.pages[_safePageIndex];
    final month = page.month;
    final selectedElement = _selectedOverlayElementForMonth(month);
    final request = widget.request.copyWith(
      overlayElementsByMonth: _overlayElementsByMonth,
    );
    final canvasSize = _resolvePreviewCanvasSize(request);

    _syncActiveControllers(
      month: month,
      canvasSize: canvasSize,
      selectedElementId: _selectedElementId,
      selectedElementLocked: selectedElement?.locked == true,
    );

    return PopScope<void>(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_hasChanges) {
          return;
        }
        final shouldDiscard = await _confirmDiscardChanges();
        if (!context.mounted || !shouldDiscard) {
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Overlay Editor • ${request.pageOrientation.label}'),
          actions: [
            if (selectedElement != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedElementId = null;
                  });
                },
                icon: const Icon(Icons.deselect_outlined),
                tooltip: 'Deselect layer',
              ),
            IconButton(
              onPressed: _zoomOutCanvas,
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Zoom out canvas',
            ),
            Text(
              '${(_canvasScale * 100).round()}%',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            IconButton(
              onPressed: _zoomInCanvas,
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Zoom in canvas',
            ),
            IconButton(
              onPressed: _resetCanvasTransform,
              icon: const Icon(Icons.center_focus_strong_outlined),
              tooltip: 'Reset canvas view',
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useWideLayout = constraints.maxWidth >= 980;
              if (useWideLayout) {
                return _buildWideLayout(
                  request: request,
                  page: page,
                  month: month,
                  canvasSize: canvasSize,
                  selectedElement: selectedElement,
                );
              }
              return _buildCompactLayout(
                request: request,
                page: page,
                month: month,
                canvasSize: canvasSize,
                selectedElement: selectedElement,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout({
    required CalendarGenerationRequest request,
    required CalendarPageModel page,
    required int month,
    required Size canvasSize,
    required CalendarOverlayElement? selectedElement,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 94,
          child: _EditorVerticalToolbar(
            selectedElement: selectedElement,
            onAddText: () => _addTextOverlayElement(month),
            onAddEmoji: () => _addEmojiOverlayElement(month),
            onAddSticker: () => _addStickerOverlayElement(month),
            onAddImage: () => _addImageOverlayElement(month),
            onBringToFront: selectedElement == null
                ? null
                : () => _bringSelectedOverlayElementToFront(month),
            onSendToBack: selectedElement == null
                ? null
                : () => _sendSelectedOverlayElementToBack(month),
            onToggleLock: selectedElement == null
                ? null
                : () => _toggleSelectedOverlayElementLock(month),
            onDelete: selectedElement == null
                ? null
                : () => _deleteSelectedOverlayElement(month),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: _buildCanvasCard(
              request: request,
              page: page,
              month: month,
              canvasSize: canvasSize,
            ),
          ),
        ),
        SizedBox(
          width: 304,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            child: _buildLayersPanel(month),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout({
    required CalendarGenerationRequest request,
    required CalendarPageModel page,
    required int month,
    required Size canvasSize,
    required CalendarOverlayElement? selectedElement,
  }) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: _buildCanvasCard(
              request: request,
              page: page,
              month: month,
              canvasSize: canvasSize,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SmallActionButton(
                      icon: Icons.text_fields,
                      label: 'Text',
                      onTap: () => _addTextOverlayElement(month),
                    ),
                    _SmallActionButton(
                      icon: Icons.emoji_emotions_outlined,
                      label: 'Emoji',
                      onTap: () => _addEmojiOverlayElement(month),
                    ),
                    _SmallActionButton(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Sticker',
                      onTap: () => _addStickerOverlayElement(month),
                    ),
                    _SmallActionButton(
                      icon: Icons.image_outlined,
                      label: 'Image',
                      onTap: () => _addImageOverlayElement(month),
                    ),
                    _SmallActionButton(
                      icon: Icons.layers_outlined,
                      label: 'Layers',
                      onTap: () => _openLayersBottomSheet(month),
                    ),
                    _SmallActionButton(
                      icon: selectedElement?.locked == true
                          ? Icons.lock_open_outlined
                          : Icons.lock_outline,
                      label: selectedElement?.locked == true
                          ? 'Unlock'
                          : 'Lock',
                      onTap: selectedElement == null
                          ? null
                          : () => _toggleSelectedOverlayElementLock(month),
                    ),
                    _SmallActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onTap: selectedElement == null
                          ? null
                          : () => _deleteSelectedOverlayElement(month),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCanvasCard({
    required CalendarGenerationRequest request,
    required CalendarPageModel page,
    required int month,
    required Size canvasSize,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final interactiveCanvas = _selectedElementId == null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          children: [
            _buildPageHeader(page: page),
            const SizedBox(height: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    transformationController: _canvasController,
                    constrained: true,
                    boundaryMargin: const EdgeInsets.all(160),
                    minScale: _minCanvasScale,
                    maxScale: _maxCanvasScale,
                    panEnabled: interactiveCanvas,
                    scaleEnabled: interactiveCanvas,
                    child: SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: canvasSize.width,
                          height: canvasSize.height,
                          child: _buildCanvasScene(
                            request: request,
                            page: page,
                            month: month,
                            canvasSize: canvasSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  interactiveCanvas
                      ? Icons.pan_tool_alt_outlined
                      : Icons.gesture_outlined,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    interactiveCanvas
                        ? 'Canvas mode: drag to pan and pinch to zoom calendar preview. Tap a layer to edit it.'
                        : 'Layer mode: drag/resize/rotate selected layer. Deselect to pan/zoom canvas.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasScene({
    required CalendarGenerationRequest request,
    required CalendarPageModel page,
    required int month,
    required Size canvasSize,
  }) {
    final elements = _elementsForMonth(month);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CalendarGenerationPreviewPage(
            model: page,
            request: request,
            margin: EdgeInsets.zero,
            elevation: 0,
            useCardChrome: false,
            contentPadding: const EdgeInsets.all(12),
            showOverlayElements: false,
          ),
        ),
        ...elements.map((element) {
          final controller = _activeControllers[element.id];
          if (controller == null) {
            return const SizedBox.shrink();
          }

          final isSelected = _selectedElementId == element.id;
          final selectorRect = _selectorRect(
            controller.position,
            controller.size,
          );

          return Stack(
            children: [
              Positioned(
                left: selectorRect.left,
                top: selectorRect.top,
                width: selectorRect.width,
                height: selectorRect.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _selectLayer(element.id),
                ),
              ),
              IgnorePointer(
                ignoring: !isSelected,
                child: BoundingBoxOverlay(
                  key: ValueKey<String>('bbox_${month}_${element.id}'),
                  controller: controller,
                  onTap: () => _selectLayer(element.id),
                  builder: (size, position, rotation) => _buildOverlayVisual(
                    element: element,
                    size: size,
                    isSelected: isSelected,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Rect _selectorRect(Offset position, Size size) {
    const inset = 14.0;
    return Rect.fromLTWH(
      position.dx - inset,
      position.dy - inset,
      size.width + (inset * 2),
      size.height + (inset * 2),
    );
  }

  Widget _buildOverlayVisual({
    required CalendarOverlayElement element,
    required Size size,
    required bool isSelected,
  }) {
    final content = switch (element.type) {
      CalendarOverlayElementType.text => FittedBox(
        fit: BoxFit.contain,
        child: Text(
          element.text?.trim().isNotEmpty == true
              ? element.text!.trim()
              : 'Text',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(element.colorValue),
            fontSize: element.baseSize,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      ),
      CalendarOverlayElementType.emoji => FittedBox(
        fit: BoxFit.contain,
        child: Text(
          element.text?.trim().isNotEmpty == true ? element.text!.trim() : '🙂',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: element.baseSize, height: 1.0),
        ),
      ),
      CalendarOverlayElementType.sticker => FittedBox(
        fit: BoxFit.contain,
        child: Icon(
          _stickerIconForKey(element.stickerKey ?? ''),
          size: element.baseSize,
          color: Color(element.colorValue),
        ),
      ),
      CalendarOverlayElementType.image => _buildOverlayImage(
        element.imageSource,
      ),
    };

    return Opacity(
      opacity: element.opacity.clamp(0.0, 1.0),
      child: Container(
        width: size.width,
        height: size.height,
        alignment: Alignment.center,
        decoration: isSelected
            ? BoxDecoration(borderRadius: BorderRadius.circular(4))
            : const BoxDecoration(),
        child: content,
      ),
    );
  }

  Widget _buildOverlayImage(String? source) {
    final provider = _parseImageProvider(source);
    if (provider == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          border: Border.all(color: const Color(0xFF9CA3AF)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 18)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image(image: provider, fit: BoxFit.cover),
    );
  }

  Widget _buildPageHeader({required CalendarPageModel page}) {
    return Row(
      children: [
        FilledButton.tonalIcon(
          onPressed: _safePageIndex > 0 ? _goPreviousPage : null,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Prev'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Page ${_safePageIndex + 1}/${widget.pages.length} • ${page.westernTitle}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: _safePageIndex < widget.pages.length - 1
              ? _goNextPage
              : null,
          icon: const Icon(Icons.chevron_right),
          iconAlignment: IconAlignment.end,
          label: const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildLayersPanel(int month) {
    final elements = _elementsForMonth(month);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Layers • Month $month',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text('${elements.length}'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Top layer is at bottom of this list.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (elements.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No overlays yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: elements.length,
                  onReorder: (oldIndex, newIndex) {
                    _reorderOverlayElements(
                      month: month,
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                    );
                  },
                  itemBuilder: (context, index) {
                    final element = elements[index];
                    final isSelected = _selectedElementId == element.id;
                    return Card(
                      key: ValueKey<String>('layer_${element.id}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        selected: isSelected,
                        onTap: () => _selectLayer(element.id),
                        leading: Icon(_overlayTypeIcon(element.type)),
                        title: Text(
                          _overlayElementLabel(element),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'x:${element.x.toStringAsFixed(2)} • y:${element.y.toStringAsFixed(2)} • s:${element.scale.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Move backward',
                              onPressed: index > 0
                                  ? () => _sendOverlayElementBackward(
                                      month: month,
                                      elementId: element.id,
                                    )
                                  : null,
                              icon: const Icon(Icons.arrow_downward_rounded),
                            ),
                            IconButton(
                              tooltip: 'Move forward',
                              onPressed: index < elements.length - 1
                                  ? () => _bringOverlayElementForward(
                                      month: month,
                                      elementId: element.id,
                                    )
                                  : null,
                              icon: const Icon(Icons.arrow_upward_rounded),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.drag_handle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  int get _safePageIndex => _pageIndex.clamp(0, widget.pages.length - 1);

  void _goPreviousPage() {
    setState(() {
      _pageIndex = (_safePageIndex - 1).clamp(0, widget.pages.length - 1);
      _selectedElementId = null;
      _activeControllerMonth = null;
      _activeControllers.clear();
      _canvasController.value = Matrix4.identity();
      _canvasScale = 1.0;
    });
  }

  void _goNextPage() {
    setState(() {
      _pageIndex = (_safePageIndex + 1).clamp(0, widget.pages.length - 1);
      _selectedElementId = null;
      _activeControllerMonth = null;
      _activeControllers.clear();
      _canvasController.value = Matrix4.identity();
      _canvasScale = 1.0;
    });
  }

  void _onCanvasTransformChanged() {
    final scale = _canvasController.value.getMaxScaleOnAxis();
    if ((scale - _canvasScale).abs() < 0.01 || !mounted) {
      return;
    }
    setState(() {
      _canvasScale = scale;
    });
  }

  void _zoomInCanvas() {
    _setCanvasScale(_canvasScale + 0.2);
  }

  void _zoomOutCanvas() {
    _setCanvasScale(_canvasScale - 0.2);
  }

  void _setCanvasScale(double target) {
    final clamped = target.clamp(_minCanvasScale, _maxCanvasScale).toDouble();
    final tx = _canvasController.value.storage[12];
    final ty = _canvasController.value.storage[13];
    _canvasController.value = Matrix4.identity()
      ..setEntry(0, 0, clamped)
      ..setEntry(1, 1, clamped)
      ..setEntry(2, 2, 1)
      ..setEntry(0, 3, tx)
      ..setEntry(1, 3, ty);
    setState(() {
      _canvasScale = clamped;
    });
  }

  void _resetCanvasTransform() {
    _canvasController.value = Matrix4.identity();
    setState(() {
      _canvasScale = 1.0;
    });
  }

  void _selectLayer(String id) {
    if (_selectedElementId == id) {
      return;
    }
    setState(() {
      _selectedElementId = id;
    });
  }

  void _finishEditing() {
    final flushedOverlayElementsByMonth = _flushActiveControllerState();
    Navigator.of(context).pop(
      CalendarOverlayEditorResult(
        overlayElementsByMonth: flushedOverlayElementsByMonth,
        pageIndex: _safePageIndex,
      ),
    );
  }

  Map<int, List<CalendarOverlayElement>> _flushActiveControllerState() {
    final copied = _cloneOverlayElementsByMonth(_overlayElementsByMonth);
    final month = _activeControllerMonth;
    if (month == null) {
      return copied;
    }

    final monthElements = copied[month];
    if (monthElements == null || monthElements.isEmpty) {
      return copied;
    }

    final request = widget.request.copyWith(overlayElementsByMonth: copied);
    final canvasSize = _resolvePreviewCanvasSize(request);
    final updated = List<CalendarOverlayElement>.from(monthElements);

    for (final entry in _activeControllers.entries) {
      final index = updated.indexWhere((element) => element.id == entry.key);
      if (index < 0) {
        continue;
      }
      updated[index] = _elementFromController(
        element: updated[index],
        controller: entry.value,
        canvasSize: canvasSize,
      );
    }

    copied[month] = List<CalendarOverlayElement>.unmodifiable(updated);
    _overlayElementsByMonth = copied;
    return copied;
  }

  Future<bool> _confirmDiscardChanges() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'You have unsaved overlay edits. Discard and leave editor?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  void _syncActiveControllers({
    required int month,
    required Size canvasSize,
    required String? selectedElementId,
    required bool selectedElementLocked,
  }) {
    if (_activeControllerMonth != month) {
      _activeControllers.clear();
      _activeControllerMonth = month;
    }

    final elements = _elementsForMonth(month);
    final ids = elements.map((e) => e.id).toSet();

    _activeControllers.removeWhere((id, _) => !ids.contains(id));

    if (_selectedElementId != null && !ids.contains(_selectedElementId)) {
      _selectedElementId = null;
    }

    final canTransformSelected =
        selectedElementId != null && selectedElementLocked == false;

    for (final element in elements) {
      final spec = _controllerSpecFromElement(element, canvasSize);
      final isSelected = selectedElementId == element.id;
      final enableTransform = isSelected && canTransformSelected;

      final existing = _activeControllers[element.id];
      if (existing == null) {
        final created = BoundingBoxController(
          position: spec.position,
          size: spec.size,
          rotation: element.rotation,
          enable: enableTransform,
          enableMove: enableTransform,
          enableRotate: enableTransform,
          actionSize: 18,
          strokeColor: const Color(0xFF2563EB),
          strokeWidth: 1.2,
          handleResizeBackgroundColor: Colors.white,
          handleResizeStrokeColor: const Color(0xFF2563EB),
          handleRotateBackgroundColor: const Color(0xFFEEF2FF),
          handleRotateStrokeColor: const Color(0xFF2563EB),
          handleMoveBackgroundColor: const Color(0xFFE0E7FF),
          handleMoveStrokeColor: const Color(0xFF2563EB),
        );

        created.addListener(() {
          _onControllerChanged(
            month: month,
            elementId: element.id,
            canvasSize: canvasSize,
          );
        });

        _activeControllers[element.id] = created;
      } else {
        _isSyncingControllers = true;
        existing.update(
          newPosition: spec.position,
          newSize: spec.size,
          newRotation: element.rotation,
          newEnable: enableTransform,
          newEnableMove: enableTransform,
          newEnableRotate: enableTransform,
        );
        _isSyncingControllers = false;
      }
    }
  }

  void _onControllerChanged({
    required int month,
    required String elementId,
    required Size canvasSize,
  }) {
    if (!mounted || _isSyncingControllers) {
      return;
    }

    final controller = _activeControllers[elementId];
    if (controller == null) {
      return;
    }

    final current = _elementsForMonth(month);
    final index = current.indexWhere((element) => element.id == elementId);
    if (index < 0) {
      return;
    }

    final original = current[index];
    final updated = _elementFromController(
      element: original,
      controller: controller,
      canvasSize: canvasSize,
    );

    if (_isSameTransform(original, updated)) {
      return;
    }

    _updateOverlayElementForMonth(month: month, element: updated);
  }

  _ControllerSpec _controllerSpecFromElement(
    CalendarOverlayElement element,
    Size canvasSize,
  ) {
    final natural = _naturalElementSize(element);
    final width = (natural.width * element.scale).clamp(24.0, 1800.0);
    final height = (natural.height * element.scale).clamp(24.0, 1800.0);
    final centerX = element.x.clamp(0.0, 1.0) * canvasSize.width;
    final centerY = element.y.clamp(0.0, 1.0) * canvasSize.height;

    return _ControllerSpec(
      position: Offset(centerX - (width / 2), centerY - (height / 2)),
      size: Size(width, height),
    );
  }

  CalendarOverlayElement _elementFromController({
    required CalendarOverlayElement element,
    required BoundingBoxController controller,
    required Size canvasSize,
  }) {
    final natural = _naturalElementSize(element);
    final scaleW = controller.size.width / natural.width;
    final scaleH = controller.size.height / natural.height;
    final nextScale = ((scaleW + scaleH) / 2).clamp(0.2, 8.0).toDouble();

    final centerX = controller.position.dx + (controller.size.width / 2);
    final centerY = controller.position.dy + (controller.size.height / 2);

    return element.copyWith(
      x: (centerX / canvasSize.width).clamp(0.0, 1.0).toDouble(),
      y: (centerY / canvasSize.height).clamp(0.0, 1.0).toDouble(),
      scale: nextScale,
      rotation: controller.rotation,
    );
  }

  bool _isSameTransform(
    CalendarOverlayElement left,
    CalendarOverlayElement right,
  ) {
    return (left.x - right.x).abs() < _epsilon &&
        (left.y - right.y).abs() < _epsilon &&
        (left.scale - right.scale).abs() < _epsilon &&
        (left.rotation - right.rotation).abs() < _epsilon;
  }

  Size _naturalElementSize(CalendarOverlayElement element) {
    final baseSize = element.baseSize.clamp(12, 420).toDouble();
    return switch (element.type) {
      CalendarOverlayElementType.text => _textNaturalSize(
        text: element.text,
        baseSize: baseSize,
      ),
      CalendarOverlayElementType.emoji => Size(baseSize * 1.5, baseSize * 1.5),
      CalendarOverlayElementType.sticker => Size(
        baseSize * 1.8,
        baseSize * 1.8,
      ),
      CalendarOverlayElementType.image => Size(baseSize, baseSize),
    };
  }

  Size _textNaturalSize({required String? text, required double baseSize}) {
    final length = (text?.trim().isNotEmpty ?? false) ? text!.trim().length : 4;
    final width = ((length.clamp(1, 32)) * baseSize * 0.62 + 28)
        .clamp(88.0, 760.0)
        .toDouble();
    final height = (baseSize * 1.75).clamp(42.0, 260.0).toDouble();
    return Size(width, height);
  }

  List<CalendarOverlayElement> _elementsForMonth(int month) {
    return _overlayElementsByMonth[month] ?? const <CalendarOverlayElement>[];
  }

  CalendarOverlayElement? _selectedOverlayElementForMonth(int month) {
    final selectedId = _selectedElementId;
    if (selectedId == null) {
      return null;
    }
    for (final element in _elementsForMonth(month)) {
      if (element.id == selectedId) {
        return element;
      }
    }
    return null;
  }

  void _updateOverlayElementForMonth({
    required int month,
    required CalendarOverlayElement element,
  }) {
    final list = _elementsForMonth(month).toList(growable: true);
    final index = list.indexWhere((item) => item.id == element.id);
    if (index < 0) {
      return;
    }

    list[index] = element;
    setState(() {
      _hasChanges = true;
      _overlayElementsByMonth[month] =
          List<CalendarOverlayElement>.unmodifiable(list);
    });
  }

  Future<void> _addTextOverlayElement(int month) async {
    String inputText = '';
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Text'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Text',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => inputText = value,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(inputText),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    final normalized = text?.trim() ?? '';
    if (normalized.isEmpty) {
      return;
    }

    _appendOverlayElement(
      month,
      CalendarOverlayElement(
        id: _newOverlayElementId(),
        type: CalendarOverlayElementType.text,
        x: 0.5,
        y: 0.5,
        scale: 1.0,
        rotation: 0.0,
        text: normalized,
        colorValue: 0xFF1F2937,
        baseSize: 28,
      ),
    );
  }

  Future<void> _addEmojiOverlayElement(int month) async {
    const emojis = <String>[
      '😀',
      '🙂',
      '😎',
      '😍',
      '🎉',
      '🔥',
      '🌙',
      '⭐',
      '🙏',
      '📌',
      '🧧',
      '🎁',
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: GridView.count(
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: emojis
              .map(
                (emoji) => InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(sheetContext).pop(emoji),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 30, height: 1.0),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );

    if (selected == null || selected.trim().isEmpty) {
      return;
    }

    _appendOverlayElement(
      month,
      CalendarOverlayElement(
        id: _newOverlayElementId(),
        type: CalendarOverlayElementType.emoji,
        x: 0.5,
        y: 0.5,
        scale: 1.0,
        rotation: 0.0,
        text: selected,
        baseSize: 34,
      ),
    );
  }

  Future<void> _addStickerOverlayElement(int month) async {
    const stickerKeys = <String>[
      'star',
      'heart',
      'flower',
      'celebration',
      'location',
      'flag',
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: stickerKeys
              .map(
                (key) => OutlinedButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop(key),
                  icon: Icon(_stickerIconForKey(key)),
                  label: Text(key.capitalize),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );

    if (selected == null || selected.trim().isEmpty) {
      return;
    }

    _appendOverlayElement(
      month,
      CalendarOverlayElement(
        id: _newOverlayElementId(),
        type: CalendarOverlayElementType.sticker,
        x: 0.5,
        y: 0.5,
        scale: 1.0,
        rotation: 0.0,
        stickerKey: selected,
        colorValue: 0xFF2563EB,
        baseSize: 42,
      ),
    );
  }

  Future<void> _addImageOverlayElement(int month) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final path = result.files.first.path?.trim();
    if (path == null || path.isEmpty) {
      return;
    }

    _appendOverlayElement(
      month,
      CalendarOverlayElement(
        id: _newOverlayElementId(),
        type: CalendarOverlayElementType.image,
        x: 0.5,
        y: 0.5,
        scale: 1.0,
        rotation: 0.0,
        imageSource: _normalizeImageSource(path),
        baseSize: 120,
      ),
    );
  }

  void _appendOverlayElement(int month, CalendarOverlayElement element) {
    final list = _elementsForMonth(month).toList(growable: true);
    final offset = (list.length % 4) * 0.08;
    final centered = element.copyWith(
      x: (0.42 + offset).clamp(0.1, 0.9).toDouble(),
      y: (0.38 + offset).clamp(0.1, 0.9).toDouble(),
    );

    list.add(centered);
    setState(() {
      _hasChanges = true;
      _selectedElementId = centered.id;
      _overlayElementsByMonth[month] =
          List<CalendarOverlayElement>.unmodifiable(list);
      _activeControllerMonth = null;
      _activeControllers.clear();
    });
  }

  void _toggleSelectedOverlayElementLock(int month) {
    final selected = _selectedOverlayElementForMonth(month);
    if (selected == null) {
      return;
    }

    _updateOverlayElementForMonth(
      month: month,
      element: selected.copyWith(locked: !selected.locked),
    );
  }

  void _deleteSelectedOverlayElement(int month) {
    final selectedId = _selectedElementId;
    if (selectedId == null) {
      return;
    }

    final list = _elementsForMonth(
      month,
    ).where((element) => element.id != selectedId).toList(growable: false);

    setState(() {
      _hasChanges = true;
      _selectedElementId = list.isEmpty ? null : list.last.id;
      _activeControllers.remove(selectedId);
      if (list.isEmpty) {
        _overlayElementsByMonth.remove(month);
      } else {
        _overlayElementsByMonth[month] = list;
      }
    });
  }

  Future<void> _openLayersBottomSheet(int month) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: _buildLayersPanel(month),
          ),
        );
      },
    );
  }

  void _bringSelectedOverlayElementToFront(int month) {
    final selectedId = _selectedElementId;
    if (selectedId == null) {
      return;
    }
    _moveOverlayElementToFront(month: month, elementId: selectedId);
  }

  void _sendSelectedOverlayElementToBack(int month) {
    final selectedId = _selectedElementId;
    if (selectedId == null) {
      return;
    }
    _moveOverlayElementToBack(month: month, elementId: selectedId);
  }

  void _moveOverlayElementToFront({
    required int month,
    required String elementId,
  }) {
    final list = _elementsForMonth(month).toList(growable: true);
    final index = list.indexWhere((item) => item.id == elementId);
    if (index < 0 || index == list.length - 1) {
      return;
    }

    final moved = list.removeAt(index);
    list.add(moved);
    _applyMonthOverlayElements(
      month: month,
      elements: list,
      selectedId: moved.id,
    );
  }

  void _moveOverlayElementToBack({
    required int month,
    required String elementId,
  }) {
    final list = _elementsForMonth(month).toList(growable: true);
    final index = list.indexWhere((item) => item.id == elementId);
    if (index <= 0) {
      return;
    }

    final moved = list.removeAt(index);
    list.insert(0, moved);
    _applyMonthOverlayElements(
      month: month,
      elements: list,
      selectedId: moved.id,
    );
  }

  void _bringOverlayElementForward({
    required int month,
    required String elementId,
  }) {
    final list = _elementsForMonth(month).toList(growable: true);
    final index = list.indexWhere((item) => item.id == elementId);
    if (index < 0 || index >= list.length - 1) {
      return;
    }

    final current = list[index];
    list[index] = list[index + 1];
    list[index + 1] = current;
    _applyMonthOverlayElements(
      month: month,
      elements: list,
      selectedId: elementId,
    );
  }

  void _sendOverlayElementBackward({
    required int month,
    required String elementId,
  }) {
    final list = _elementsForMonth(month).toList(growable: true);
    final index = list.indexWhere((item) => item.id == elementId);
    if (index <= 0) {
      return;
    }

    final current = list[index];
    list[index] = list[index - 1];
    list[index - 1] = current;
    _applyMonthOverlayElements(
      month: month,
      elements: list,
      selectedId: elementId,
    );
  }

  void _reorderOverlayElements({
    required int month,
    required int oldIndex,
    required int newIndex,
  }) {
    final list = _elementsForMonth(month).toList(growable: true);
    if (oldIndex < 0 ||
        oldIndex >= list.length ||
        newIndex < 0 ||
        newIndex > list.length) {
      return;
    }

    var target = newIndex;
    if (target > oldIndex) {
      target -= 1;
    }

    final moved = list.removeAt(oldIndex);
    list.insert(target, moved);
    _applyMonthOverlayElements(
      month: month,
      elements: list,
      selectedId: moved.id,
    );
  }

  void _applyMonthOverlayElements({
    required int month,
    required List<CalendarOverlayElement> elements,
    String? selectedId,
  }) {
    setState(() {
      _hasChanges = true;
      _selectedElementId = selectedId ?? _selectedElementId;
      _activeControllerMonth = null;
      _activeControllers.clear();
      if (elements.isEmpty) {
        _overlayElementsByMonth.remove(month);
      } else {
        _overlayElementsByMonth[month] =
            List<CalendarOverlayElement>.unmodifiable(elements);
      }
    });
  }

  Size _resolvePreviewCanvasSize(CalendarGenerationRequest request) {
    final imageSize = CalendarExportLayout.resolveImageSize(request);
    final divisor = request.imageQuality == CalendarImageQuality.print
        ? 4.0
        : 2.0;
    return Size(imageSize.width / divisor, imageSize.height / divisor);
  }

  IconData _overlayTypeIcon(CalendarOverlayElementType type) {
    return switch (type) {
      CalendarOverlayElementType.text => Icons.text_fields,
      CalendarOverlayElementType.emoji => Icons.emoji_emotions_outlined,
      CalendarOverlayElementType.sticker => Icons.auto_awesome_outlined,
      CalendarOverlayElementType.image => Icons.image_outlined,
    };
  }

  String _overlayElementLabel(CalendarOverlayElement element) {
    return switch (element.type) {
      CalendarOverlayElementType.text =>
        'Text: ${(element.text ?? '').trim().isEmpty ? '(empty)' : element.text!.trim()}',
      CalendarOverlayElementType.emoji =>
        'Emoji: ${(element.text ?? '').trim().isEmpty ? '🙂' : element.text!.trim()}',
      CalendarOverlayElementType.sticker =>
        'Sticker: ${(element.stickerKey ?? 'default').capitalize}',
      CalendarOverlayElementType.image => 'Image',
    };
  }

  String _newOverlayElementId() {
    return 'overlay_${DateTime.now().microsecondsSinceEpoch}';
  }

  IconData _stickerIconForKey(String key) {
    return switch (key) {
      'star' => Icons.star_rounded,
      'heart' => Icons.favorite_rounded,
      'flower' => Icons.local_florist_rounded,
      'celebration' => Icons.celebration_rounded,
      'location' => Icons.place_rounded,
      'flag' => Icons.flag_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }

  Map<int, List<CalendarOverlayElement>> _cloneOverlayElementsByMonth(
    Map<int, List<CalendarOverlayElement>> source,
  ) {
    final copied = <int, List<CalendarOverlayElement>>{};
    for (final entry in source.entries) {
      copied[entry.key] = List<CalendarOverlayElement>.from(entry.value);
    }
    return copied;
  }

  String _normalizeImageSource(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.hasScheme) {
      return normalized;
    }

    if (_looksLikeAbsoluteLocalPath(normalized)) {
      return Uri.file(normalized).toString();
    }

    return normalized;
  }

  ImageProvider<Object>? _parseImageProvider(String? source) {
    final normalized = source?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    final cached = _imageProviderCache[normalized];
    if (cached != null) {
      return cached;
    }

    if (normalized.startsWith('data:image/') &&
        normalized.contains(';base64,')) {
      final start = normalized.indexOf('base64,');
      if (start < 0) {
        return null;
      }
      try {
        final bytes = base64Decode(normalized.substring(start + 7));
        final provider = MemoryImage(bytes);
        _rememberProvider(normalized, provider);
        return provider;
      } catch (_) {
        return null;
      }
    }

    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.scheme == 'file') {
      try {
        final provider = FileImage(File(uri.toFilePath()));
        _rememberProvider(normalized, provider);
        return provider;
      } catch (_) {
        return null;
      }
    }

    if (_looksLikeAbsoluteLocalPath(normalized)) {
      final provider = FileImage(File(normalized));
      _rememberProvider(normalized, provider);
      return provider;
    }

    if (uri != null &&
        uri.hasScheme &&
        uri.scheme != 'http' &&
        uri.scheme != 'https') {
      return null;
    }

    final provider = NetworkImage(normalized);
    _rememberProvider(normalized, provider);
    return provider;
  }

  void _rememberProvider(String source, ImageProvider<Object> provider) {
    if (_imageProviderCache.containsKey(source)) {
      _imageProviderCache[source] = provider;
      return;
    }

    _imageProviderCache[source] = provider;
    _imageProviderCacheOrder.add(source);
    if (_imageProviderCacheOrder.length > _maxImageProviderCacheSize) {
      final evictedKey = _imageProviderCacheOrder.removeAt(0);
      _imageProviderCache.remove(evictedKey);
    }
  }

  bool _looksLikeAbsoluteLocalPath(String value) {
    if (value.startsWith('/')) {
      return true;
    }
    return RegExp(r'^[a-zA-Z]:[\\\/]').hasMatch(value);
  }
}

class _ControllerSpec {
  const _ControllerSpec({required this.position, required this.size});

  final Offset position;
  final Size size;
}

class _EditorVerticalToolbar extends StatelessWidget {
  const _EditorVerticalToolbar({
    required this.selectedElement,
    required this.onAddText,
    required this.onAddEmoji,
    required this.onAddSticker,
    required this.onAddImage,
    required this.onBringToFront,
    required this.onSendToBack,
    required this.onToggleLock,
    required this.onDelete,
  });

  final CalendarOverlayElement? selectedElement;
  final VoidCallback onAddText;
  final VoidCallback onAddEmoji;
  final VoidCallback onAddSticker;
  final VoidCallback onAddImage;
  final VoidCallback? onBringToFront;
  final VoidCallback? onSendToBack;
  final VoidCallback? onToggleLock;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: 8),
              _IconOnlyToolButton(
                icon: Icons.text_fields,
                tooltip: 'Add text',
                onTap: onAddText,
              ),
              _IconOnlyToolButton(
                icon: Icons.emoji_emotions_outlined,
                tooltip: 'Add emoji',
                onTap: onAddEmoji,
              ),
              _IconOnlyToolButton(
                icon: Icons.auto_awesome_outlined,
                tooltip: 'Add sticker',
                onTap: onAddSticker,
              ),
              _IconOnlyToolButton(
                icon: Icons.image_outlined,
                tooltip: 'Add image',
                onTap: onAddImage,
              ),
              const Divider(height: 14),
              _IconOnlyToolButton(
                icon: Icons.vertical_align_top,
                tooltip: 'Bring to front',
                onTap: onBringToFront,
              ),
              _IconOnlyToolButton(
                icon: Icons.vertical_align_bottom,
                tooltip: 'Send to back',
                onTap: onSendToBack,
              ),
              _IconOnlyToolButton(
                icon: selectedElement?.locked == true
                    ? Icons.lock_open_outlined
                    : Icons.lock_outline,
                tooltip: selectedElement?.locked == true
                    ? 'Unlock element'
                    : 'Lock element',
                onTap: onToggleLock,
              ),
              _IconOnlyToolButton(
                icon: Icons.delete_outline,
                tooltip: 'Delete selected element',
                onTap: onDelete,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
                child: Text(
                  selectedElement == null
                      ? 'No selection'
                      : 'Selected\n${selectedElement!.type.name}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconOnlyToolButton extends StatelessWidget {
  const _IconOnlyToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: IconButton(onPressed: onTap, tooltip: tooltip, icon: Icon(icon)),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
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
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
