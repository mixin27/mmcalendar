import 'package:flutter/material.dart';

class LeadingDot extends StatelessWidget {
  final Color? color;
  final double opacity;
  final double size;
  final IconData? icon;

  const LeadingDot({
    super.key,
    this.color,
    this.opacity = 1,
    this.size = 24,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return Icon(icon!, color: color);
    }
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color:
            color?.withValues(alpha: opacity) ??
            Theme.of(context).colorScheme.primary.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
