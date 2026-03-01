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
  late Map<int, List<CalendarOverlayElement>> _overlayElementsByMonth;
  late int _pageIndex;
  String? _selectedElementId;
  bool _hasChanges = false;
  double _viewerScale = 1.0;

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
  }

  @override
  void dispose() {
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
                  setState(() => _selectedElementId = null);
                },
                icon: const Icon(Icons.deselect_outlined),
                tooltip: 'Deselect element',
              ),
            IconButton(
              onPressed: _zoomOutCanvas,
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Zoom out canvas',
            ),
            Text(
              '${(_viewerScale * 100).round()}%',
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
              tooltip: 'Reset canvas transform',
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
          width: 100,
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
            child: _buildEditorCanvas(
              request: request,
              page: page,
              month: month,
              canvasSize: canvasSize,
            ),
          ),
        ),
        SizedBox(
          width: 300,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            child: _buildLayerPanel(month),
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
            child: _buildEditorCanvas(
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

  Widget _buildEditorCanvas({
    required CalendarGenerationRequest request,
    required CalendarPageModel page,
    required int month,
    required Size canvasSize,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          children: [
            _buildPageHeader(page: page),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fitScale = _resolveFitScale(
                        canvasWidth: canvasSize.width,
                        canvasHeight: canvasSize.height,
                        viewportWidth: constraints.maxWidth,
                        viewportHeight: constraints.maxHeight,
                      );
                      final displayScale = (fitScale * _viewerScale)
                          .clamp(0.1, 8.0)
                          .toDouble();
                      final displayWidth = canvasSize.width * displayScale;
                      final displayHeight = canvasSize.height * displayScale;
                      final canScrollCanvas = _selectedElementId == null;
                      final scrollPhysics = canScrollCanvas
                          ? const BouncingScrollPhysics()
                          : const NeverScrollableScrollPhysics();

                      final previewCanvas = SizedBox(
                        width: canvasSize.width,
                        height: canvasSize.height,
                        child: CalendarGenerationPreviewPage(
                          model: page,
                          request: request,
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          useCardChrome: false,
                          contentPadding: const EdgeInsets.all(12),
                          editOverlayElements: true,
                          restrictTransformToSelected: true,
                          selectedOverlayElementId: _selectedElementId,
                          onSelectedOverlayElementChanged: (id) {
                            setState(() {
                              _selectedElementId = id;
                            });
                          },
                          onOverlayElementChanged: (updated) {
                            _updateOverlayElementForMonth(
                              month: month,
                              element: updated,
                            );
                          },
                          onOverlayElementEditEnd: () {
                            setState(() {
                              _hasChanges = true;
                            });
                          },
                          onOverlayElementDoubleTap: (element) {
                            _handleOverlayElementDoubleTap(
                              month: month,
                              element: element,
                            );
                          },
                          overlayInteractionScale: displayScale,
                        ),
                      );

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: scrollPhysics,
                        child: SingleChildScrollView(
                          physics: scrollPhysics,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                              minHeight: constraints.maxHeight,
                            ),
                            child: Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: displayWidth,
                                height: displayHeight,
                                child: Transform.scale(
                                  scale: displayScale,
                                  alignment: Alignment.topLeft,
                                  child: previewCanvas,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.gesture_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Select an element first, then drag/pinch/rotate. While selected, canvas scrolling is locked to prevent drag conflicts.',
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

  Widget _buildLayerPanel(int month) {
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
                Text(
                  '${elements.length}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Top layer is at the bottom of this list.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (elements.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No elements yet.',
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
                      key: ValueKey<String>('editor_layer_${element.id}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedElementId = element.id;
                          });
                        },
                        leading: Icon(_overlayTypeIcon(element.type)),
                        title: Text(
                          _overlayElementLabel(element),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'x:${element.x.toStringAsFixed(2)}  y:${element.y.toStringAsFixed(2)}  s:${element.scale.toStringAsFixed(2)}',
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
    });
  }

  void _goNextPage() {
    setState(() {
      _pageIndex = (_safePageIndex + 1).clamp(0, widget.pages.length - 1);
      _selectedElementId = null;
    });
  }

  void _resetCanvasTransform() {
    setState(() {
      _viewerScale = 1.0;
    });
  }

  void _zoomInCanvas() {
    _setCanvasZoom(_viewerScale + 0.15);
  }

  void _zoomOutCanvas() {
    _setCanvasZoom(_viewerScale - 0.15);
  }

  void _setCanvasZoom(double zoom) {
    final clamped = zoom.clamp(0.5, 3.2).toDouble();
    setState(() {
      _viewerScale = clamped;
    });
  }

  double _resolveFitScale({
    required double canvasWidth,
    required double canvasHeight,
    required double viewportWidth,
    required double viewportHeight,
  }) {
    if (canvasWidth <= 0 ||
        canvasHeight <= 0 ||
        viewportWidth <= 0 ||
        viewportHeight <= 0) {
      return 1.0;
    }
    final scaleX = viewportWidth / canvasWidth;
    final scaleY = viewportHeight / canvasHeight;
    return scaleX < scaleY ? scaleX : scaleY;
  }

  void _finishEditing() {
    Navigator.of(context).pop(
      CalendarOverlayEditorResult(
        overlayElementsByMonth: _cloneOverlayElementsByMonth(
          _overlayElementsByMonth,
        ),
        pageIndex: _safePageIndex,
      ),
    );
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
    final offset = (list.length % 4) * 0.05;
    final centered = element.copyWith(
      x: (0.45 + offset).clamp(0.1, 0.9).toDouble(),
      y: (0.42 + offset).clamp(0.1, 0.9).toDouble(),
    );
    list.add(centered);
    setState(() {
      _hasChanges = true;
      _selectedElementId = centered.id;
      _overlayElementsByMonth[month] =
          List<CalendarOverlayElement>.unmodifiable(list);
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
      _selectedElementId = null;
      if (list.isEmpty) {
        _overlayElementsByMonth.remove(month);
      } else {
        _overlayElementsByMonth[month] = list;
      }
    });
  }

  void _handleOverlayElementDoubleTap({
    required int month,
    required CalendarOverlayElement element,
  }) {
    switch (element.type) {
      case CalendarOverlayElementType.text:
      case CalendarOverlayElementType.emoji:
        _editOverlayElementText(month: month, element: element);
      case CalendarOverlayElementType.sticker:
      case CalendarOverlayElementType.image:
        return;
    }
  }

  Future<void> _editOverlayElementText({
    required int month,
    required CalendarOverlayElement element,
  }) async {
    String inputText = element.text ?? '';
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          element.type == CalendarOverlayElementType.emoji
              ? 'Edit Emoji'
              : 'Edit Text',
        ),
        content: TextFormField(
          initialValue: inputText,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Value',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => inputText = value,
          onFieldSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(inputText),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final normalized = result?.trim() ?? '';
    if (normalized.isEmpty) {
      return;
    }
    _updateOverlayElementForMonth(
      month: month,
      element: element.copyWith(text: normalized),
    );
  }

  Future<void> _openLayersBottomSheet(int month) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: _buildLayerPanel(month),
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
    final element = list.removeAt(index);
    list.add(element);
    _applyMonthOverlayElements(
      month: month,
      elements: list,
      selectedId: elementId,
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
    final element = list.removeAt(index);
    list.insert(0, element);
    _applyMonthOverlayElements(
      month: month,
      elements: list,
      selectedId: elementId,
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
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }
    final moved = list.removeAt(oldIndex);
    list.insert(targetIndex, moved);
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

  bool _looksLikeAbsoluteLocalPath(String value) {
    if (value.startsWith('/')) {
      return true;
    }
    return RegExp(r'^[a-zA-Z]:[\\\/]').hasMatch(value);
  }
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
