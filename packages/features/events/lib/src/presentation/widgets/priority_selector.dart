
import 'package:flutter/material.dart';

class PrioritySelector extends StatelessWidget {
  final int priority;
  final void Function(int) onPriorityChanged;

  const PrioritySelector({
    super.key,
    required this.priority,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text('None'),
            ),
            ButtonSegment(
              value: 1,
              label: Text('Low'),
              icon: Icon(Icons.flag, color: Colors.blue),
            ),
            ButtonSegment(
              value: 2,
              label: Text('Medium'),
              icon: Icon(Icons.flag, color: Colors.orange),
            ),
            ButtonSegment(
              value: 3,
              label: Text('High'),
              icon: Icon(Icons.flag, color: Colors.red),
            ),
          ],
          selected: {priority},
          onSelectionChanged: (Set<int> newSelection) {
            onPriorityChanged(newSelection.first);
          },
        ),
      ],
    );
  }
}
