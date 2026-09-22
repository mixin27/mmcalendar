import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../services/calendar_studio_contracts.dart';

/// The single Flutter render path for editable canvases and page previews.
class CalendarStudioScene extends StatelessWidget {
  const CalendarStudioScene({
    required this.page,
    required this.source,
    this.selectedBlockId,
    this.showSafeArea = false,
    this.onSelect,
    this.dataProvider,
    this.assetStore,
    this.resolvedDays,
    this.resolvedAssets = const {},
    this.onTransform,
    this.onTransformStart,
    this.onTransformEnd,
    this.onDuplicate,
    this.onToggleLock,
    this.onToggleVisibility,
    this.onDelete,
    super.key,
  });
  final CalendarStudioPage page;
  final CalendarStudioSource source;
  final String? selectedBlockId;
  final bool showSafeArea;
  final ValueChanged<CalendarStudioBlock?>? onSelect;
  final CalendarStudioDataProvider? dataProvider;
  final CalendarStudioAssetStore? assetStore;
  final List<CalendarStudioDayData>? resolvedDays;
  final Map<String, Uint8List> resolvedAssets;
  final ValueChanged<CalendarStudioBlock>? onTransform;
  final VoidCallback? onTransformStart;
  final VoidCallback? onTransformEnd;
  final VoidCallback? onDuplicate;
  final VoidCallback? onToggleLock;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onDelete;

  static const double designWidth = 595;

