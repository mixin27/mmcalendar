import 'package:flutter/material.dart';

// Small color chip for preview
class ColorChip extends StatelessWidget {
  final Color color;

  const ColorChip({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
    );
  }
}
