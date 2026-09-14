import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WidgetAddInstructions extends StatelessWidget {
  const WidgetAddInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final steps = isIOS
        ? const [
            ('Long press an empty area of the Home Screen', Icons.touch_app),
            ('Tap Edit, then Add Widget', Icons.add_box_outlined),
            ('Search for "Myanmar Calendar"', Icons.search),
            ('Choose a size and tap Add Widget', Icons.widgets_outlined),
          ]
        : const [
            ('Long press on your home screen', Icons.touch_app),
            ('Tap on "Widgets"', Icons.widgets_outlined),
            ('Find "Myanmar Calendar" widget', Icons.search),
            ('Drag and drop to home screen', Icons.drag_indicator),
          ];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'How to Add Widget',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (final (index, step) in steps.indexed) ...[
              _buildStep(context, index + 1, step.$1, step.$2),
              if (index < steps.length - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'After adding, configure the widget appearance from this page!',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.green[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    int stepNumber,
    String description,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
