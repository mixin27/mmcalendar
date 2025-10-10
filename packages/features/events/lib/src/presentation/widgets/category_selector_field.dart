import 'package:flutter/material.dart';

import '../../domain/entities/event.dart';

class CategorySelectorField extends StatelessWidget {
  final String selectedCategory;
  final int? selectedCategoryId;
  final List<EventCategory> categories;
  final void Function(String category, int? categoryId) onCategoryChanged;

  const CategorySelectorField({
    super.key,
    required this.selectedCategory,
    this.selectedCategoryId,
    required this.categories,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCategoryPicker(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Category *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.category),
        ),
        child: Row(
          children: [
            if (selectedCategoryId != null) ...[
              Icon(
                _getIconData(
                  categories
                      .firstWhere((c) => c.id == selectedCategoryId)
                      .iconName,
                ),
                size: 20,
                color: Color(
                  categories
                      .firstWhere((c) => c.id == selectedCategoryId)
                      .colorCode,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(selectedCategory),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => ListView(
        shrinkWrap: true,
        children: categories.map((category) {
          final isSelected = category.id == selectedCategoryId;
          return ListTile(
            leading: Icon(
              _getIconData(category.iconName),
              color: Color(category.colorCode),
            ),
            title: Text(category.name),
            trailing: isSelected ? const Icon(Icons.check) : null,
            onTap: () {
              onCategoryChanged(category.name, category.id);
              Navigator.pop(bottomSheetContext);
            },
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
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
