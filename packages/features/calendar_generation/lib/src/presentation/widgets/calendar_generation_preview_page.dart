import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_page_model.dart';
import '../../domain/entities/calendar_preview_theme.dart';
import '../../rendering/export/calendar_export_layout.dart';

class CalendarGenerationPreviewPage extends StatelessWidget {
  const CalendarGenerationPreviewPage({
    required this.model,
    required this.request,
    super.key,
  });

  static final Map<String, ImageProvider<Object>> _imageProviderCache =
      <String, ImageProvider<Object>>{};
  static final List<String> _imageProviderCacheOrder = <String>[];
  static const int _maxImageProviderCacheSize = 24;

  final CalendarPageModel model;
  final CalendarGenerationRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = request.theme;
    final backgroundColor = Color(theme.backgroundColorValue);
    final foregroundColor = Color(theme.foregroundColorValue);
    final accentColor = Color(theme.accentColorValue);
    final aspectRatio = CalendarExportLayout.previewAspectRatio(request);
    final pageBackgroundImage = theme.backgroundImageUrlForMonth(model.month);
    final imageProvider = _parseImageProvider(pageBackgroundImage);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 2,
      child: AspectRatio(
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
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  model.title,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _WeekdayHeader(
                  labels: model.weekdayLabels,
                  foregroundColor: foregroundColor,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: GridView.builder(
                    itemCount: model.dayCells.length,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 0.86,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                    itemBuilder: (context, index) {
                      final day = model.dayCells[index];
                      final hasMarker =
                          (request.showHolidays && day.hasHoliday) ||
                          (request.showAstrology && day.hasAstrology);

                      return Container(
                        decoration: BoxDecoration(
                          color: day.isCurrentMonth
                              ? backgroundColor.withValues(alpha: 0.92)
                              : foregroundColor.withValues(alpha: 0.06),
                          border: Border.all(
                            color: day.isToday
                                ? accentColor
                                : foregroundColor.withValues(alpha: 0.15),
                            width: day.isToday ? 1.3 : 0.6,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Stack(
                          children: [
                            if (request.showWesternDates)
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  day.westernDayLabel,
                                  style: TextStyle(
                                    color: foregroundColor.withValues(
                                      alpha: day.isCurrentMonth ? 0.95 : 0.5,
                                    ),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (request.showMyanmarDates)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  day.myanmarDayLabel,
                                  style: TextStyle(
                                    color: foregroundColor.withValues(
                                      alpha: day.isCurrentMonth ? 0.78 : 0.45,
                                    ),
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            if (hasMarker)
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
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
      ),
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
  const _WeekdayHeader({required this.labels, required this.foregroundColor});

  final List<String> labels;
  final Color foregroundColor;

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
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
