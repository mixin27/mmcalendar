import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_landscape_decoration_area_side.dart';
import '../../domain/entities/calendar_overlay_element.dart';
import '../../domain/entities/calendar_page_model.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import '../../domain/entities/calendar_preview_theme.dart';
import '../../rendering/export/calendar_export_layout.dart';

class CalendarGenerationPreviewPage extends StatelessWidget {
  const CalendarGenerationPreviewPage({
    required this.model,
    required this.request,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.elevation = 2,
    this.contentPadding = const EdgeInsets.all(12),
    this.compact = false,
    this.useCardChrome = true,
    this.backgroundImageProvider,
    this.showOverlayElements = true,
    this.editOverlayElements = false,
    this.selectedOverlayElementId,
    this.onSelectedOverlayElementChanged,
    this.onOverlayElementChanged,
    this.onOverlayElementEditEnd,
    super.key,
  });

  static final Map<String, ImageProvider<Object>> _imageProviderCache =
      <String, ImageProvider<Object>>{};
  static final List<String> _imageProviderCacheOrder = <String>[];
  static const int _maxImageProviderCacheSize = 24;

  final CalendarPageModel model;
  final CalendarGenerationRequest request;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final EdgeInsetsGeometry contentPadding;
  final bool compact;
  final bool useCardChrome;
  final ImageProvider<Object>? backgroundImageProvider;
  final bool showOverlayElements;
  final bool editOverlayElements;
  final String? selectedOverlayElementId;
  final ValueChanged<String?>? onSelectedOverlayElementChanged;
  final ValueChanged<CalendarOverlayElement>? onOverlayElementChanged;
  final VoidCallback? onOverlayElementEditEnd;