  @override
  Widget build(BuildContext context) {
    final blocks = [...page.blocks]
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final designSize = Size(designWidth, designWidth / page.canvas.aspectRatio);
    return AspectRatio(
      aspectRatio: page.canvas.aspectRatio,
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox.fromSize(
          size: designSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSelect == null ? null : () => onSelect!(null),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(page.canvas.backgroundColor),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final block in blocks)
                    if (block.visible) _buildBlock(context, designSize, block),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: .75),
                              ),
                            ),
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
    );
  }

  Widget _buildBlock(
    BuildContext context,
    Size size,
    CalendarStudioBlock block,
  ) {
    final rect = block.bounds.resolve(size);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        onTap: () => onSelect?.call(block),
        onPanStart: block.locked || onTransform == null
            ? null
            : (_) => onTransformStart?.call(),
        onPanUpdate: block.locked || onTransform == null
            ? null
            : (details) {
                final bounds = block.bounds;
                onTransform!(
                  block.copyWith(
                    bounds: bounds.copyWith(
                      left: (bounds.left + details.delta.dx / size.width).clamp(
                        0,
                        1 - bounds.width,
                      ),
                      top: (bounds.top + details.delta.dy / size.height).clamp(
                        0,
                        1 - bounds.height,
                      ),
                    ),
                  ),
                );
              },
        onPanEnd: block.locked || onTransform == null
            ? null
            : (_) => onTransformEnd?.call(),
        onPanCancel: block.locked || onTransform == null
            ? null
            : onTransformEnd,
        child: Transform.rotate(
          angle: block.rotation,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: selectedBlockId == block.id
                    ? BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      )
                    : const BoxDecoration(),
                child: _contents(block),
              ),
              if (selectedBlockId == block.id &&
                  !block.locked &&
                  onTransform != null)
                for (final handle in _ResizeHandle.values)
                  _resizeHandle(context, size, block, handle),
              if (selectedBlockId == block.id && onDuplicate != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -48,
                  child: Center(
                    child: _SelectionActions(
                      locked: block.locked,
                      visible: block.visible,
                      onDuplicate: onDuplicate!,
                      onToggleLock: onToggleLock!,
                      onToggleVisibility: onToggleVisibility!,
                      onDelete: onDelete!,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resizeHandle(
    BuildContext context,
    Size size,
    CalendarStudioBlock block,
    _ResizeHandle handle,
  ) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment((handle.x - .5) * 2, (handle.y - .5) * 2),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => onTransformStart?.call(),
          onPanUpdate: (details) => onTransform!(
            block.copyWith(
              bounds: _resizeBounds(
                block.bounds,
                handle,
                details.delta.dx / size.width,
                details.delta.dy / size.height,
              ),
            ),
          ),
          onPanEnd: (_) => onTransformEnd?.call(),
          onPanCancel: onTransformEnd,
          child: Container(
            key: ValueKey('calendar-studio-resize-${handle.name}'),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  StudioRect _resizeBounds(
    StudioRect value,
    _ResizeHandle handle,
    double dx,
    double dy,
  ) {
    var left = value.left;
    var top = value.top;
    var right = value.right;
    var bottom = value.bottom;
    if (handle.x == 0) left = (left + dx).clamp(0, right - .06);
    if (handle.x == 1) right = (right + dx).clamp(left + .06, 1);
    if (handle.y == 0) top = (top + dy).clamp(0, bottom - .04);
    if (handle.y == 1) bottom = (bottom + dy).clamp(top + .04, 1);
    return StudioRect(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    );
  }

  Widget _contents(CalendarStudioBlock block) => switch (block.type) {
    CalendarStudioBlockType.calendarGrid => _CalendarGrid(
      block: block,
      source: source.copyWith(year: page.year, month: page.month),
      dataProvider: dataProvider,
      resolvedDays: resolvedDays,
    ),
    CalendarStudioBlockType.text => _TextBlock(block: block),
    CalendarStudioBlockType.shape => ColoredBox(
      color: Color((block.style['color'] as int?) ?? 0xFF0E6B5C),
    ),
    CalendarStudioBlockType.image ||
    CalendarStudioBlockType.logo => _AssetImageBlock(
      assetId: block.content['assetId'] as String?,
      assetStore: assetStore,
      resolvedBytes: resolvedAssets[block.content['assetId']],
    ),
    CalendarStudioBlockType.eventList => const _ListBlock(
      icon: Icons.event_outlined,
      label: 'My events',
    ),
    CalendarStudioBlockType.holidayLegend => const _ListBlock(
      icon: Icons.local_offer_outlined,
      label: 'Holiday legend',
    ),
    CalendarStudioBlockType.decoration => const Center(
      child: Icon(Icons.spa_outlined, color: Color(0xFFB98A25)),
    ),
  };
}

class _AssetImageBlock extends StatelessWidget {
  const _AssetImageBlock({
    required this.assetId,
    required this.assetStore,
    required this.resolvedBytes,
  });
  final String? assetId;
  final CalendarStudioAssetStore? assetStore;
  final Uint8List? resolvedBytes;

  @override
  Widget build(BuildContext context) {
    if (resolvedBytes case final bytes? when bytes.isNotEmpty) {
      return _image(bytes);
    }
    if (assetId == null || assetStore == null) return _placeholder();
    return FutureBuilder<List<int>?>(
      future: assetStore!.loadBytes(assetId!),
      builder: (_, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) return _placeholder();
        return _image(Uint8List.fromList(bytes));
      },
    );
  }

  Widget _image(Uint8List bytes) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.memory(bytes, fit: BoxFit.cover),
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
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: switch (block.style['align']) {
      'center' => Alignment.center,
      'right' => Alignment.centerRight,
      _ => Alignment.centerLeft,
    },
    child: Text(
      (block.content['text'] as String?) ?? '',
      textAlign: switch (block.style['align']) {
        'center' => TextAlign.center,
        'right' => TextAlign.right,
        _ => TextAlign.left,
      },
      style: TextStyle(
        fontFamily: block.style['fontFamily'] as String? ?? 'Noto Sans Myanmar',
        fontFamilyFallback: const ['Noto Sans Myanmar'],
        fontSize: (block.style['fontSize'] as num?)?.toDouble() ?? 20,
        fontWeight: FontWeight.w700,
        color: Color((block.style['color'] as int?) ?? 0xFF15201D),
      ),
    ),
  );
}

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

class _CalendarGrid extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final rowHeight = (block.style['rowHeight'] as num?)?.toDouble() ?? 1;
    final date = DateTime(source.year, source.month);
    final first =
        (date.weekday % 7 - (source.weekStartsMonday ? 1 : 0) + 7) % 7;
    final count = DateUtils.getDaysInMonth(source.year, source.month);
    final headers = source.weekStartsMonday
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    Widget buildGrid(List<CalendarStudioDayData>? dayData) => Column(
      children: [
        SizedBox(
          height: 30 / rowHeight.clamp(.75, 1.35),
          child: Row(
            children: [
              for (var index = 0; index < headers.length; index++)
                Expanded(
                  child: Center(
                    child: Text(
                      headers[index],
                      style: TextStyle(
                        fontFamily: 'Noto Sans Myanmar',
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                        color: index == 0 && !source.weekStartsMonday
                            ? const Color(0xFFB8322A)
                            : const Color(0xFF15201D),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              for (var row = 0; row < 6; row++)
                Expanded(
                  child: Row(
                    children: [
                      for (var column = 0; column < 7; column++)
                        Expanded(
                          child: _dayCell(
                            row * 7 + column - first + 1,
                            count,
                            dayData,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    if (resolvedDays != null) return buildGrid(resolvedDays);
    if (dataProvider == null) return buildGrid(null);
    return FutureBuilder<List<CalendarStudioDayData>>(
      future: dataProvider!.daysFor(source, month: source.month),
      builder: (_, snapshot) => buildGrid(snapshot.data),
    );
  }

  Widget _dayCell(int day, int count, List<CalendarStudioDayData>? dayData) {
    if (day < 1 || day > count) return const SizedBox();
    final sunday = DateTime(source.year, source.month, day).weekday == 7;
    final data = dayData != null && day <= dayData.length
        ? dayData[day - 1]
        : null;
    final holiday = data?.holidayLabel?.isNotEmpty ?? false;
    final gridLines = block.style['gridLines'] as String? ?? 'light';
    final holidayColor = Color(
      block.style['holidayColor'] as int? ?? 0xFFB8322A,
    );
    final numberFont = block.style['numberFont'] as String? ?? 'sans';
    final rowHeight = (block.style['rowHeight'] as num?)?.toDouble() ?? 1;
    final borderColor = const Color(0xFF15201D).withValues(alpha: .14);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: switch (gridLines) {
          'none' => null,
          'full' => Border.all(color: borderColor),
          _ => Border(top: BorderSide(color: borderColor)),
        },
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(5, 5 * rowHeight, 5, 3 * rowHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontFamily: numberFont == 'serif'
                    ? 'Georgia'
                    : 'Noto Sans Myanmar',
                fontFamilyFallback: const ['Noto Sans Myanmar'],
                fontWeight: FontWeight.w700,
                fontSize: 15,
                height: 1,
                color: sunday || holiday
                    ? holidayColor
                    : const Color(0xFF15201D),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _secondaryDayLabel(day, dayData),
                textAlign: TextAlign.right,
                maxLines: 3,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  fontFamily: 'Noto Sans Myanmar',
                  fontFamilyFallback: ['Noto Sans Myanmar'],
                  fontSize: 8.5,
                  height: 1.3,
                  color: Color(0xB315201D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _secondaryDayLabel(int day, List<CalendarStudioDayData>? values) {
    if (values == null || day > values.length) return '';
    final data = values[day - 1];
    return [
      if (source.showMyanmarDate && data.myanmarLabel != null)
        data.myanmarLabel!,
      if (source.showMoonPhases && data.moonLabel != null) data.moonLabel!,
      if (source.showHolidays && data.holidayLabel != null) data.holidayLabel!,
      if (source.showAstrology &&
          data.astrologyLabel != null &&
          data.astrologyLabel!.isNotEmpty)
        data.astrologyLabel!,
      if (source.showEvents && data.events.isNotEmpty) ...data.events,
    ].join('\n');
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
}

class _SelectionActions extends StatelessWidget {
  const _SelectionActions({
    required this.locked,
    required this.visible,
    required this.onDuplicate,
    required this.onToggleLock,
    required this.onToggleVisibility,
    required this.onDelete,
  });
  final bool locked;
  final bool visible;
  final VoidCallback onDuplicate;
  final VoidCallback onToggleLock;
  final VoidCallback onToggleVisibility;
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
