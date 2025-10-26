import 'package:flutter/material.dart';

import '../../domain/entities/event.dart';

/// Widget to display event indicators on calendar cells
class EventCalendarIndicator extends StatelessWidget {
  final List<Event> events;
  final bool showCount;
  final double size;

  const EventCalendarIndicator({
    super.key,
    required this.events,
    this.showCount = true,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    final hasHighPriority = events.any(
      (e) =>
          e.priority == EventPriority.high ||
          e.priority == EventPriority.urgent,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasHighPriority
            ? Colors.red.withValues(alpha: 0.8)
            : Colors.blue.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: showCount && events.length > 1
            ? Text(
                events.length.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.6,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Icon(Icons.event, color: Colors.white, size: size * 0.7),
      ),
    );
  }
}
