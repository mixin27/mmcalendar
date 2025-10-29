import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/event.dart';

/// Widget to display event in a list
class EventListTile extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(bool?)? onCheckboxChanged;
  final bool showDate;
  final bool showCategory;
  final bool showCheckbox;

  const EventListTile({
    super.key,
    required this.event,
    this.onTap,
    this.onLongPress,
    this.onCheckboxChanged,
    this.showDate = true,
    this.showCategory = true,
    this.showCheckbox = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: event.isCompleted ? 0 : 2,
      child: ListTile(
        leading: showCheckbox
            ? Checkbox(
                value: event.isCompleted,
                onChanged: onCheckboxChanged,
                activeColor: Color(event.effectiveColor),
              )
            : Container(
                width: 4,
                height: double.infinity,
                color: Color(event.effectiveColor),
              ),
        title: Text(
          event.title,
          style: TextStyle(
            decoration: event.isCompleted ? TextDecoration.lineThrough : null,
            color: event.isCompleted ? Colors.grey : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDate) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    event.isAllDay ? Icons.event : Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatEventTime(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (showCategory) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(),
                    size: 14,
                    color: Color(event.category.colorCode),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.category.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(event.category.colorCode),
                    ),
                  ),
                ],
              ),
            ],
            if (event.location != null && event.location!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: _buildTrailing(),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  Widget? _buildTrailing() {
    if (event.priority == EventPriority.high ||
        event.priority == EventPriority.urgent) {
      return Icon(
        Icons.priority_high,
        color: event.priority == EventPriority.urgent
            ? Colors.red
            : Colors.orange,
      );
    }

    if (event.hasNotifications) {
      return const Icon(
        Icons.notifications_active,
        color: Colors.blue,
        size: 20,
      );
    }

    return null;
  }

  String _formatEventTime() {
    if (event.isAllDay) {
      return DateFormat('MMM dd, yyyy').format(event.eventDate);
    } else {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(event.eventDateTime);
    }
  }

  IconData _getCategoryIcon() {
    // Map icon name to IconData
    switch (event.category.iconName) {
      case 'person':
        return Icons.person;
      case 'work':
        return Icons.work;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.event;
    }
  }
}
