import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_box_transform/flutter_box_transform.dart';

import '../models/overlay_editor_item.dart';
import '../models/overlay_editor_page_data.dart';
import '../models/overlay_editor_result.dart';

class OverlayEditorPage extends StatefulWidget {
  const OverlayEditorPage({
    required this.pages,
    required this.initialPageIndex,
    super.key,
  });

  final List<OverlayEditorPageData> pages;
  final int initialPageIndex;

  @override
  State<OverlayEditorPage> createState() => _OverlayEditorPageState();
}

class _OverlayEditorPageState extends State<OverlayEditorPage> {
  static const double _epsilon = 0.0001;
  static const double _minCanvasScale = 0.6;
  static const double _maxCanvasScale = 4.0;
  static const List<Color> _stylePresetColors = <Color>[
    Color(0xFF111827),
    Color(0xFF1F2937),
    Color(0xFF334155),
    Color(0xFFB91C1C),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFFE11D48),
    Color(0xFFFFFFFF),
    Color(0xFFFBBF24),
  ];

  static final Map<String, ImageProvider<Object>> _imageProviderCache =
      <String, ImageProvider<Object>>{};
  static final List<String> _imageProviderCacheOrder = <String>[];
  static const int _maxImageProviderCacheSize = 24;

  late final Map<int, List<OverlayEditorItem>> _itemsByPageKey;
  late int _pageIndex;
  String? _selectedItemId;
  bool _hasChanges = false;

  final TransformationController _canvasController = TransformationController();
  double _canvasScale = 1.0;

  final Map<String, TransformableBoxController> _activeControllers =
      <String, TransformableBoxController>{};
  int? _activeControllerPageKey;
  String? _interactingItemId;
  bool _updatingControllers = false;

  @override
  void initState() {
    super.initState();
    _itemsByPageKey = <int, List<OverlayEditorItem>>{};
    for (final page in widget.pages) {
      _itemsByPageKey[page.pageKey] = List<OverlayEditorItem>.unmodifiable(
        page.items,
      );
    }
    _pageIndex = widget.initialPageIndex.clamp(
      0,
      (widget.pages.length - 1).clamp(0, 999),
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

    final page = _currentPage;
    _syncControllers(page: page);
    final selectedItem = _selectedItem(page.pageKey);

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
          title: Text('Overlay Editor • ${page.title}'),
          actions: [
            if (selectedItem != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedItemId = null;
                  });
                },
                icon: const Icon(Icons.deselect_outlined),
                tooltip: 'Deselect',
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
              final wide = constraints.maxWidth >= 980;
              return wide
                  ? _buildWideLayout(page: page, selectedItem: selectedItem)
                  : _buildCompactLayout(page: page, selectedItem: selectedItem);
            },
          ),
        ),
      ),
    );
  }

  OverlayEditorPageData get _currentPage =>
      widget.pages[_pageIndex.clamp(0, widget.pages.length - 1)];

  Widget _buildWideLayout({
    required OverlayEditorPageData page,
    required OverlayEditorItem? selectedItem,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: _EditorVerticalToolbar(
            selectedItem: selectedItem,
            onAddText: () => _addText(page.pageKey),
            onAddEmoji: () => _addEmoji(page.pageKey),
            onAddSticker: () => _addSticker(page.pageKey),
            onAddImage: () => _addImage(page.pageKey),
            onToggleLock: selectedItem == null
                ? null
                : () => _toggleLock(page.pageKey),
            onDelete: selectedItem == null ? null : () => _deleteSelected(),
            onRotateLeft: selectedItem == null
                ? null
                : () => _rotateSelected(page.pageKey, -0.08),
            onRotateRight: selectedItem == null
                ? null
                : () => _rotateSelected(page.pageKey, 0.08),
            onLayers: () => _openLayersSheet(page.pageKey),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: _buildCanvasCard(page: page),
          ),
        ),
        SizedBox(
          width: 306,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            child: Column(
              children: [
                Expanded(child: _buildLayersPanel(page.pageKey)),
                if (selectedItem != null) ...[
                  const SizedBox(height: 8),
                  _buildStylePanel(page.pageKey, selectedItem),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout({
    required OverlayEditorPageData page,
    required OverlayEditorItem? selectedItem,
  }) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: _buildCanvasCard(page: page),
          ),
        ),
        if (selectedItem != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: _buildStylePanel(page.pageKey, selectedItem, compact: true),
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
                      onTap: () => _addText(page.pageKey),
                    ),
                    _SmallActionButton(
                      icon: Icons.emoji_emotions_outlined,
                      label: 'Emoji',
                      onTap: () => _addEmoji(page.pageKey),
                    ),
                    _SmallActionButton(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Sticker',
                      onTap: () => _addSticker(page.pageKey),
                    ),
                    _SmallActionButton(
                      icon: Icons.image_outlined,
                      label: 'Image',
                      onTap: () => _addImage(page.pageKey),
                    ),
                    _SmallActionButton(
                      icon: Icons.layers_outlined,
                      label: 'Layers',
                      onTap: () => _openLayersSheet(page.pageKey),
                    ),
                    _SmallActionButton(
                      icon: Icons.rotate_left,
                      label: 'Rotate -',
                      onTap: selectedItem == null
                          ? null
                          : () => _rotateSelected(page.pageKey, -0.08),
                    ),
                    _SmallActionButton(
                      icon: Icons.rotate_right,
                      label: 'Rotate +',
                      onTap: selectedItem == null
                          ? null
                          : () => _rotateSelected(page.pageKey, 0.08),
                    ),
                    _SmallActionButton(
                      icon: selectedItem?.locked == true
                          ? Icons.lock_open_outlined
                          : Icons.lock_outline,
                      label: selectedItem?.locked == true ? 'Unlock' : 'Lock',
                      onTap: selectedItem == null
                          ? null
                          : () => _toggleLock(page.pageKey),
                    ),
                    _SmallActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onTap: selectedItem == null ? null : _deleteSelected,
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

  Widget _buildCanvasCard({required OverlayEditorPageData page}) {
    final colorScheme = Theme.of(context).colorScheme;
    final panAndZoomEnabled = _selectedItemId == null;

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
                    panEnabled: panAndZoomEnabled,
                    scaleEnabled: panAndZoomEnabled,
                    child: SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: page.canvasSize.width,
                          height: page.canvasSize.height,
                          child: _buildCanvasScene(page),
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
                  panAndZoomEnabled
                      ? Icons.pan_tool_alt_outlined
                      : Icons.open_with_outlined,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    panAndZoomEnabled
                        ? 'Canvas mode: drag to pan and pinch to zoom. Tap a layer to edit it.'
                        : 'Layer mode: drag/resize selected layer. Deselect to pan/zoom canvas.',
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

  Widget _buildCanvasScene(OverlayEditorPageData page) {
    final items = _items(page.pageKey);
    final overlayRect = Rect.fromLTWH(
      page.overlayPadding.left,
      page.overlayPadding.top,
      (page.canvasSize.width - page.overlayPadding.horizontal).clamp(
        0.0,
        page.canvasSize.width,
      ),
      (page.canvasSize.height - page.overlayPadding.vertical).clamp(
        0.0,
        page.canvasSize.height,
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: page.preview),
        Positioned.fromRect(
          rect: overlayRect,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final item in items)
                _buildOverlayItem(
                  pageKey: page.pageKey,
                  item: item,
                  overlayCanvasSize: overlayRect.size,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayItem({
    required int pageKey,
    required OverlayEditorItem item,
    required Size overlayCanvasSize,
  }) {
    final isSelected = _selectedItemId == item.id;
    final natural = _naturalSize(item);
    final controller = _activeControllers[item.id];
    if (controller == null) {
      return const SizedBox.shrink();
    }

    if (!isSelected) {
      final rect = controller.rect;
      return Positioned.fromRect(
        rect: rect,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _select(item.id),
          child: _buildLayerContainer(
            item: item,
            width: rect.width,
            height: rect.height,
            selected: false,
          ),
        ),
      );
    }

    return TransformableBox(
      key: ValueKey<String>('box_${pageKey}_${item.id}'),
      controller: controller,
      allowFlippingWhileResizing: false,
      resizable: !item.locked,
      draggable: !item.locked,
      onTap: () => _select(item.id),
      onDragStart: (_) => _interactingItemId = item.id,
      onResizeStart: (_, _) => _interactingItemId = item.id,
      onChanged: (result, _) {
        _storeFromRect(pageKey, item, result.rect, natural, overlayCanvasSize);
      },
      onDragEnd: (_) {
        _interactingItemId = null;
        setState(() {});
      },
      onResizeEnd: (_, _) {
        _interactingItemId = null;
        setState(() {});
      },
      visibleHandles: item.locked
          ? const <HandlePosition>{}
          : const <HandlePosition>{
              HandlePosition.topLeft,
              HandlePosition.topRight,
              HandlePosition.bottomLeft,
              HandlePosition.bottomRight,
            },
      enabledHandles: item.locked
          ? const <HandlePosition>{}
          : const <HandlePosition>{
              HandlePosition.topLeft,
              HandlePosition.topRight,
              HandlePosition.bottomLeft,
              HandlePosition.bottomRight,
            },
      contentBuilder: (_, rect, _) => _buildLayerContainer(
        item: item,
        width: rect.width,
        height: rect.height,
        selected: true,
      ),
      cornerHandleBuilder: (context, handle) =>
          DefaultCornerHandle(handle: handle),
    );
  }

  Widget _buildLayerContainer({
    required OverlayEditorItem item,
    required double width,
    required double height,
    required bool selected,
  }) {
    final textStyle = _baseTextStyle(item);
    final iconShadows = _overlayShadows(item);
    final content = switch (item.type) {
      OverlayEditorItemType.text => Text(
        item.text?.trim().isNotEmpty == true ? item.text!.trim() : 'Text',
        textAlign: TextAlign.center,
        style: textStyle,
      ),
      OverlayEditorItemType.emoji => Text(
        item.text?.trim().isNotEmpty == true ? item.text!.trim() : '🙂',
        textAlign: TextAlign.center,
        style: textStyle.copyWith(color: null),
      ),
      OverlayEditorItemType.sticker => Icon(
        _stickerIcon(item.stickerKey),
        size: item.baseSize,
        color: Color(item.colorValue),
        shadows: iconShadows,
      ),
      OverlayEditorItemType.image => _buildImage(item),
    };

    return Opacity(
      opacity: item.opacity.clamp(0.0, 1.0),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: selected
            ? BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Transform.rotate(
          angle: item.rotation,
          child: FittedBox(fit: BoxFit.contain, child: content),
        ),
      ),
    );
  }

  Widget _buildImage(OverlayEditorItem item) {
    final provider = _parseImageProvider(item.imageSource);
    final size = item.baseSize.clamp(16, 520).toDouble();
    if (provider == null) {
      return Container(
        width: size,
        height: size,
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
      child: Image(
        image: provider,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildPageHeader({required OverlayEditorPageData page}) {
    return Row(
      children: [
        FilledButton.tonalIcon(
          onPressed: _pageIndex > 0 ? _goPreviousPage : null,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Prev'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Page ${_pageIndex + 1}/${widget.pages.length} • ${page.title}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: _pageIndex < widget.pages.length - 1 ? _goNextPage : null,
          icon: const Icon(Icons.chevron_right),
          iconAlignment: IconAlignment.end,
          label: const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildLayersPanel(int pageKey) {
    final items = _items(pageKey);
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
                    'Layers',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text('${items.length}'),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
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
                  itemCount: items.length,
                  onReorder: (oldIndex, newIndex) =>
                      _reorderItems(pageKey, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final selected = _selectedItemId == item.id;
                    return Card(
                      key: ValueKey<String>('layer_${item.id}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        selected: selected,
                        onTap: () => _select(item.id),
                        leading: Icon(_itemIcon(item.type)),
                        title: Text(
                          _itemLabel(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'x:${item.x.toStringAsFixed(2)} • y:${item.y.toStringAsFixed(2)} • s:${item.scale.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.drag_handle),
                          ),
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

  Widget _buildStylePanel(
    int pageKey,
    OverlayEditorItem item, {
    bool compact = false,
  }) {
    final supportsColor =
        item.type == OverlayEditorItemType.text ||
        item.type == OverlayEditorItemType.sticker;
    final supportsTypography =
        item.type == OverlayEditorItemType.text ||
        item.type == OverlayEditorItemType.emoji;
    final hasShadow = item.shadowColorValue != null && item.shadowBlur > 0;
    final hasBackground = item.backgroundColorValue != null;

    final panelContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Style • ${_titleCase(item.type.name)}',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _StyleSliderRow(
          label: 'Size',
          value: item.baseSize,
          min: 12,
          max: 220,
          divisions: 104,
          valueText: item.baseSize.toStringAsFixed(0),
          onChanged: (value) => _updateSelectedItem(
            pageKey,
            (selected) => selected.copyWith(baseSize: value),
          ),
        ),
        const SizedBox(height: 8),
        _StyleSliderRow(
          label: 'Opacity',
          value: item.opacity,
          min: 0.05,
          max: 1.0,
          divisions: 19,
          valueText: '${(item.opacity * 100).round()}%',
          onChanged: (value) => _updateSelectedItem(
            pageKey,
            (selected) => selected.copyWith(opacity: value),
          ),
        ),
        if (supportsColor) ...[
          const SizedBox(height: 10),
          Text('Color', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _stylePresetColors
                .map(
                  (color) => _ColorDot(
                    color: color,
                    selected: item.colorValue == color.toARGB32(),
                    onTap: () => _updateSelectedItem(
                      pageKey,
                      (selected) =>
                          selected.copyWith(colorValue: color.toARGB32()),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (supportsTypography) ...[
          const SizedBox(height: 10),
          Text('Typography', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 400, label: Text('Regular')),
              ButtonSegment<int>(value: 600, label: Text('Semi')),
              ButtonSegment<int>(value: 700, label: Text('Bold')),
              ButtonSegment<int>(value: 800, label: Text('Heavy')),
            ],
            selected: <int>{item.fontWeightValue.clamp(100, 900).toInt()},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) {
                return;
              }
              _updateSelectedItem(
                pageKey,
                (selected) =>
                    selected.copyWith(fontWeightValue: selection.first),
              );
            },
          ),
          const SizedBox(height: 6),
          SwitchListTile.adaptive(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: item.italic,
            title: const Text('Italic'),
            onChanged: (value) => _updateSelectedItem(
              pageKey,
              (selected) => selected.copyWith(italic: value),
            ),
          ),
          _StyleSliderRow(
            label: 'Letter Spacing',
            value: item.letterSpacing.clamp(-2.0, 8.0),
            min: -2.0,
            max: 8.0,
            divisions: 40,
            valueText: item.letterSpacing.toStringAsFixed(1),
            onChanged: (value) => _updateSelectedItem(
              pageKey,
              (selected) => selected.copyWith(letterSpacing: value),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: hasBackground,
            title: const Text('Text Background'),
            onChanged: (value) => _updateSelectedItem(pageKey, (selected) {
              return selected.copyWith(
                backgroundColorValue: value ? 0x1A111827 : null,
              );
            }),
          ),
          if (hasBackground)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _stylePresetColors
                  .map(
                    (color) => _ColorDot(
                      color: color,
                      selected: item.backgroundColorValue == color.toARGB32(),
                      onTap: () => _updateSelectedItem(
                        pageKey,
                        (selected) => selected.copyWith(
                          backgroundColorValue: color.toARGB32(),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: hasShadow,
          title: const Text('Shadow'),
          onChanged: (value) => _updateSelectedItem(pageKey, (selected) {
            if (!value) {
              return selected.copyWith(shadowColorValue: null, shadowBlur: 0);
            }
            return selected.copyWith(
              shadowColorValue: const Color(0x80000000).toARGB32(),
              shadowBlur: 4,
              shadowOffsetX: 0,
              shadowOffsetY: 1,
            );
          }),
        ),
        if (hasShadow) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _stylePresetColors
                .map(
                  (color) => _ColorDot(
                    color: color,
                    selected: item.shadowColorValue == color.toARGB32(),
                    onTap: () => _updateSelectedItem(
                      pageKey,
                      (selected) =>
                          selected.copyWith(shadowColorValue: color.toARGB32()),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 8),
          _StyleSliderRow(
            label: 'Shadow Blur',
            value: item.shadowBlur.clamp(0.0, 32.0),
            min: 0,
            max: 32,
            divisions: 32,
            valueText: item.shadowBlur.toStringAsFixed(1),
            onChanged: (value) => _updateSelectedItem(
              pageKey,
              (selected) => selected.copyWith(shadowBlur: value),
            ),
          ),
          _StyleSliderRow(
            label: 'Shadow Offset X',
            value: item.shadowOffsetX.clamp(-20.0, 20.0),
            min: -20,
            max: 20,
            divisions: 40,
            valueText: item.shadowOffsetX.toStringAsFixed(1),
            onChanged: (value) => _updateSelectedItem(
              pageKey,
              (selected) => selected.copyWith(shadowOffsetX: value),
            ),
          ),
          _StyleSliderRow(
            label: 'Shadow Offset Y',
            value: item.shadowOffsetY.clamp(-20.0, 20.0),
            min: -20,
            max: 20,
            divisions: 40,
            valueText: item.shadowOffsetY.toStringAsFixed(1),
            onChanged: (value) => _updateSelectedItem(
              pageKey,
              (selected) => selected.copyWith(shadowOffsetY: value),
            ),
          ),
        ],
      ],
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: compact
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: 620, child: panelContent),
              )
            : SingleChildScrollView(child: panelContent),
      ),
    );
  }

  void _updateSelectedItem(
    int pageKey,
    OverlayEditorItem Function(OverlayEditorItem item) transform,
  ) {
    final selected = _selectedItem(pageKey);
    if (selected == null) {
      return;
    }
    _storeItem(pageKey, transform(selected));
  }

  void _syncControllers({required OverlayEditorPageData page}) {
    if (_activeControllerPageKey != page.pageKey) {
      _activeControllerPageKey = page.pageKey;
      _activeControllers.clear();
      _interactingItemId = null;
    }

    final items = _items(page.pageKey);
    final ids = items.map((item) => item.id).toSet();
    _activeControllers.removeWhere((id, _) => !ids.contains(id));

    if (_selectedItemId != null && !ids.contains(_selectedItemId)) {
      _selectedItemId = null;
    }

    final overlayCanvasSize = Size(
      (page.canvasSize.width - page.overlayPadding.horizontal).clamp(
        0.0,
        page.canvasSize.width,
      ),
      (page.canvasSize.height - page.overlayPadding.vertical).clamp(
        0.0,
        page.canvasSize.height,
      ),
    );

    final clampRect = Rect.fromLTWH(
      0,
      0,
      overlayCanvasSize.width,
      overlayCanvasSize.height,
    );

    for (final item in items) {
      final rect = _rectFromItem(item, overlayCanvasSize);
      final existing = _activeControllers[item.id];
      if (existing == null) {
        _activeControllers[item.id] = TransformableBoxController(
          rect: rect,
          clampingRect: clampRect,
          constraints: BoxConstraints(
            minWidth: 24,
            minHeight: 24,
            maxWidth: overlayCanvasSize.width,
            maxHeight: overlayCanvasSize.height,
          ),
          allowFlippingWhileResizing: false,
        );
        continue;
      }

      if (_interactingItemId == item.id) {
        continue;
      }

      try {
        _updatingControllers = true;
        existing.setRect(rect, notify: false, recalculate: false);
        existing.setClampingRect(clampRect, notify: false, recalculate: false);
        existing.setConstraints(
          BoxConstraints(
            minWidth: 24,
            minHeight: 24,
            maxWidth: overlayCanvasSize.width,
            maxHeight: overlayCanvasSize.height,
          ),
          notify: false,
        );
      } finally {
        _updatingControllers = false;
      }
    }
  }

  Rect _rectFromItem(OverlayEditorItem item, Size canvasSize) {
    final natural = _naturalSize(item);
    final width = (natural.width * item.scale).clamp(24.0, 2000.0);
    final height = (natural.height * item.scale).clamp(24.0, 2000.0);
    final xRange = (canvasSize.width - natural.width).clamp(0.0, 2000.0);
    final yRange = (canvasSize.height - natural.height).clamp(0.0, 2000.0);
    final center = Offset(
      (item.x.clamp(0.0, 1.0) * xRange.toDouble()) + (natural.width / 2),
      (item.y.clamp(0.0, 1.0) * yRange.toDouble()) + (natural.height / 2),
    );
    return Rect.fromCenter(
      center: center,
      width: width.toDouble(),
      height: height.toDouble(),
    );
  }

  void _storeFromRect(
    int pageKey,
    OverlayEditorItem original,
    Rect rect,
    Size natural,
    Size overlayCanvasSize,
  ) {
    if (_updatingControllers) {
      return;
    }
    final xRange = overlayCanvasSize.width - natural.width;
    final yRange = overlayCanvasSize.height - natural.height;
    final safeXRange = xRange.abs() < _epsilon ? 1.0 : xRange;
    final safeYRange = yRange.abs() < _epsilon ? 1.0 : yRange;
    final next = original.copyWith(
      x: ((rect.center.dx - (natural.width / 2)) / safeXRange).clamp(0.0, 1.0),
      y: ((rect.center.dy - (natural.height / 2)) / safeYRange).clamp(0.0, 1.0),
      scale:
          ((((rect.width / natural.width) + (rect.height / natural.height)) / 2)
                  .clamp(0.4, 12.0))
              .toDouble(),
    );
    if (_isSameTransform(original, next)) {
      return;
    }
    _storeItem(pageKey, next, repaint: false);
  }

  bool _isSameTransform(OverlayEditorItem a, OverlayEditorItem b) {
    return (a.x - b.x).abs() < _epsilon &&
        (a.y - b.y).abs() < _epsilon &&
        (a.scale - b.scale).abs() < _epsilon &&
        (a.rotation - b.rotation).abs() < _epsilon;
  }

  Size _naturalSize(OverlayEditorItem item) {
    final baseSize = item.baseSize.clamp(12, 420).toDouble();
    final style = _baseTextStyle(item);
    return switch (item.type) {
      OverlayEditorItemType.text => _measureText(
        text: item.text?.trim().isNotEmpty == true ? item.text!.trim() : 'Text',
        style: style.copyWith(fontSize: baseSize),
        minWidth: 44,
        minHeight: 26,
      ),
      OverlayEditorItemType.emoji => _measureText(
        text: item.text?.trim().isNotEmpty == true ? item.text!.trim() : '🙂',
        style: style.copyWith(fontSize: baseSize, color: null),
        minWidth: 28,
        minHeight: 28,
      ),
      OverlayEditorItemType.sticker => Size(baseSize, baseSize),
      OverlayEditorItemType.image => Size(baseSize, baseSize),
    };
  }

  Size _measureText({
    required String text,
    required TextStyle style,
    required double minWidth,
    required double minHeight,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return Size(
      painter.width.clamp(minWidth, 1400).toDouble(),
      painter.height.clamp(minHeight, 600).toDouble(),
    );
  }

  TextStyle _baseTextStyle(OverlayEditorItem item) {
    final backgroundColor = item.backgroundColorValue == null
        ? null
        : Color(item.backgroundColorValue!);
    return TextStyle(
      color: Color(item.colorValue),
      fontSize: item.baseSize,
      fontWeight: _fontWeightFromValue(item.fontWeightValue),
      fontStyle: item.italic ? FontStyle.italic : FontStyle.normal,
      letterSpacing: item.letterSpacing,
      height: 1.0,
      backgroundColor: backgroundColor,
      shadows: _overlayShadows(item),
    );
  }

  List<Shadow>? _overlayShadows(OverlayEditorItem item) {
    final colorValue = item.shadowColorValue;
    if (colorValue == null || item.shadowBlur <= 0) {
      return null;
    }
    return <Shadow>[
      Shadow(
        color: Color(colorValue),
        blurRadius: item.shadowBlur,
        offset: Offset(item.shadowOffsetX, item.shadowOffsetY),
      ),
    ];
  }

  FontWeight _fontWeightFromValue(int value) {
    final clamped = value.clamp(100, 900);
    return FontWeight.values[(clamped ~/ 100) - 1];
  }

  List<OverlayEditorItem> _items(int pageKey) {
    return _itemsByPageKey[pageKey] ?? const <OverlayEditorItem>[];
  }

  OverlayEditorItem? _selectedItem(int pageKey) {
    final selectedId = _selectedItemId;
    if (selectedId == null) {
      return null;
    }
    for (final item in _items(pageKey)) {
      if (item.id == selectedId) {
        return item;
      }
    }
    return null;
  }

  void _storeItem(int pageKey, OverlayEditorItem item, {bool repaint = true}) {
    final list = _items(pageKey).toList(growable: true);
    final index = list.indexWhere((element) => element.id == item.id);
    if (index < 0) {
      return;
    }
    list[index] = item;
    _hasChanges = true;
    _itemsByPageKey[pageKey] = List<OverlayEditorItem>.unmodifiable(list);
    if (repaint && mounted) {
      setState(() {});
    }
  }

  Future<void> _addText(int pageKey) async {
    String value = '';
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
          onChanged: (next) => value = next,
          onSubmitted: (next) => Navigator.of(dialogContext).pop(next),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(value),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final normalized = text?.trim() ?? '';
    if (normalized.isEmpty) {
      return;
    }
    _appendItem(
      pageKey,
      OverlayEditorItem(
        id: _newId(),
        type: OverlayEditorItemType.text,
        x: 0.5,
        y: 0.5,
        scale: 1.0,
        rotation: 0.0,
        text: normalized,
        baseSize: 30,
        colorValue: 0xFF1F2937,
      ),
    );
  }

  Future<void> _addEmoji(int pageKey) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => _OverlayEmojiPackSheet(
        packs: _defaultEmojiPacks,
        onSelected: (emoji) => Navigator.of(sheetContext).pop(emoji),
      ),
    );

    if (selected == null || selected.trim().isEmpty) {
      return;
    }
    _appendItem(
      pageKey,
      OverlayEditorItem(
        id: _newId(),
        type: OverlayEditorItemType.emoji,
        x: 0.5,
        y: 0.5,
        scale: 1.0,
        rotation: 0.0,
        text: selected,
        baseSize: 34,
      ),
    );
  }

  Future<void> _addSticker(int pageKey) async {
    final selected = await showModalBottomSheet<_OverlayStickerOption>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => _OverlayStickerPackSheet(
        packs: _defaultStickerPacks,
        onSelected: (sticker) => Navigator.of(sheetContext).pop(sticker),
      ),
    );
    if (selected == null || selected.key.trim().isEmpty) {
      return;
    }
    _appendItem(
      pageKey,
      OverlayEditorItem(
        id: _newId(),
        type: OverlayEditorItemType.sticker,
        x: 0.5,
        y: 0.5,
        scale: 1.0,
        rotation: 0.0,
        stickerKey: selected.key,
        baseSize: 42,
        colorValue: selected.colorValue,
      ),
    );
  }

  Future<void> _addImage(int pageKey) async {
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

    _appendItem(
      pageKey,
      OverlayEditorItem(
        id: _newId(),
        type: OverlayEditorItemType.image,
        x: 0.5,
        y: 0.5,
        scale: 1.0,
        rotation: 0.0,
        imageSource: _normalizeImageSource(path),
        baseSize: 120,
      ),
    );
  }

  void _appendItem(int pageKey, OverlayEditorItem item) {
    final list = _items(pageKey).toList(growable: true);
    final offset = (list.length % 4) * 0.08;
    final centered = item.copyWith(
      x: (0.42 + offset).clamp(0.1, 0.9).toDouble(),
      y: (0.38 + offset).clamp(0.1, 0.9).toDouble(),
    );
    list.add(centered);
    setState(() {
      _hasChanges = true;
      _selectedItemId = centered.id;
      _itemsByPageKey[pageKey] = List<OverlayEditorItem>.unmodifiable(list);
      _activeControllerPageKey = null;
      _activeControllers.clear();
    });
  }

  void _toggleLock(int pageKey) {
    final selected = _selectedItem(pageKey);
    if (selected == null) {
      return;
    }
    _storeItem(pageKey, selected.copyWith(locked: !selected.locked));
  }

  void _rotateSelected(int pageKey, double delta) {
    final selected = _selectedItem(pageKey);
    if (selected == null) {
      return;
    }
    _storeItem(
      pageKey,
      selected.copyWith(rotation: selected.rotation + delta),
      repaint: true,
    );
  }

  void _deleteSelected() {
    final selectedId = _selectedItemId;
    if (selectedId == null) {
      return;
    }
    final pageKey = _currentPage.pageKey;
    final list = _items(
      pageKey,
    ).where((item) => item.id != selectedId).toList(growable: false);
    setState(() {
      _hasChanges = true;
      _selectedItemId = list.isEmpty ? null : list.last.id;
      _activeControllers.remove(selectedId);
      if (list.isEmpty) {
        _itemsByPageKey.remove(pageKey);
      } else {
        _itemsByPageKey[pageKey] = List<OverlayEditorItem>.unmodifiable(list);
      }
    });
  }

  void _reorderItems(int pageKey, int oldIndex, int newIndex) {
    final list = _items(pageKey).toList(growable: true);
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
    setState(() {
      _hasChanges = true;
      _selectedItemId = moved.id;
      _itemsByPageKey[pageKey] = List<OverlayEditorItem>.unmodifiable(list);
      _activeControllerPageKey = null;
      _activeControllers.clear();
    });
  }

  Future<void> _openLayersSheet(int pageKey) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: _buildLayersPanel(pageKey),
        ),
      ),
    );
  }

  void _onCanvasTransformChanged() {
    final scale = _canvasController.value.getMaxScaleOnAxis();
    if ((scale - _canvasScale).abs() < 0.01 || !mounted) {
      return;
    }
    setState(() => _canvasScale = scale);
  }

  void _zoomInCanvas() => _setCanvasScale(_canvasScale + 0.2);

  void _zoomOutCanvas() => _setCanvasScale(_canvasScale - 0.2);

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
    setState(() => _canvasScale = clamped);
  }

  void _resetCanvasTransform() {
    _canvasController.value = Matrix4.identity();
    setState(() => _canvasScale = 1.0);
  }

  void _select(String id) {
    if (_selectedItemId == id) {
      return;
    }
    setState(() {
      _selectedItemId = id;
    });
  }

  void _goPreviousPage() {
    setState(() {
      _pageIndex = (_pageIndex - 1).clamp(0, widget.pages.length - 1);
      _selectedItemId = null;
      _activeControllerPageKey = null;
      _activeControllers.clear();
      _canvasController.value = Matrix4.identity();
      _canvasScale = 1.0;
    });
  }

  void _goNextPage() {
    setState(() {
      _pageIndex = (_pageIndex + 1).clamp(0, widget.pages.length - 1);
      _selectedItemId = null;
      _activeControllerPageKey = null;
      _activeControllers.clear();
      _canvasController.value = Matrix4.identity();
      _canvasScale = 1.0;
    });
  }

  void _finishEditing() {
    Navigator.of(context).pop(
      OverlayEditorResult(
        itemsByPageKey: _itemsByPageKey,
        pageIndex: _pageIndex,
      ),
    );
  }

  Future<bool> _confirmDiscardChanges() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
      ),
    );
    return confirmed == true;
  }

  IconData _itemIcon(OverlayEditorItemType type) {
    return switch (type) {
      OverlayEditorItemType.text => Icons.text_fields,
      OverlayEditorItemType.emoji => Icons.emoji_emotions_outlined,
      OverlayEditorItemType.sticker => Icons.auto_awesome_outlined,
      OverlayEditorItemType.image => Icons.image_outlined,
    };
  }

  String _itemLabel(OverlayEditorItem item) {
    return switch (item.type) {
      OverlayEditorItemType.text =>
        'Text: ${(item.text ?? '').trim().isEmpty ? '(empty)' : item.text!.trim()}',
      OverlayEditorItemType.emoji =>
        'Emoji: ${(item.text ?? '').trim().isEmpty ? '🙂' : item.text!.trim()}',
      OverlayEditorItemType.sticker =>
        'Sticker: ${_titleCase(item.stickerKey ?? 'default')}',
      OverlayEditorItemType.image => 'Image',
    };
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _newId() => 'overlay_${DateTime.now().microsecondsSinceEpoch}';

  IconData _stickerIcon(String? key) {
    return switch (key) {
      'sparkles' => Icons.auto_awesome_rounded,
      'crown' => Icons.workspace_premium_rounded,
      'balloon' => Icons.celebration_rounded,
      'gift' => Icons.card_giftcard_rounded,
      'sun' => Icons.wb_sunny_rounded,
      'moon' => Icons.nightlight_round,
      'rainbow' => Icons.gradient_rounded,
      'camera' => Icons.camera_alt_rounded,
      'music' => Icons.music_note_rounded,
      'travel' => Icons.flight_takeoff_rounded,
      'home' => Icons.home_rounded,
      'food' => Icons.restaurant_rounded,
      'coffee' => Icons.coffee_rounded,
      'message' => Icons.chat_bubble_rounded,
      'ring' => Icons.diamond_rounded,
      'leaf' => Icons.eco_rounded,
      'paw' => Icons.pets_rounded,
      'trophy' => Icons.emoji_events_rounded,
      'star' => Icons.star_rounded,
      'heart' => Icons.favorite_rounded,
      'flower' => Icons.local_florist_rounded,
      'celebration' => Icons.celebration_rounded,
      'location' => Icons.place_rounded,
      'flag' => Icons.flag_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }

  String _normalizeImageSource(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (_isDataUrl(trimmed) || _isHttp(trimmed) || _isFileUri(trimmed)) {
      return trimmed;
    }
    if (_isAbsolutePath(trimmed)) {
      return Uri.file(trimmed).toString();
    }
    return trimmed;
  }

  ImageProvider<Object>? _parseImageProvider(String? source) {
    final normalized = _normalizeImageSource(source ?? '');
    if (normalized.isEmpty) {
      return null;
    }

    final cached = _imageProviderCache[normalized];
    if (cached != null) {
      _touchImageCacheKey(normalized);
      return cached;
    }

    ImageProvider<Object>? provider;
    if (_isDataUrl(normalized)) {
      final commaIndex = normalized.indexOf(',');
      if (commaIndex <= 0 || commaIndex == normalized.length - 1) {
        return null;
      }
      final payload = normalized.substring(commaIndex + 1);
      try {
        final bytes = base64Decode(payload);
        provider = MemoryImage(bytes);
      } catch (_) {
        provider = null;
      }
    } else if (_isHttp(normalized)) {
      provider = NetworkImage(normalized);
    } else {
      final filePath = _toFilePath(normalized);
      if (filePath == null || filePath.isEmpty) {
        return null;
      }
      final file = File(filePath);
      if (!file.existsSync()) {
        return null;
      }
      provider = FileImage(file);
    }

    if (provider == null) {
      return null;
    }

    _imageProviderCache[normalized] = provider;
    _touchImageCacheKey(normalized);
    _trimImageCache();
    return provider;
  }

  void _touchImageCacheKey(String key) {
    _imageProviderCacheOrder.remove(key);
    _imageProviderCacheOrder.add(key);
  }

  void _trimImageCache() {
    while (_imageProviderCacheOrder.length > _maxImageProviderCacheSize) {
      final evictedKey = _imageProviderCacheOrder.removeAt(0);
      _imageProviderCache.remove(evictedKey);
    }
  }

  bool _isDataUrl(String value) =>
      value.startsWith('data:image/') && value.contains(';base64,');

  bool _isHttp(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  bool _isFileUri(String value) => value.startsWith('file://');

  bool _isAbsolutePath(String value) {
    if (value.startsWith('/')) {
      return true;
    }
    return RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(value);
  }

  String? _toFilePath(String value) {
    if (value.isEmpty) {
      return null;
    }
    if (_isFileUri(value)) {
      return Uri.tryParse(value)?.toFilePath();
    }
    if (_isAbsolutePath(value)) {
      return value;
    }
    return null;
  }
}

const List<_OverlayEmojiPack> _defaultEmojiPacks = <_OverlayEmojiPack>[
  _OverlayEmojiPack(
    id: 'face',
    label: 'Faces',
    emojis: <String>[
      '😀',
      '😄',
      '🙂',
      '😉',
      '😍',
      '🥰',
      '😎',
      '🤩',
      '🥳',
      '😇',
      '🤗',
      '🥹',
    ],
  ),
  _OverlayEmojiPack(
    id: 'event',
    label: 'Events',
    emojis: <String>[
      '🎉',
      '🎊',
      '🎁',
      '🎈',
      '✨',
      '🌟',
      '🏆',
      '🎵',
      '📸',
      '📍',
      '🗓️',
      '🧧',
    ],
  ),
  _OverlayEmojiPack(
    id: 'life',
    label: 'Life',
    emojis: <String>[
      '🌙',
      '☀️',
      '🌈',
      '🌸',
      '🍀',
      '☕',
      '🍜',
      '🏡',
      '✈️',
      '💬',
      '❤️',
      '🙏',
    ],
  ),
];

const List<_OverlayStickerPack> _defaultStickerPacks = <_OverlayStickerPack>[
  _OverlayStickerPack(
    id: 'core',
    label: 'Core',
    stickers: <_OverlayStickerOption>[
      _OverlayStickerOption('star', 'Star', Icons.star_rounded, 0xFFF59E0B),
      _OverlayStickerOption(
        'heart',
        'Heart',
        Icons.favorite_rounded,
        0xFFE11D48,
      ),
      _OverlayStickerOption(
        'flower',
        'Flower',
        Icons.local_florist_rounded,
        0xFFEC4899,
      ),
      _OverlayStickerOption(
        'celebration',
        'Celebrate',
        Icons.celebration_rounded,
        0xFF7C3AED,
      ),
      _OverlayStickerOption(
        'location',
        'Location',
        Icons.place_rounded,
        0xFFDC2626,
      ),
      _OverlayStickerOption('flag', 'Flag', Icons.flag_rounded, 0xFF2563EB),
      _OverlayStickerOption(
        'sparkles',
        'Sparkle',
        Icons.auto_awesome_rounded,
        0xFFF59E0B,
      ),
      _OverlayStickerOption(
        'crown',
        'Crown',
        Icons.workspace_premium_rounded,
        0xFFCA8A04,
      ),
      _OverlayStickerOption(
        'balloon',
        'Balloon',
        Icons.celebration_rounded,
        0xFFDB2777,
      ),
      _OverlayStickerOption(
        'gift',
        'Gift',
        Icons.card_giftcard_rounded,
        0xFF059669,
      ),
    ],
  ),
  _OverlayStickerPack(
    id: 'nature',
    label: 'Nature',
    stickers: <_OverlayStickerOption>[
      _OverlayStickerOption('sun', 'Sun', Icons.wb_sunny_rounded, 0xFFF59E0B),
      _OverlayStickerOption('moon', 'Moon', Icons.nightlight_round, 0xFF4338CA),
      _OverlayStickerOption(
        'rainbow',
        'Rainbow',
        Icons.gradient_rounded,
        0xFF16A34A,
      ),
      _OverlayStickerOption('leaf', 'Leaf', Icons.eco_rounded, 0xFF16A34A),
      _OverlayStickerOption('paw', 'Pet', Icons.pets_rounded, 0xFFD97706),
    ],
  ),
  _OverlayStickerPack(
    id: 'story',
    label: 'Story',
    stickers: <_OverlayStickerOption>[
      _OverlayStickerOption(
        'camera',
        'Camera',
        Icons.camera_alt_rounded,
        0xFF0EA5E9,
      ),
      _OverlayStickerOption(
        'music',
        'Music',
        Icons.music_note_rounded,
        0xFF9333EA,
      ),
      _OverlayStickerOption(
        'travel',
        'Travel',
        Icons.flight_takeoff_rounded,
        0xFF2563EB,
      ),
      _OverlayStickerOption('home', 'Home', Icons.home_rounded, 0xFF475569),
      _OverlayStickerOption(
        'food',
        'Food',
        Icons.restaurant_rounded,
        0xFFEA580C,
      ),
      _OverlayStickerOption(
        'coffee',
        'Coffee',
        Icons.coffee_rounded,
        0xFF92400E,
      ),
      _OverlayStickerOption(
        'message',
        'Chat',
        Icons.chat_bubble_rounded,
        0xFF0EA5E9,
      ),
      _OverlayStickerOption('ring', 'Ring', Icons.diamond_rounded, 0xFF6366F1),
      _OverlayStickerOption(
        'trophy',
        'Trophy',
        Icons.emoji_events_rounded,
        0xFFF59E0B,
      ),
    ],
  ),
];

class _OverlayEmojiPack {
  const _OverlayEmojiPack({
    required this.id,
    required this.label,
    required this.emojis,
  });

  final String id;
  final String label;
  final List<String> emojis;
}

class _OverlayStickerPack {
  const _OverlayStickerPack({
    required this.id,
    required this.label,
    required this.stickers,
  });

  final String id;
  final String label;
  final List<_OverlayStickerOption> stickers;
}

class _OverlayStickerOption {
  const _OverlayStickerOption(this.key, this.label, this.icon, this.colorValue);

  final String key;
  final String label;
  final IconData icon;
  final int colorValue;
}

class _OverlayEmojiPackSheet extends StatefulWidget {
  const _OverlayEmojiPackSheet({required this.packs, required this.onSelected});

  final List<_OverlayEmojiPack> packs;
  final ValueChanged<String> onSelected;

  @override
  State<_OverlayEmojiPackSheet> createState() => _OverlayEmojiPackSheetState();
}

class _OverlayEmojiPackSheetState extends State<_OverlayEmojiPackSheet> {
  int _packIndex = 0;

  @override
  Widget build(BuildContext context) {
    final safeIndex = _packIndex.clamp(0, widget.packs.length - 1);
    final pack = widget.packs[safeIndex];
    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emoji Packs',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List<Widget>.generate(widget.packs.length, (index) {
                  final selected = index == safeIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(widget.packs[index].label),
                      selected: selected,
                      onSelected: (_) => setState(() => _packIndex = index),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: pack.emojis.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final emoji = pack.emojis[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => widget.onSelected(emoji),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 30, height: 1.0),
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
}

class _OverlayStickerPackSheet extends StatefulWidget {
  const _OverlayStickerPackSheet({
    required this.packs,
    required this.onSelected,
  });

  final List<_OverlayStickerPack> packs;
  final ValueChanged<_OverlayStickerOption> onSelected;

  @override
  State<_OverlayStickerPackSheet> createState() =>
      _OverlayStickerPackSheetState();
}

class _OverlayStickerPackSheetState extends State<_OverlayStickerPackSheet> {
  int _packIndex = 0;

  @override
  Widget build(BuildContext context) {
    final safeIndex = _packIndex.clamp(0, widget.packs.length - 1);
    final pack = widget.packs[safeIndex];
    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sticker Packs',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List<Widget>.generate(widget.packs.length, (index) {
                  final selected = index == safeIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(widget.packs[index].label),
                      selected: selected,
                      onSelected: (_) => setState(() => _packIndex = index),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: pack.stickers.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.8,
                ),
                itemBuilder: (context, index) {
                  final sticker = pack.stickers[index];
                  return OutlinedButton.icon(
                    onPressed: () => widget.onSelected(sticker),
                    icon: Icon(sticker.icon, color: Color(sticker.colorValue)),
                    label: Text(sticker.label),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleSliderRow extends StatelessWidget {
  const _StyleSliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueText,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueText;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            Text(valueText, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        Slider(
          min: min,
          max: max,
          divisions: divisions,
          value: value.clamp(min, max),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2.4 : 1.0,
          ),
        ),
      ),
    );
  }
}

class _EditorVerticalToolbar extends StatelessWidget {
  const _EditorVerticalToolbar({
    required this.selectedItem,
    required this.onAddText,
    required this.onAddEmoji,
    required this.onAddSticker,
    required this.onAddImage,
    required this.onToggleLock,
    required this.onDelete,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onLayers,
  });

  final OverlayEditorItem? selectedItem;
  final VoidCallback onAddText;
  final VoidCallback onAddEmoji;
  final VoidCallback onAddSticker;
  final VoidCallback onAddImage;
  final VoidCallback? onToggleLock;
  final VoidCallback? onDelete;
  final VoidCallback? onRotateLeft;
  final VoidCallback? onRotateRight;
  final VoidCallback onLayers;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 0, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          children: [
            _ToolbarIconButton(
              icon: Icons.text_fields,
              tooltip: 'Add text',
              onTap: onAddText,
            ),
            _ToolbarIconButton(
              icon: Icons.emoji_emotions_outlined,
              tooltip: 'Add emoji',
              onTap: onAddEmoji,
            ),
            _ToolbarIconButton(
              icon: Icons.auto_awesome_outlined,
              tooltip: 'Add sticker',
              onTap: onAddSticker,
            ),
            _ToolbarIconButton(
              icon: Icons.image_outlined,
              tooltip: 'Add image',
              onTap: onAddImage,
            ),
            const Divider(height: 18),
            _ToolbarIconButton(
              icon: Icons.layers_outlined,
              tooltip: 'Layers',
              onTap: onLayers,
            ),
            _ToolbarIconButton(
              icon: Icons.rotate_left,
              tooltip: 'Rotate left',
              onTap: onRotateLeft,
            ),
            _ToolbarIconButton(
              icon: Icons.rotate_right,
              tooltip: 'Rotate right',
              onTap: onRotateRight,
            ),
            _ToolbarIconButton(
              icon: selectedItem?.locked == true
                  ? Icons.lock_open_outlined
                  : Icons.lock_outline,
              tooltip: selectedItem?.locked == true ? 'Unlock' : 'Lock',
              onTap: onToggleLock,
            ),
            _ToolbarIconButton(
              icon: Icons.delete_outline,
              tooltip: 'Delete selected',
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
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
      padding: const EdgeInsets.symmetric(vertical: 3),
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
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
