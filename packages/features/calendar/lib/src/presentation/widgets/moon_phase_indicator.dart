import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

class MoonPhaseIconIndicator extends StatelessWidget {
  final int moonPhase;
  final MoonIconStyle style;
  final double size;
  final bool showLabel;

  const MoonPhaseIconIndicator({
    super.key,
    required this.moonPhase,
    this.style = MoonIconStyle.emoji,
    this.size = 12,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getMoonPhaseIcon(moonPhase, style: style),
          size: size,
          color: _getMoonPhaseColor(moonPhase),
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            _formatMoonPhase(moonPhase),
            style: TextStyle(
              fontSize: size * 0.7,
              color: _getMoonPhaseColor(moonPhase),
            ),
          ),
        ],
      ],
    );
  }

  String _formatMoonPhase(int moonPhase, {bool useIcon = true}) {
    if (!useIcon) {
      final str = TranslationService.getMoonPhaseName(moonPhase);
      return str.length > 5 ? str.substring(1, 6) : str.substring(1, 5);
    }
    return '';
  }

  /// Get moon phase icon based on style preference
  IconData _getMoonPhaseIcon(
    int moonPhase, {
    MoonIconStyle style = MoonIconStyle.emoji,
  }) {
    switch (style) {
      case MoonIconStyle.emoji:
        return _getEmojiStyleIcon(moonPhase);
      case MoonIconStyle.material:
        return _getMaterialStyleIcon(moonPhase);
      case MoonIconStyle.brightness:
        return _getBrightnessStyleIcon(moonPhase);
      case MoonIconStyle.custom:
        return _getCustomStyleIcon(moonPhase);
    }
  }

  /// Get moon phase color based on phase
  Color _getMoonPhaseColor(int moonPhase) {
    switch (moonPhase) {
      case 0: // Waxing
        return Colors.amber.shade600;
      case 1: // Full Moon
        return Colors.amber.shade400;
      case 2: // Waning
        return Colors.blue.shade300;
      case 3: // New Moon
        return Colors.indigo.shade400;
      default:
        return Colors.grey;
    }
  }

  IconData _getEmojiStyleIcon(int moonPhase) {
    switch (moonPhase) {
      case 0: // Waxing - 🌒
        return Icons.brightness_2; // Crescent moon
      case 1: // Full Moon - 🌕
        return Icons.circle; // Full circle
      case 2: // Waning - 🌘
        return Icons.brightness_3; // Reversed crescent
      case 3: // New Moon - 🌑
        return Icons.circle_outlined; // Empty circle
      default:
        return Icons.circle_outlined;
    }
  }

  IconData _getMaterialStyleIcon(int moonPhase) {
    switch (moonPhase) {
      case 0: // Waxing
        return Icons.nightlight; // Crescent growing
      case 1: // Full Moon
        return Icons.wb_sunny; // Full bright
      case 2: // Waning
        return Icons.nightlight_round; // Crescent shrinking
      case 3: // New Moon
        return Icons.dark_mode; // Dark moon
      default:
        return Icons.dark_mode;
    }
  }

  IconData _getBrightnessStyleIcon(int moonPhase) {
    switch (moonPhase) {
      case 0: // Waxing
        return Icons.brightness_low; // Getting brighter
      case 1: // Full Moon
        return Icons.brightness_high; // Brightest
      case 2: // Waning
        return Icons.brightness_medium; // Getting dimmer
      case 3: // New Moon
        return Icons.brightness_1; // Dimmest
      default:
        return Icons.brightness_1;
    }
  }

  IconData _getCustomStyleIcon(int moonPhase) {
    switch (moonPhase) {
      case 0: // Waxing
        return Icons.star_half; // Half filled growing
      case 1: // Full Moon
        return Icons.star; // Full star
      case 2: // Waning
        return Icons.star_half_outlined; // Half outlined
      case 3: // New Moon
        return Icons.star_outline; // Empty star
      default:
        return Icons.star_outline;
    }
  }
}

enum MoonIconStyle {
  emoji, // Most recommended - clear moon phases
  material, // Material Design icons
  brightness, // Brightness levels
  custom, // Creative star style
}

class CustomMoonIcon extends StatelessWidget {
  final int moonPhase;
  final double size;

  const CustomMoonIcon({super.key, required this.moonPhase, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: MoonPhaseIconPainter(
        moonPhase: moonPhase,
        color: getMoonPhaseColor(moonPhase),
      ),
    );
  }

  /// Get moon phase color based on phase
  Color getMoonPhaseColor(int moonPhase) {
    switch (moonPhase) {
      case 0: // Waxing
        return Colors.amber.shade600;
      case 1: // Full Moon
        return Colors.amber.shade400;
      case 2: // Waning
        return Colors.blue.shade300;
      case 3: // New Moon
        return Colors.indigo.shade400;
      default:
        return Colors.grey;
    }
  }
}

class MoonPhaseIconPainter extends CustomPainter {
  final int moonPhase;
  final Color color;

  MoonPhaseIconPainter({required this.moonPhase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    switch (moonPhase) {
      case 0: // Waxing - Right half filled
        // Draw circle outline
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = color.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        // Draw right half
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -3.14159 / 2, // Start from top
          3.14159, // Half circle
          true,
          paint,
        );
        break;

      case 1: // Full Moon - Full circle
        canvas.drawCircle(center, radius, paint);
        break;

      case 2: // Waning - Left half filled
        // Draw circle outline
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = color.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        // Draw left half
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          3.14159 / 2, // Start from bottom
          3.14159, // Half circle
          true,
          paint,
        );
        break;

      case 3: // New Moon - Outline only
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
