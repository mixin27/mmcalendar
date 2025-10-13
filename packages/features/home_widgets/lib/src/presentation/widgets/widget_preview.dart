import 'package:flutter/material.dart';

import '../../domain/entities/widget_config.dart';
import '../../domain/entities/widget_data.dart';
import 'moon_phase_widget.dart';

class WidgetPreview extends StatelessWidget {
  final WidgetConfig config;
  final WidgetData? data;

  const WidgetPreview({super.key, required this.config, this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Center(child: _buildWidgetPreview(context)),
    );
  }

  Widget _buildWidgetPreview(BuildContext context) {
    switch (config.size) {
      case WidgetSize.small:
        return _buildSmallWidget(context);
      case WidgetSize.medium:
        return _buildMediumWidget(context);
      case WidgetSize.large:
        return _buildLargeWidget(context);
    }
  }

  Widget _buildSmallWidget(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: _getWidgetDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Moon Phase
          if (data != null)
            MoonPhaseWidget(
              moonPhase: _parseMoonPhase(data!.moonPhaseEmoji),
              size: 56,
              showGlow: true,
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
            ),

          const SizedBox(height: 8),

          // Myanmar Date
          if (config.showMyanmarDate && data != null)
            Text(
              _getShortMyanmarDate(data!.myanmarDate),
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          else
            Text(
              'Myanmar Date',
              style: TextStyle(
                color: _getTextColor(context).withValues(alpha: 0.5),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildMediumWidget(BuildContext context) {
    return Container(
      width: 280,
      height: 140,
      decoration: _getWidgetDecoration(),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Left: Moon
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (data != null)
                  MoonPhaseWidget(
                    moonPhase: _parseMoonPhase(data!.moonPhaseEmoji),
                    size: 72,
                    showGlow: true,
                  )
                else
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                  ),

                const SizedBox(height: 4),

                Text(
                  data?.moonPhase ?? 'Moon',
                  style: TextStyle(
                    color: const Color(0xFFFFD700),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right: Dates
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  'Myanmar Calendar',
                  style: TextStyle(
                    color: _getSecondaryTextColor(
                      context,
                    ).withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 6),

                // Myanmar Date
                if (config.showMyanmarDate && data != null)
                  Text(
                    data!.myanmarDate,
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 3),

                // Western Date
                if (config.showWesternDate && data != null)
                  Text(
                    data!.westernDate,
                    style: TextStyle(
                      color: _getSecondaryTextColor(context),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 6),

                // Holiday
                if (config.showHolidays &&
                    data != null &&
                    data!.holidays.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '🎉 Holiday',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeWidget(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: _getWidgetDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Myanmar Calendar',
                  style: TextStyle(
                    color: _getTextColor(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today,
                color: _getTextColor(context),
                size: 26,
              ),
            ],
          ),

          Divider(
            height: 24,
            color: _getTextColor(context).withValues(alpha: 0.3),
          ),

          // Content
          Expanded(
            child: Row(
              children: [
                // Moon
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (data != null)
                        MoonPhaseWidget(
                          moonPhase: _parseMoonPhase(data!.moonPhaseEmoji),
                          size: 100,
                          showGlow: true,
                        )
                      else
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                        ),

                      const SizedBox(height: 6),

                      Text(
                        data?.moonPhase ?? 'Moon Phase',
                        style: TextStyle(
                          color: const Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Dates
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Myanmar Date
                      if (config.showMyanmarDate && data != null)
                        Text(
                          data!.myanmarDate,
                          style: TextStyle(
                            color: _getTextColor(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),

                      const SizedBox(height: 6),

                      // Western Date
                      if (config.showWesternDate && data != null)
                        Text(
                          data!.westernDate,
                          style: TextStyle(
                            color: _getSecondaryTextColor(context),
                            fontSize: 13,
                          ),
                        ),

                      const SizedBox(height: 12),

                      Container(
                        height: 1,
                        color: _getTextColor(context).withValues(alpha: 0.2),
                      ),

                      const SizedBox(height: 10),

                      // Holidays
                      if (config.showHolidays &&
                          data != null &&
                          data!.holidays.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '🎉 ${data!.holidays.join(", ")}',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Astrology
                      if (config.showAstrology &&
                          data != null &&
                          _hasAstrologyInfo())
                        Text(
                          _getAstrologyText(),
                          style: TextStyle(
                            color: _getSecondaryTextColor(context),
                            fontSize: 10,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _getWidgetDecoration() {
    Color startColor, endColor;
    Color borderColor;

    switch (config.theme) {
      case WidgetTheme.light:
        startColor = Colors.white;
        endColor = const Color(0xFFF5F5F5);
        borderColor = Colors.grey[300]!;
        break;
      case WidgetTheme.dark:
        startColor = const Color(0xFF1E1E1E);
        endColor = const Color(0xFF2C2C2C);
        borderColor = Colors.grey[700]!;
        break;
      case WidgetTheme.traditional:
        startColor = const Color(0xFF8B4513);
        endColor = const Color(0xFFCD853F);
        borderColor = const Color(0xFFFFD700);
        break;
      case WidgetTheme.auto:
        startColor = Colors.white;
        endColor = const Color(0xFFF5F5F5);
        borderColor = Colors.grey[300]!;
        break;
      case WidgetTheme.gradientBlue:
        startColor = const Color(0xFF1976D2);
        endColor = const Color(0xFF64B5F6);
        borderColor = const Color(0xFF90CAF9);
        break;
      case WidgetTheme.gradientPurple:
        startColor = const Color(0xFF6A1B9A);
        endColor = const Color(0xFFAB47BC);
        borderColor = const Color(0xFFCE93D8);
        break;
      case WidgetTheme.gradientTeal:
        startColor = const Color(0xFF00796B);
        endColor = const Color(0xFF26A69A);
        borderColor = const Color(0xFF80CBC4);
        break;
    }

    // Apply size-specific gradient based on actual layouts
    // if (config.size == WidgetSize.small) {
    //   // Teal for small
    //   startColor = const Color(0xFF00796B);
    //   endColor = const Color(0xFF26A69A);
    //   borderColor = const Color(0xFF80CBC4);
    // } else if (config.size == WidgetSize.medium) {
    //   // Purple for medium
    //   startColor = const Color(0xFF6A1B9A);
    //   endColor = const Color(0xFFAB47BC);
    //   borderColor = const Color(0xFFCE93D8);
    // } else {
    //   // Blue for large
    //   startColor = const Color(0xFF1976D2);
    //   endColor = const Color(0xFF64B5F6);
    //   borderColor = const Color(0xFF90CAF9);
    // }

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [startColor, endColor],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Color _getTextColor(BuildContext context) {
    Color color = Colors.white;
    switch (config.theme) {
      case WidgetTheme.light:
        color = Colors.black;
        break;
      case WidgetTheme.auto:
        final isDark = Theme.brightnessOf(context) == Brightness.dark;
        color = isDark ? Colors.white : Colors.black;
        break;
      case WidgetTheme.dark:
      case WidgetTheme.traditional:
      case WidgetTheme.gradientBlue:
      case WidgetTheme.gradientPurple:
      case WidgetTheme.gradientTeal:
        color = Colors.white;
        break;
    }

    return color;
  }

  Color _getSecondaryTextColor(BuildContext context) {
    Color color = Colors.white;
    switch (config.theme) {
      case WidgetTheme.light:
        color = Colors.black45;
        break;
      case WidgetTheme.auto:
        final isDark = Theme.brightnessOf(context) == Brightness.dark;
        color = isDark ? Colors.white54 : Colors.black45;
        break;
      case WidgetTheme.dark:
      case WidgetTheme.traditional:
      case WidgetTheme.gradientBlue:
      case WidgetTheme.gradientPurple:
      case WidgetTheme.gradientTeal:
        color = const Color(0xFFE0E0E0);
        break;
    }

    return color;
  }

  String _getShortMyanmarDate(String fullDate) {
    final parts = fullDate.split(' ');
    if (parts.length >= 3) {
      return '${parts[0]} ${parts[1]}\n${parts[2]}';
    }
    return fullDate;
  }

  bool _hasAstrologyInfo() {
    return data?.sabbathInfo != null ||
        data?.yatyazaInfo != null ||
        data?.pyathadaInfo != null;
  }

  String _getAstrologyText() {
    final items = <String>[];
    if (data?.sabbathInfo != null) items.add('☸️ ${data!.sabbathInfo}');
    if (data?.yatyazaInfo != null) items.add('⚠️ ${data!.yatyazaInfo}');
    if (data?.pyathadaInfo != null) items.add('✨ ${data!.pyathadaInfo}');
    return items.join('\n');
  }

  int _parseMoonPhase(String moonPhaseEmoji) {
    if (moonPhaseEmoji.contains('🌒')) return 0; // Waxing
    if (moonPhaseEmoji.contains('🌕')) return 1; // Full
    if (moonPhaseEmoji.contains('🌘')) return 2; // Waning
    if (moonPhaseEmoji.contains('🌑')) return 3; // New
    return 0;
  }
}