  @override
  Widget build(BuildContext context) {
    final theme = request.theme;
    final backgroundColor = Color(theme.backgroundColorValue);
    final foregroundColor = Color(theme.foregroundColorValue);
    const holidayColor = Color(0xFFC62828);
    const fullMoonColor = Color(0xFFB45309);
    const newMoonColor = Color(0xFF4338CA);
    final aspectRatio = CalendarExportLayout.previewAspectRatio(request);
    final pageBackgroundImage = theme.backgroundImageUrlForMonth(model.month);
    final imageProvider =
        backgroundImageProvider ?? _parseImageProvider(pageBackgroundImage);

    final titleFontSize = compact ? 13.0 : 20.0;
    final weekdayFontSize = compact ? 9.0 : 13.0;
    final westernDayFontSize = compact ? 20.0 : 34.0;
    final myanmarDayFontSize = compact ? 7.0 : 11.5;
    final dayPadding = compact ? 2.0 : 4.0;
    final dayRadius = compact ? 3.0 : 4.0;
    final gridSpacing = compact ? 1.5 : 2.0;
    final gridAspectRatioFallback = compact ? 0.8 : 0.86;
    final visibleRows = _visibleRowCount(model.dayCells);
    final visibleCellCount = visibleRows * 7;
    final isLandscape =
        request.pageOrientation == CalendarPageOrientation.landscape;
    final isDecorationOnLeft =
        request.landscapeDecorationAreaSide ==
        CalendarLandscapeDecorationAreaSide.left;
    final portraitCalendarFlex = compact ? 80 : 72;
    final portraitDecorationFlex = 100 - portraitCalendarFlex;
    final landscapeCalendarFlex = compact ? 80 : 76;
    final landscapeDecorationFlex = 100 - landscapeCalendarFlex;
    final overlayElements =
        request.overlayElementsByMonth[model.month] ??
        const <CalendarOverlayElement>[];

    final previewBody = AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          image: imageProvider == null
              ? null
              : DecorationImage(
                  image: imageProvider,
                  fit: _toFlutterFit(theme.backgroundImageFit),
                  alignment: _toFlutterAlignment(
                    theme.backgroundImageAlignment,
                  ),
                  opacity: theme.backgroundImageOpacity.clamp(0.0, 1.0),
                ),
        ),
        child: Padding(
          padding: contentPadding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pageContent = Column(
                children: [
                  Text(
                    model.westernTitle,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!compact &&
                      request.showMyanmarDates &&
                      model.myanmarTitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      model.myanmarTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foregroundColor.withValues(alpha: 0.82),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  SizedBox(height: compact ? 4 : 8),
                  Expanded(
                    child: isLandscape
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (isDecorationOnLeft)
                                Expanded(
                                  flex: landscapeDecorationFlex,
                                  child: _buildCustomDecorationArea(
                                    backgroundColor: backgroundColor,
                                    foregroundColor: foregroundColor,
                                  ),
                                ),
                              if (isDecorationOnLeft)
                                SizedBox(width: compact ? 4 : 8),
                              Expanded(
                                flex: landscapeCalendarFlex,
                                child: Column(
                                  children: [
                                    _WeekdayHeader(
                                      labels: model.weekdayLabels,
                                      foregroundColor: foregroundColor,
                                      fontSize: weekdayFontSize,
                                    ),
                                    SizedBox(height: compact ? 3 : 6),
                                    Expanded(
                                      child: _buildCalendarGrid(
                                        backgroundColor: backgroundColor,
                                        foregroundColor: foregroundColor,
                                        holidayColor: holidayColor,
                                        fullMoonColor: fullMoonColor,
                                        newMoonColor: newMoonColor,
                                        dayRadius: dayRadius,
                                        dayPadding: dayPadding,
                                        gridSpacing: gridSpacing,
                                        gridAspectRatioFallback:
                                            gridAspectRatioFallback,
                                        visibleRows: visibleRows,
                                        visibleCellCount: visibleCellCount,
                                        westernDayFontSize: westernDayFontSize,
                                        myanmarDayFontSize: myanmarDayFontSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isDecorationOnLeft)
                                SizedBox(width: compact ? 4 : 8),
                              if (!isDecorationOnLeft)
                                Expanded(
                                  flex: landscapeDecorationFlex,
                                  child: _buildCustomDecorationArea(
                                    backgroundColor: backgroundColor,
                                    foregroundColor: foregroundColor,
                                  ),
                                ),
                            ],
                          )
                        : Column(
                            children: [
                              _WeekdayHeader(
                                labels: model.weekdayLabels,
                                foregroundColor: foregroundColor,
                                fontSize: weekdayFontSize,
                              ),
                              SizedBox(height: compact ? 3 : 6),
                              Expanded(
                                flex: portraitCalendarFlex,
                                child: _buildCalendarGrid(
                                  backgroundColor: backgroundColor,
                                  foregroundColor: foregroundColor,
                                  holidayColor: holidayColor,
                                  fullMoonColor: fullMoonColor,
                                  newMoonColor: newMoonColor,
                                  dayRadius: dayRadius,
                                  dayPadding: dayPadding,
                                  gridSpacing: gridSpacing,
                                  gridAspectRatioFallback:
                                      gridAspectRatioFallback,
                                  visibleRows: visibleRows,
                                  visibleCellCount: visibleCellCount,
                                  westernDayFontSize: westernDayFontSize,
                                  myanmarDayFontSize: myanmarDayFontSize,
                                ),
                              ),
                              SizedBox(height: compact ? 4 : 8),
                              Expanded(
                                flex: portraitDecorationFlex,
                                child: _buildCustomDecorationArea(
                                  backgroundColor: backgroundColor,
                                  foregroundColor: foregroundColor,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              );

              if (!showOverlayElements || overlayElements.isEmpty) {
                return pageContent;
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  pageContent,
                  _OverlayElementsLayer(
                    elements: overlayElements,
                    canvasWidth: constraints.maxWidth,
                    canvasHeight: constraints.maxHeight,
                    editMode: editOverlayElements && !compact,
                    selectedElementId: selectedOverlayElementId,
                    onSelectedElementChanged: onSelectedOverlayElementChanged,
                    onElementChanged: onOverlayElementChanged,
                    onElementEditEnd: onOverlayElementEditEnd,
                    buildElementChild: (element, isSelected) =>
                        _buildOverlayElementVisual(
                          element,
                          foregroundColor: foregroundColor,
                          isSelected: isSelected,
                        ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    if (!useCardChrome) {
      return previewBody;
    }
    return Card(margin: margin, elevation: elevation, child: previewBody);
  }

  Widget _buildOverlayElementVisual(
    CalendarOverlayElement element, {
    required Color foregroundColor,
    required bool isSelected,
  }) {
    final content = switch (element.type) {
      CalendarOverlayElementType.text => Text(
        element.text?.trim().isNotEmpty == true ? element.text!.trim() : 'Text',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(element.colorValue),
          fontSize: element.baseSize,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
      CalendarOverlayElementType.emoji => Text(
        element.text?.trim().isNotEmpty == true ? element.text!.trim() : '🙂',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: element.baseSize, height: 1.0),
      ),
      CalendarOverlayElementType.sticker => Icon(
        _resolveStickerIcon(element.stickerKey),
        size: element.baseSize,
        color: Color(element.colorValue),
      ),
      CalendarOverlayElementType.image => _buildOverlayImage(element),
    };

    return Opacity(
      opacity: element.opacity.clamp(0.0, 1.0),
      child: DecoratedBox(
        decoration: isSelected
            ? BoxDecoration(
                border: Border.all(
                  color: foregroundColor.withValues(alpha: 0.75),
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(4),
              )
            : const BoxDecoration(),
        child: Padding(
          padding: isSelected
              ? const EdgeInsets.symmetric(horizontal: 3, vertical: 2)
              : EdgeInsets.zero,
          child: content,
        ),
      ),
    );
  }

  Widget _buildOverlayImage(CalendarOverlayElement element) {
    final provider = _parseImageProvider(element.imageSource);
    final size = element.baseSize.clamp(16, 520).toDouble();
    if (provider == null) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF9CA3AF)),
          borderRadius: BorderRadius.circular(6),
          color: Colors.white.withValues(alpha: 0.82),
        ),
        child: const Icon(Icons.broken_image_outlined, size: 18),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image(
        image: provider,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }

  IconData _resolveStickerIcon(String? key) {
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

  Widget _buildCellMetaText({required CalendarDayCellModel day}) {
    final holidayText = request.showHolidays
        ? day.publicHolidayLabel?.trim()
        : null;
    final astroTexts = <String>[
      if (day.sabbathLabel?.trim().isNotEmpty ?? false)
        day.sabbathLabel!.trim(),
      if (day.sabbathEveLabel?.trim().isNotEmpty ?? false)
        day.sabbathEveLabel!.trim(),
      if (day.yatyazaLabel?.trim().isNotEmpty ?? false)
        day.yatyazaLabel!.trim(),
      if (day.pyathadaLabel?.trim().isNotEmpty ?? false)
        day.pyathadaLabel!.trim(),
      if (day.afternoonPyathadaLabel?.trim().isNotEmpty ?? false)
        day.afternoonPyathadaLabel!.trim(),
      if (day.otherAstrologyLabel?.trim().isNotEmpty ?? false)
        day.otherAstrologyLabel!.trim(),
    ];
    final astroText = request.showAstrology && astroTexts.isNotEmpty
        ? astroTexts.join(' • ')
        : null;

    if ((holidayText == null || holidayText.isEmpty) &&
        (astroText == null || astroText.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (holidayText != null && holidayText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.2),
              decoration: BoxDecoration(
                color: const Color(0xFFC62828).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                holidayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFC62828).withValues(alpha: 0.95),
                  fontSize: compact ? 5.0 : 6.0,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          if (astroText != null && astroText.isNotEmpty) ...[
            if (holidayText != null && holidayText.isNotEmpty)
              const SizedBox(height: 1),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                astroText,
                maxLines: compact ? 1 : (holidayText == null ? 2 : 1),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF334155).withValues(alpha: 0.95),
                  fontSize: compact ? 5.0 : 6.0,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarGrid({
    required Color backgroundColor,
    required Color foregroundColor,
    required Color holidayColor,
    required Color fullMoonColor,
    required Color newMoonColor,
    required double dayRadius,
    required double dayPadding,
    required double gridSpacing,
    required double gridAspectRatioFallback,
    required int visibleRows,
    required int visibleCellCount,
    required double westernDayFontSize,
    required double myanmarDayFontSize,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridAspectRatio = _resolveGridAspectRatio(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          rows: visibleRows,
          columns: 7,
          spacing: gridSpacing,
          fallback: gridAspectRatioFallback,
        );
        return GridView.builder(
          itemCount: visibleCellCount,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: gridAspectRatio,
            crossAxisSpacing: gridSpacing,
            mainAxisSpacing: gridSpacing,
          ),
          itemBuilder: (context, index) {
            final day = model.dayCells[index];
            if (day.isPlaceholder) {
              return _buildPlaceholderCell(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                dayRadius: dayRadius,
              );
            }
            final dayTextColor = (day.hasPublicHoliday || day.isWeekend == true)
                ? holidayColor
                : foregroundColor;
            final moonPhaseColor = day.hasPublicHoliday
                ? holidayColor
                : day.isFullMoon
                ? fullMoonColor
                : day.isNewMoon
                ? newMoonColor
                : dayTextColor;

            return Container(
              decoration: BoxDecoration(
                color: backgroundColor.withValues(alpha: 0.96),
                border: Border.all(
                  color: foregroundColor.withValues(alpha: 0.22),
                  width: 0.6,
                ),
                borderRadius: BorderRadius.circular(dayRadius),
              ),
              padding: EdgeInsets.all(dayPadding),
              child: Stack(
                children: [
                  if (request.showWesternDates)
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        day.westernDayLabel,
                        style: TextStyle(
                          color: dayTextColor.withValues(
                            alpha: day.isCurrentMonth ? 0.97 : 0.6,
                          ),
                          fontSize: westernDayFontSize,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  if (request.showMyanmarDates)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1, left: 1),
                        child: _buildMoonPhaseVisual(day: day),
                      ),
                    ),
                  if (request.showMyanmarDates)
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        day.myanmarDayLabel,
                        style: TextStyle(
                          color: moonPhaseColor.withValues(
                            alpha: day.isCurrentMonth ? 0.78 : 0.45,
                          ),
                          fontSize: myanmarDayFontSize,
                          fontWeight: day.isFullMoon || day.isNewMoon
                              ? FontWeight.w700
                              : FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                    ),
                  if (request.showAstrology || request.showHolidays)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildCellMetaText(day: day),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomDecorationArea({
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.56),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
      ),
    );
  }

  Widget _buildPlaceholderCell({
    required Color backgroundColor,
    required Color foregroundColor,
    required double dayRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.90),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(dayRadius),
      ),
    );
  }

  int _visibleRowCount(List<CalendarDayCellModel> dayCells) {
    var lastRowWithData = -1;
    for (var row = 0; row < 6; row++) {
      final start = row * 7;
      final hasCurrentMonthDay = dayCells
          .skip(start)
          .take(7)
          .any((day) => !day.isPlaceholder);
      if (hasCurrentMonthDay) {
        lastRowWithData = row;
      }
    }
    return lastRowWithData < 0 ? 6 : (lastRowWithData + 1);
  }

  double _resolveGridAspectRatio({
    required double maxWidth,
    required double maxHeight,
    required int rows,
    required int columns,
    required double spacing,
    required double fallback,
  }) {
    if (maxWidth <= 0 || maxHeight <= 0 || rows <= 0 || columns <= 0) {
      return fallback;
    }

    final totalCrossSpacing = spacing * (columns - 1);
    final totalMainSpacing = spacing * (rows - 1);
    final cellWidth = (maxWidth - totalCrossSpacing) / columns;
    final cellHeight = (maxHeight - totalMainSpacing) / rows;
    if (cellWidth <= 0 || cellHeight <= 0) {
      return fallback;
    }
    return cellWidth / cellHeight;
  }

  Widget _buildMoonPhaseVisual({required CalendarDayCellModel day}) {
    return CompactMoonPhaseIndicator(
      moonPhase: day.moonPhase,
      fortnightDay: day.fortnightDay ?? 0,
      size: compact ? 12 : 16,
    );
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

  BoxFit _toFlutterFit(CalendarBackgroundImageFit fit) {
    return switch (fit) {
      CalendarBackgroundImageFit.cover => BoxFit.cover,
      CalendarBackgroundImageFit.contain => BoxFit.contain,
      CalendarBackgroundImageFit.fill => BoxFit.fill,
    };
  }

  Alignment _toFlutterAlignment(CalendarBackgroundImageAlignment alignment) {
    return switch (alignment) {
      CalendarBackgroundImageAlignment.top => Alignment.topCenter,
      CalendarBackgroundImageAlignment.center => Alignment.center,
      CalendarBackgroundImageAlignment.bottom => Alignment.bottomCenter,
    };
  }
}

class _OverlayElementsLayer extends StatelessWidget {
  const _OverlayElementsLayer({
    required this.elements,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.editMode,
    required this.buildElementChild,
    this.selectedElementId,
    this.onSelectedElementChanged,
    this.onElementChanged,
    this.onElementEditEnd,
  });

  final List<CalendarOverlayElement> elements;
  final double canvasWidth;
  final double canvasHeight;
  final bool editMode;
  final String? selectedElementId;
  final ValueChanged<String?>? onSelectedElementChanged;
  final ValueChanged<CalendarOverlayElement>? onElementChanged;
  final VoidCallback? onElementEditEnd;
  final Widget Function(CalendarOverlayElement element, bool isSelected)
  buildElementChild;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: elements
          .map(
            (element) => _EditableOverlayElement(
              key: ValueKey<String>('overlay_${element.id}'),
              element: element,
              canvasWidth: canvasWidth,
              canvasHeight: canvasHeight,
              selected: selectedElementId == element.id,
              editMode: editMode,
              onSelected: onSelectedElementChanged,
              onChanged: onElementChanged,
              onEditEnd: onElementEditEnd,
              child: buildElementChild(
                element,
                selectedElementId == element.id,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _EditableOverlayElement extends StatefulWidget {
  const _EditableOverlayElement({
    required this.element,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.selected,
    required this.editMode,
    required this.child,
    this.onSelected,
    this.onChanged,
    this.onEditEnd,
    super.key,
  });

  final CalendarOverlayElement element;
  final double canvasWidth;
  final double canvasHeight;
  final bool selected;
  final bool editMode;
  final Widget child;
  final ValueChanged<String?>? onSelected;
  final ValueChanged<CalendarOverlayElement>? onChanged;
  final VoidCallback? onEditEnd;

  @override
  State<_EditableOverlayElement> createState() =>
      _EditableOverlayElementState();
}

class _EditableOverlayElementState extends State<_EditableOverlayElement> {
  double _startScale = 1.0;
  double _startRotation = 0.0;

  @override
  Widget build(BuildContext context) {
    final element = widget.element;
    final alignment = Alignment(
      (element.x * 2.0) - 1.0,
      (element.y * 2.0) - 1.0,
    );
    final content = Transform.rotate(
      angle: element.rotation,
      child: Transform.scale(scale: element.scale, child: widget.child),
    );

    if (!widget.editMode) {
      return Align(alignment: alignment, child: content);
    }

    return Align(
      alignment: alignment,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => widget.onSelected?.call(element.id),
        onScaleStart: (details) {
          if (element.locked) {
            return;
          }
          widget.onSelected?.call(element.id);
          _startScale = element.scale;
          _startRotation = element.rotation;
        },
        onScaleUpdate: (details) {
          if (element.locked) {
            return;
          }
          final dx = widget.canvasWidth <= 0
              ? 0.0
              : details.focalPointDelta.dx / widget.canvasWidth;
          final dy = widget.canvasHeight <= 0
              ? 0.0
              : details.focalPointDelta.dy / widget.canvasHeight;
          final updated = element.copyWith(
            x: (element.x + dx).clamp(0.0, 1.0).toDouble(),
            y: (element.y + dy).clamp(0.0, 1.0).toDouble(),
            scale: (_startScale * details.scale).clamp(0.2, 8.0).toDouble(),
            rotation: _startRotation + details.rotation,
          );
          widget.onChanged?.call(updated);
        },
        onScaleEnd: (_) => widget.onEditEnd?.call(),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            content,
            if (widget.selected)
              Positioned(
                bottom: -16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    element.locked ? 'Locked' : 'Drag/Pinch/Rotate',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({
    required this.labels,
    required this.foregroundColor,
    required this.fontSize,
  });

  final List<String> labels;
  final Color foregroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foregroundColor.withValues(alpha: 0.9),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
