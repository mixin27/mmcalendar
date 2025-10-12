import 'package:flutter/material.dart';

import '../../domain/entities/widget_config.dart';
import '../../domain/entities/widget_data.dart';

class WidgetPreview extends StatelessWidget {
  final WidgetConfig config;
  final WidgetData? data;

  const WidgetPreview({super.key, required this.config, this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(child: _buildWidgetPreview(context)),
    );
  }

  Widget _buildWidgetPreview(BuildContext context) {
    switch (config.size) {
      case WidgetSize.small:
        return _buildSmallWidget();
      case WidgetSize.medium:
        return _buildMediumWidget();
      case WidgetSize.large:
        return _buildLargeWidget();
    }
  }

  Widget _buildSmallWidget() {
    return Container(
      width: 160,
      height: 160,
      decoration: _getWidgetDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Myanmar Date
          if (config.showMyanmarDate && data != null)
            Text(
              _getShortMyanmarDate(data!.myanmarDate),
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 8),

          // Moon Phase
          Text(
            data?.moonPhaseEmoji ?? '🌙',
            style: const TextStyle(fontSize: 32),
          ),

          const SizedBox(height: 4),

          // Moon Phase Name
          Text(
            data?.moonPhase ?? 'Moon Phase',
            style: TextStyle(color: _getSecondaryTextColor(), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildMediumWidget() {
    return Container(
      width: 320,
      height: 160,
      decoration: _getWidgetDecoration(),
      padding: const EdgeInsets.all(12),
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
                    color: _getTextColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.calendar_today, color: _getTextColor(), size: 16),
            ],
          ),

          const SizedBox(height: 8),

          // Myanmar Date
          if (config.showMyanmarDate && data != null)
            Text(
              data!.myanmarDate,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 4),

          // Western Date
          if (config.showWesternDate && data != null)
            Text(
              data!.westernDate,
              style: TextStyle(color: _getSecondaryTextColor(), fontSize: 12),
            ),

          const Spacer(),

          // Moon Phase & Holidays
          Row(
            children: [
              // Moon Phase
              Text(
                data?.moonPhaseEmoji ?? '🌙',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 4),
              Text(
                data?.moonPhase ?? 'Moon',
                style: TextStyle(color: const Color(0xFFFFD700), fontSize: 10),
              ),

              const Spacer(),

              // Holiday Indicator
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
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '🎉 Holiday',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          // Astrology Info
          if (config.showAstrology && data != null && _hasAstrologyInfo())
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _getAstrologyText(),
                style: TextStyle(color: _getSecondaryTextColor(), fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLargeWidget() {
    return Container(
      width: 320,
      height: 320,
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
                    color: _getTextColor(),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.calendar_today, color: _getTextColor(), size: 18),
            ],
          ),

          const Divider(height: 16),

          // Myanmar Date
          if (config.showMyanmarDate && data != null)
            Text(
              data!.myanmarDate,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

          const SizedBox(height: 8),

          // Western Date
          if (config.showWesternDate && data != null)
            Text(
              data!.westernDate,
              style: TextStyle(color: _getSecondaryTextColor(), fontSize: 13),
            ),

          const SizedBox(height: 16),

          // Moon Phase
          Row(
            children: [
              Text(
                data?.moonPhaseEmoji ?? '🌙',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moon Phase',
                    style: TextStyle(
                      color: _getSecondaryTextColor(),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    data?.moonPhase ?? 'Unknown',
                    style: TextStyle(
                      color: const Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Holidays
          if (config.showHolidays &&
              data != null &&
              data!.holidays.isNotEmpty) ...[
            Text(
              'Holidays',
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data!.holidays.join('\n'),
                style: TextStyle(color: Colors.red[700], fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const Spacer(),

          // Astrology Info
          if (config.showAstrology && data != null) ...[
            const Divider(height: 16),
            _buildAstrologySection(),
          ],

          // Last Updated
          if (data != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Updated: ${_formatTime(data!.lastUpdated)}',
                style: TextStyle(
                  color: _getSecondaryTextColor().withValues(alpha: 0.6),
                  fontSize: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAstrologySection() {
    final items = <String>[];

    if (data?.sabbathInfo != null) {
      items.add('☸️ ${data!.sabbathInfo}');
    }
    if (data?.yatyazaInfo != null) {
      items.add('⚠️ ${data!.yatyazaInfo}');
    }
    if (data?.pyathadaInfo != null) {
      items.add('✨ ${data!.pyathadaInfo}');
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Astrology',
          style: TextStyle(
            color: _getTextColor(),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              item,
              style: TextStyle(color: _getSecondaryTextColor(), fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _getWidgetDecoration() {
    Color backgroundColor;
    Color borderColor;

    switch (config.theme) {
      case WidgetTheme.light:
        backgroundColor = Colors.white;
        borderColor = Colors.grey[300]!;
        break;
      case WidgetTheme.dark:
        backgroundColor = const Color(0xFF1E1E1E);
        borderColor = Colors.grey[700]!;
        break;
      case WidgetTheme.traditional:
        backgroundColor = const Color(0xFFB71C1C);
        borderColor = const Color(0xFFFFC107);
        break;
      case WidgetTheme.auto:
        backgroundColor = Colors.white;
        borderColor = Colors.grey[300]!;
        break;
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Color _getTextColor() {
    switch (config.theme) {
      case WidgetTheme.light:
        return Colors.black87;
      case WidgetTheme.dark:
        return Colors.white;
      case WidgetTheme.traditional:
        return Colors.white;
      case WidgetTheme.auto:
        return Colors.black87;
    }
  }

  Color _getSecondaryTextColor() {
    switch (config.theme) {
      case WidgetTheme.light:
        return Colors.black54;
      case WidgetTheme.dark:
        return Colors.white70;
      case WidgetTheme.traditional:
        return const Color(0xFFFFF9C4);
      case WidgetTheme.auto:
        return Colors.black54;
    }
  }

  String _getShortMyanmarDate(String fullDate) {
    // Extract main parts for small widget
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
    if (data?.sabbathInfo != null) items.add(data!.sabbathInfo!);
    if (data?.yatyazaInfo != null) items.add(data!.yatyazaInfo!);
    if (data?.pyathadaInfo != null) items.add(data!.pyathadaInfo!);
    return items.join(' • ');
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
