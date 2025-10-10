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

                  // Myanmar fortnight day and moon phase
                  if (widget.isInCurrentMonth && widget.showMyanmarDates) ...[
                    const SizedBox(height: 2),
                    // Myanmar date info - simplified
                    _buildMyanmarDateInfo(textColor, opacity),
                  ],
                ],
              ),
            ),

            // Event indicators
            if (widget.events.isNotEmpty && widget.showEvents)
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (
                      int i = 0;
                      i < (widget.events.length > 3 ? 3 : widget.events.length);
                      i++
                    )
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color:
                              // widget.events[i].colorCode != null
                              //     ? Color(widget.events[i].colorCode!)
                              //     :
                              Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (widget.events.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          '+${widget.events.length - 3}',
                          style: TextStyle(
                            fontSize: 8,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            if (widget.isInCurrentMonth && widget.showHolidays) ...[
              // Holiday
              if (widget.dateInfo.hasHolidays)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.isSelected || widget.isToday
                          ? textColor.withValues(alpha: 0.8)
                          : colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

              // Sabbath indicator
              // if (widget.dateInfo.isSabbath && widget.showAstrology)
              //   Positioned(
              //     bottom: 4,
              //     left: 0,
              //     right: 0,
              //     child: Center(
              //       child: Container(
              //         width: 4,
              //         height: 4,
              //         decoration: BoxDecoration(
              //           color: Colors.orange.withValues(alpha: 0.8),
              //           shape: BoxShape.circle,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMyanmarDateInfo(Color textColor, double opacity) {
    final moonPhaseIcon = _getMoonPhaseIcon(widget.dateInfo.moonPhase);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          moonPhaseIcon,
          style: TextStyle(
            fontSize: 11,
            color: textColor.withValues(alpha: opacity * 0.7),
          ),
        ),
        if (!(widget.dateInfo.isFullMoon || widget.dateInfo.isNewMoon)) ...[
          const SizedBox(width: 2),
          Text(
            MyanmarCalendar.formatMyanmar(
              widget.dateInfo.myanmar,
              pattern: '&f',
            ),
            style: context.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: textColor.withValues(alpha: opacity * 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
