import 'package:flutter/material.dart';

import '../../domain/entities/recurrence_rule.dart';

/// Widget to display recurrence information
class RecurrenceBadge extends StatelessWidget {
  final RecurrenceRule recurrenceRule;
  final bool compact;

  const RecurrenceBadge({
    super.key,
    required this.recurrenceRule,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.all(4)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple),
      ),
      child: compact
          ? const Icon(Icons.repeat, size: 16, color: Colors.purple)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.repeat, size: 16, color: Colors.purple),
                const SizedBox(width: 4),
                Text(
                  _getRecurrenceText(),
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  String _getRecurrenceText() {
    final interval = recurrenceRule.interval;
    switch (recurrenceRule.type) {
      case RecurrenceType.daily:
        return interval == 1 ? 'Daily' : 'Every $interval days';
      case RecurrenceType.weekly:
        return interval == 1 ? 'Weekly' : 'Every $interval weeks';
      case RecurrenceType.monthly:
        return interval == 1 ? 'Monthly' : 'Every $interval months';
      case RecurrenceType.yearly:
        return interval == 1 ? 'Yearly' : 'Every $interval years';
      case RecurrenceType.none:
        return 'No repeat';
    }
  }
}
