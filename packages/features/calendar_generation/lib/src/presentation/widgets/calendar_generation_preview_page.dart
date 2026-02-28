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
    final accentColor = Color(theme.accentColorValue);
    const holidayColor = Color(0xFFC62828);
    const fullMoonColor = Color(0xFFB45309);
    const newMoonColor = Color(0xFF4338CA);
    final aspectRatio = CalendarExportLayout.previewAspectRatio(request);
    final pageBackgroundImage = theme.backgroundImageUrlForMonth(model.month);
    final imageProvider =
        backgroundImageProvider ?? _parseImageProvider(pageBackgroundImage);

    final titleFontSize = compact ? 13.0 : 20.0;
    final weekdayFontSize = compact ? 8.0 : 12.0;
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
              if (!compact && model.myanmarTitle.trim().isNotEmpty) ...[
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
                    final dayTextColor = day.hasPublicHoliday
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
                          color: day.isToday
                              ? accentColor
                              : foregroundColor.withValues(alpha: 0.22),
                          width: day.isToday ? 1.3 : 0.6,
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
                                child: _MoonPhaseIndicator(
                                  moonPhase: day.moonPhase,
                                  compact: compact,
                                  lightColor: moonPhaseColor.withValues(
                                    alpha: 0.88,
                                  ),
                                  darkColor: foregroundColor.withValues(
                                    alpha: 0.22,
                                  ),
                                  borderColor: foregroundColor.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
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
                          if (!compact && request.showAstrology)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: _buildAstroBadges(context, day: day),
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

  Widget _buildAstroBadges(
    BuildContext context, {
    required CalendarDayCellModel day,
  }) {
    final allBadges = <_AstroBadge>[
      if (day.sabbathLabel?.trim().isNotEmpty ?? false)
        const _AstroBadge('S', Color(0xFFF59E0B)),
      if (day.sabbathEveLabel?.trim().isNotEmpty ?? false)
        const _AstroBadge('SE', Color(0xFFD97706)),
      if (day.yatyazaLabel?.trim().isNotEmpty ?? false)
        const _AstroBadge('Y', Color(0xFF7E22CE)),
      if (day.pyathadaLabel?.trim().isNotEmpty ?? false)
        const _AstroBadge('P', Color(0xFF4F46E5)),
      if (day.afternoonPyathadaLabel?.trim().isNotEmpty ?? false)
        const _AstroBadge('AP', Color(0xFFEA580C)),
      if (day.otherAstrologyLabel?.trim().isNotEmpty ?? false)
        const _AstroBadge('+', Color(0xFF64748B)),
    ];
    if (allBadges.isEmpty) {
      return const SizedBox.shrink();
    }
    const maxVisibleBadges = 4;
    final overflowCount = allBadges.length - maxVisibleBadges;
    final badges = overflowCount > 0
        ? allBadges.take(maxVisibleBadges).toList(growable: false)
        : allBadges;

    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final badge in badges)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: badge.color.withValues(alpha: 0.22),
                shape: BoxShape.circle,
                border: Border.all(
                  color: badge.color.withValues(alpha: 0.58),
                  width: 0.6,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                badge.code,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: badge.color.withValues(alpha: 0.96),
                  fontSize: 5.4,
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                ),
              ),
            ),
          if (overflowCount > 0)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF334155).withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '+$overflowCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF334155).withValues(alpha: 0.94),
                  fontSize: 4.8,
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                ),
              ),
            ),
        ],
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

class _MoonPhaseIndicator extends StatelessWidget {
  const _MoonPhaseIndicator({
    required this.moonPhase,
    required this.compact,
    required this.lightColor,
    required this.darkColor,
    required this.borderColor,
  });

  final int moonPhase;
  final bool compact;
  final Color lightColor;
  final Color darkColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 12.0 : 16.0;
    final icon = switch (moonPhase % 4) {
      1 => '●', // full
      2 => '◐', // waning
      3 => '○', // new
      _ => '◑', // waxing
    };
    final iconColor = moonPhase == 3 ? darkColor : lightColor;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: darkColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 0.6),
      ),
      child: Text(
        icon,
        style: TextStyle(
          color: iconColor.withValues(alpha: 0.96),
          fontSize: compact ? 7.0 : 8.8,
          fontWeight: FontWeight.w700,
          height: 0.95,
        ),
      ),
    );
  }
}

class _AstroBadge {
  const _AstroBadge(this.code, this.color);

  final String code;
  final Color color;
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
