import 'package:events/events.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';
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

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    // Determine background color
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
      backgroundColor = Colors.amber.shade100;
      textColor = Colors.amber.shade900;
    } else if (widget.dateInfo.isNewMoon) {
      backgroundColor = Colors.indigo.shade100;
      textColor = Colors.indigo.shade900;
    }

    if (!widget.isInCurrentMonth) {
      opacity = 0.3;
      textColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
      backgroundColor = null;
      borderColor = null;
    }

    return GestureDetector(
      onTapDown: widget.isInCurrentMonth
          ? (_) => _scaleController.forward()
          : null,
      onTapUp: widget.isInCurrentMonth
          ? (_) => _scaleController.reverse()
          : null,
      onTapCancel: widget.isInCurrentMonth
          ? () => _scaleController.reverse()
          : null,
      onTap: widget.isInCurrentMonth ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: backgroundColor?.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null
              ? Border.all(
                  color: borderColor.withValues(alpha: opacity),
                  width: 2,
                )
              : null,
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
            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Western day
                  if (widget.showWesternDates)
                    Text(
                      widget.dateInfo.westernDay.toString(),
                      style: context.textTheme.titleMedium?.copyWith(
                        color: textColor.withValues(alpha: opacity),
                        fontWeight: widget.isToday
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),

                  if (widget.isInCurrentMonth && widget.showMyanmarDates)
                    _buildMyanmarDateInfo(
                      textColor,
                      opacity,
                      widget.showWesternDates,
                    ),
                ],
              ),
            ),

            // Myanmar fortnight day and moon phase
            if (widget.isInCurrentMonth && widget.showMyanmarDates) ...[
              Positioned(
                right: 2,
                bottom: 2,
                child: _buildMoonPhase(textColor, opacity),
              ),
            ],

            // Event indicators
            if (widget.events.isNotEmpty &&
                widget.showEvents &&
                widget.isInCurrentMonth)
              Positioned(
                left: 2,
                bottom: 2,
                child: EventCalendarIndicator(events: widget.events, size: 6),
              ),

            if (widget.isInCurrentMonth) ...[
              Positioned(
                top: 3,
                left: 3,
                child: Wrap(
                  spacing: 2,
                  children: [
                    // Holiday
                    if (widget.showHolidays && widget.dateInfo.hasHolidays)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.isSelected || widget.isToday
                              ? textColor.withValues(alpha: 0.8)
                              : Colors.red.shade700,
                          shape: BoxShape.circle,
                        ),
                      ),

                    // Anniversary days
                    if (widget.showAnniversaryDays &&
                        widget.dateInfo.hasAnniversaryDays)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.isSelected || widget.isToday
                              ? textColor.withValues(alpha: 0.8)
                              : Colors.teal.shade700,
                          shape: BoxShape.circle,
                        ),
                      ),

                    // Astro indicator
                    if (widget.showAstrology &&
                        widget.dateInfo.hasAstrologicalDays)
                      Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade700,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    // Sabbath indicator
                    if (widget.showSabbaths && widget.dateInfo.isSabbath)
                      Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoonPhase(Color textColor, double opacity) {
    final moonPhaseIcon = _getMoonPhaseIcon(widget.dateInfo.moonPhase);

    if (widget.dateInfo.isNewMoon || widget.dateInfo.isFullMoon) {
      return CustomPaint(
        size: Size(10, 10),
        painter: MoonPhasePainter(
          moonPhase: widget.dateInfo.moonPhase,
          fortnightDay: widget.dateInfo.fortnightDay,
        ),
      );
    } else {
      return Text(
        moonPhaseIcon,
        style: TextStyle(
          fontSize: 8,
          color: textColor.withValues(alpha: opacity * 0.7),
        ),
      );
    }
  }

  Widget _buildMyanmarDateInfo(
    Color textColor,
    double opacity,
    bool showWestern,
  ) {
    if (!showWestern) {
      return Column(
        children: [
          Text(
            // MyanmarCalendar.formatMyanmar(
            //   widget.dateInfo.myanmar,
            //   pattern: '&f',
            // ),
            FormatService().translateNumbers(
              widget.dateInfo.fortnightDay.toString(),
            ),
            style: context.textTheme.titleMedium?.copyWith(
              color: textColor.withValues(alpha: opacity),
              fontWeight: widget.isToday ? FontWeight.bold : FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 2),
        Text(
          // MyanmarCalendar.formatMyanmar(
          //   widget.dateInfo.myanmar,
          //   pattern: '&f',
          // ),
          FormatService().translateNumbers(
            widget.dateInfo.fortnightDay.toString(),
          ),
          style: context.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            color: textColor.withValues(alpha: opacity * 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getMoonPhaseIcon(int moonPhase) {
    switch (moonPhase) {
      case 0:
        return '☽';
      case 1:
        return '●';
      case 2:
        return '☾';
      case 3:
        return '○';
      default:
        return '';
    }
  }
}
