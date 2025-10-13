import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyableInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget child;

  const CopyableInfoRow({
    super.key,
    required this.child,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied!'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Expanded(child: child),
            Icon(
              Icons.copy,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
