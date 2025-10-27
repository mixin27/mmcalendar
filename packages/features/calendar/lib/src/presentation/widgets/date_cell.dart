import 'package:events/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

class DateCell extends StatefulWidget {
  final CompleteDate dateInfo;
  final bool isSelected;
  final bool isToday;
  final bool isInCurrentMonth;
  final VoidCallback onTap;
  final bool showHolidays;
  final bool showAnniversaryDays;
  final bool showSabbaths;
  final bool showAstrology;
  final bool showWesternDates;
  final bool showMyanmarDates;
  final List<Event> events;
  final bool showEvents;

  const DateCell({
    super.key,
    required this.dateInfo,
    required this.isSelected,
    required this.isToday,
    required this.isInCurrentMonth,
    required this.onTap,
    this.showHolidays = true,
    this.showAnniversaryDays = true,
    this.showSabbaths = true,
    this.showAstrology = true,
    this.showWesternDates = true,
    this.showMyanmarDates = true,
    this.events = const [],
    this.showEvents = true,
  });

  @override
  State<DateCell> createState() => _DateCellState();
}

class _DateCellState extends State<DateCell> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determine styling
    Color? backgroundColor;
    Color? borderColor;
    Color textColor = colorScheme.onSurface;
    double opacity = 1.0;

    if (widget.isSelected) {
      backgroundColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
    } else if (widget.isToday) {
      backgroundColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
      borderColor = colorScheme.primary;
    } else if (widget.dateInfo.isFullMoon) {
      backgroundColor = Colors.amber.shade50;
      textColor = Colors.amber.shade900;
      borderColor = Colors.amber.shade200;
    } else if (widget.dateInfo.isNewMoon) {
      backgroundColor = Colors.indigo.shade50;
      textColor = Colors.indigo.shade900;
      borderColor = Colors.indigo.shade200;
    }

    if (!widget.isInCurrentMonth) {
      opacity = 0.4;
      textColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
      backgroundColor = null;
      borderColor = null;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: widget.isInCurrentMonth
            ? (_) => _scaleController.forward()
            : null,
        onTapUp: widget.isInCurrentMonth
            ? (_) {
                _scaleController.reverse();
                widget.onTap();
              }
            : null,
        onTapCancel: widget.isInCurrentMonth
            ? () => _scaleController.reverse()
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: backgroundColor?.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(12),
            border: borderColor != null
                ? Border.all(
                    color: borderColor.withValues(alpha: opacity),
                    width: widget.isToday ? 2 : 1,
                  )
                : Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Main content area
              Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top section: Indicators
                    if (widget.isInCurrentMonth)
                      _buildTopIndicators(textColor, opacity),

                    // Middle section: Date numbers
                    Expanded(
                      child: Center(
                        child: _buildDateNumbers(textColor, opacity),
                      ),
                    ),

                    // Bottom section: Events
                    if (widget.isInCurrentMonth)
                      _buildBottomSection(textColor, opacity),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopIndicators(Color textColor, double opacity) {
    final hasIndicators =
        (widget.showHolidays && widget.dateInfo.hasHolidays) ||
        (widget.showAnniversaryDays && widget.dateInfo.hasAnniversaryDays) ||
        (widget.showSabbaths && widget.dateInfo.isSabbath) ||
        (widget.showAstrology && widget.dateInfo.hasAstrologicalDays);

    if (!hasIndicators) {
      return const SizedBox(height: 6);
    }

    return SizedBox(
      height: 6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.showHolidays && widget.dateInfo.hasHolidays)
            _buildDot(
              widget.isSelected || widget.isToday
                  ? textColor.withValues(alpha: 0.8)
                  : Colors.red.shade600,
              opacity,
            ),
          if (widget.showAnniversaryDays && widget.dateInfo.hasAnniversaryDays)
            _buildDot(
              widget.isSelected || widget.isToday
                  ? textColor.withValues(alpha: 0.8)
                  : Colors.teal.shade600,
              opacity,
            ),
          if (widget.showSabbaths && widget.dateInfo.isSabbath)
            _buildDot(
              widget.isSelected || widget.isToday
                  ? textColor.withValues(alpha: 0.8)
                  : Colors.amber.shade700,
              opacity,
            ),
          if (widget.showAstrology && widget.dateInfo.hasAstrologicalDays)
            _buildDot(
              widget.isSelected || widget.isToday
                  ? textColor.withValues(alpha: 0.8)
                  : Colors.deepPurple.shade600,
              opacity,
            ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color, double opacity) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDateNumbers(Color textColor, double opacity) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Western date
        if (widget.showWesternDates)
          Text(
            widget.dateInfo.westernDay.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: textColor.withValues(alpha: opacity),
              fontWeight: widget.isToday ? FontWeight.bold : FontWeight.w600,
              fontSize: 16,
              height: 1.2,
            ),
          ),

        // Myanmar date
        if (widget.showMyanmarDates && widget.isInCurrentMonth) ...[
          const SizedBox(height: 2),
          _buildMyanmarDate(textColor, opacity),
        ],
      ],
    );
  }

  Widget _buildMyanmarDate(Color textColor, double opacity) {
    if (widget.dateInfo.isFullMoon || widget.dateInfo.isNewMoon) {
      return CustomPaint(
        size: const Size(12, 12),
        painter: _MoonPhasePainter(
          moonPhase: widget.dateInfo.moonPhase,
          fortnightDay: widget.dateInfo.fortnightDay,
        ),
      );
    }

    final moonIcon = _getMoonPhaseIcon(widget.dateInfo.moonPhase);
    final fortnightDay = FormatService().translateNumbers(
      widget.dateInfo.fortnightDay.toString(),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          moonIcon,
          style: TextStyle(
            fontSize: 8,
            color: textColor.withValues(alpha: opacity * 0.7),
            height: 1,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          fortnightDay,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: widget.showWesternDates ? 10 : 14,
            color: textColor.withValues(alpha: opacity * 0.7),
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(Color textColor, double opacity) {
    if (!widget.showEvents || widget.events.isEmpty) {
      return const SizedBox(height: 8);
    }

    return SizedBox(height: 8, child: _buildEventIndicator(textColor, opacity));
  }

  Widget _buildEventIndicator(Color textColor, double opacity) {
    final eventCount = widget.events.length;
    final hasHighPriority = widget.events.any(
      (e) =>
          e.priority == EventPriority.high ||
          e.priority == EventPriority.urgent,
    );

    // Show different styles based on event count
    if (eventCount == 1) {
      // Single event - show colored bar
      return Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _getEventColor(widget.events.first).withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(1.5),
        ),
      );
    } else if (eventCount == 2) {
      // Two events - show two bars
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(left: 4, right: 1),
              decoration: BoxDecoration(
                color: _getEventColor(
                  widget.events[0],
                ).withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(left: 1, right: 4),
              decoration: BoxDecoration(
                color: _getEventColor(
                  widget.events[1],
                ).withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ],
      );
    } else if (eventCount == 3) {
      // Three events - show three dots
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 3; i++)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: _getEventColor(
                  widget.events[i],
                ).withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            ),
        ],
      );
    } else {
      // Multiple events (4+) - show gradient bar with count
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  hasHighPriority
                      ? Colors.red.shade400.withValues(alpha: opacity)
                      : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: opacity),
                  hasHighPriority
                      ? Colors.orange.shade400.withValues(alpha: opacity)
                      : Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: opacity),
                ],
              ),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
            decoration: BoxDecoration(
              color: widget.isSelected || widget.isToday
                  ? textColor.withValues(alpha: 0.9)
                  : Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              eventCount.toString(),
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.bold,
                color: widget.isSelected || widget.isToday
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                height: 1.2,
              ),
            ),
          ),
        ],
      );
    }
  }

  Color _getEventColor(Event event) {
    // Priority-based colors
    if (event.priority == EventPriority.urgent) {
      return Colors.red.shade600;
    } else if (event.priority == EventPriority.high) {
      return Colors.orange.shade600;
    }

    // Use event's custom color or category color
    return Color(event.effectiveColor);
  }

  String _getMoonPhaseIcon(int moonPhase) {
    switch (moonPhase) {
      case 0:
        return '☽'; // Waxing
      case 1:
        return '●'; // Full Moon
      case 2:
        return '☾'; // Waning
      case 3:
        return '○'; // New Moon
      default:
        return '';
    }
  }
}

class _MoonPhasePainter extends CustomPainter {
  final int moonPhase;
  final int fortnightDay;

  _MoonPhasePainter({required this.moonPhase, required this.fortnightDay});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.grey.shade700;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (moonPhase == 1) {
      // Full Moon - filled circle
      canvas.drawCircle(center, radius, paint);
    } else if (moonPhase == 3) {
      // New Moon - empty circle with border
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
