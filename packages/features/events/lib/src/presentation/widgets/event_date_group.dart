import 'package:flutter/material.dart';

import '../../domain/entities/event.dart';
import 'event_card.dart';

class EventDateGroup extends StatelessWidget {
  final DateTime date;
  final List<Event> events;
  final void Function(Event)? onEventTap;
  final void Function(int)? onEventToggle;

  const EventDateGroup({
    super.key,
    required this.date,
    required this.events,
    this.onEventTap,
    this.onEventToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isToday(date)
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date.day.toString(),
                      style: textTheme.titleLarge?.copyWith(
                        color: _isToday(date)
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getMonthAbbr(date.month),
                      style: textTheme.bodySmall?.copyWith(
                        color: _isToday(date)
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getWeekday(date.weekday),
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${events.length} ${events.length == 1 ? 'event' : 'events'}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Events list
        ...events.map(
          (event) => EventCard(
            event: event,
            onTap: onEventTap != null ? () => onEventTap!(event) : null,
            onToggle: onEventToggle != null
                ? () => onEventToggle!(event.id)
                : null,
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getWeekday(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  String _getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
