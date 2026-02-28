import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/event_category.dart';
import '../bloc/event_categories_bloc.dart';
import '../bloc/event_categories_event.dart';
import '../bloc/event_categories_state.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Categories'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<EventCategoriesBloc>().add(
                const LoadEventCategories(),
              );
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
      body: BlocBuilder<EventCategoriesBloc, EventCategoriesState>(
        builder: (context, state) {
          if (state is EventCategoriesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EventCategoriesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(state.failure.message),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      context.read<EventCategoriesBloc>().add(
                        const LoadEventCategories(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is EventCategoriesLoaded) {
            if (state.categories.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      const Text('No categories yet'),
                      const SizedBox(height: 6),
                      Text(
                        'Create one to personalize event organization.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final categoryColor = Color(category.colorCode);
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconData(category.iconName),
                        color: categoryColor,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      category.isDefault
                          ? 'Default category'
                          : 'Custom category',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    trailing: category.isDefault
                        ? Icon(
                            Icons.lock_outline,
                            color: colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
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

  void _showCreateCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedIcon = 'category';
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: selectedColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconData(selectedIcon),
                    color: selectedColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select Icon:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _getAvailableIcons().map((icon) {
                    return IconButton(
                      icon: Icon(icon.value),
                      color: selectedIcon == icon.key
                          ? selectedColor
                          : Colors.grey,
                      onPressed: () {
                        setState(() {
                          selectedIcon = icon.key;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Select Color:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _getAvailableColors().map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final category = EventCategory(
                    name: name,
                    iconName: selectedIcon,
                    colorCode: selectedColor.toARGB32(),
                    createdAt: DateTime.now(),
                  );
                  context.read<EventCategoriesBloc>().add(
                    CreateCategory(category),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, IconData>> _getAvailableIcons() {
    return const [
      MapEntry('person', Icons.person),
      MapEntry('work', Icons.work),
      MapEntry('auto_awesome', Icons.auto_awesome),
      MapEntry('family_restroom', Icons.family_restroom),
      MapEntry('favorite', Icons.favorite),
      MapEntry('school', Icons.school),
      MapEntry('sports', Icons.sports),
      MapEntry('restaurant', Icons.restaurant),
      MapEntry('flight', Icons.flight),
      MapEntry('shopping_cart', Icons.shopping_cart),
    ];
  }

  List<Color> _getAvailableColors() {
    return [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];
  }
}
