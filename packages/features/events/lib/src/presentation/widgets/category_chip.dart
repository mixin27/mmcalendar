import 'package:flutter/material.dart';

import '../../domain/entities/event_category.dart';

/// Widget to display category as a chip
class CategoryChip extends StatelessWidget {
  final EventCategory category;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(category.name),
      avatar: Icon(
        _getIconData(),
        size: 18,
        color: selected ? Colors.white : Color(category.colorCode),
      ),
      selected: selected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      backgroundColor: Color(category.colorCode).withValues(alpha: 0.1),
      selectedColor: Color(category.colorCode),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Color(category.colorCode),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  IconData _getIconData() {
    switch (category.iconName) {
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
        return Icons.category;
    }
  }
}
