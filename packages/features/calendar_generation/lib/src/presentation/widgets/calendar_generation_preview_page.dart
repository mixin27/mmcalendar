import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_page_model.dart';
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
    final gridAspectRatio = compact ? 0.8 : 0.86;

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
          child: Column(
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
              _WeekdayHeader(
                labels: model.weekdayLabels,
                foregroundColor: foregroundColor,
                fontSize: weekdayFontSize,
              ),
              SizedBox(height: compact ? 3 : 6),
              Expanded(
                child: GridView.builder(
                  itemCount: model.dayCells.length,
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
                      return const SizedBox.shrink();
                    }
                    final dayTextColor =
                        (day.hasPublicHoliday || day.isWeekend == true)
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
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!useCardChrome) {
      return previewBody;
    }
    return Card(margin: margin, elevation: elevation, child: previewBody);
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
