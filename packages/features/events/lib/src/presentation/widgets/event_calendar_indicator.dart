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
    this.size = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    final hasHighPriority = events.any(
      (e) =>
          e.priority == EventPriority.high ||
          e.priority == EventPriority.urgent,
    );

    // Simple dot indicator
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasHighPriority
            ? Colors.red.withValues(alpha: 0.8)
            : Colors.blue.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
    );
  }
}
