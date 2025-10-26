import 'package:flutter/material.dart';

import '../../domain/entities/event.dart';

/// Widget to display event priority
class PriorityBadge extends StatelessWidget {
  final EventPriority priority;
  final bool compact;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (priority == EventPriority.normal || priority == EventPriority.low) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: compact
          ? const EdgeInsets.all(4)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getColor()),
      ),
      child: compact
          ? Icon(_getIcon(), size: 16, color: _getColor())
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getIcon(), size: 16, color: _getColor()),
                const SizedBox(width: 4),
                Text(
                  priority.displayName,
                  style: TextStyle(
                    color: _getColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Color _getColor() {
    switch (priority) {
      case EventPriority.urgent:
        return Colors.red;
      case EventPriority.high:
        return Colors.orange;
      case EventPriority.normal:
        return Colors.blue;
      case EventPriority.low:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (priority) {
      case EventPriority.urgent:
        return Icons.priority_high;
      case EventPriority.high:
        return Icons.flag;
      case EventPriority.normal:
        return Icons.outlined_flag;
      case EventPriority.low:
        return Icons.flag_outlined;
    }
  }
}
