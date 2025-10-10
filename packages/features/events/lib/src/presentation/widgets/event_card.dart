import 'package:flutter/material.dart';

import '../../domain/entities/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  const EventCard({super.key, required this.event, this.onTap, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final categoryColor = event.colorCode != null
        ? Color(event.colorCode!)
        : colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Category color indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Complete checkbox
              Checkbox(
                value: event.isCompleted,
                onChanged: onToggle != null ? (_) => onToggle!() : null,
              ),
              const SizedBox(width: 8),

              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      event.title,
                      style: textTheme.titleMedium?.copyWith(
                        decoration: event.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: event.isCompleted
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Time (if not all day)
                    if (!event.isAllDay && event.eventTime != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            TimeOfDay.fromDateTime(
                              event.eventTime!,
                            ).format(context),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                    // Category and location
                    Row(
                      children: [
                        // Category
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.category,
                            style: textTheme.bodySmall?.copyWith(
                              color: categoryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        if (event.location != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              event.location!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Priority indicator
              if (event.priority > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.flag,
                    size: 20,
                    color: _getPriorityColor(event.priority, colorScheme),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority, ColorScheme colorScheme) {
    switch (priority) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.blue;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }
}
