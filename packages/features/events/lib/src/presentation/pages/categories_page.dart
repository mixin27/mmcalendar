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
    return Scaffold(
      appBar: AppBar(title: const Text('Event Categories')),
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.failure.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<EventCategoriesBloc>().add(
                        const LoadEventCategories(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is EventCategoriesLoaded) {
            if (state.categories.isEmpty) {
              return const Center(
                child: Text('No categories yet. Create one to get started.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(category.colorCode),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconData(category.iconName),
                        color: Colors.white,
                        size: 20,
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: category.isDefault
                        ? null
                        : PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditCategoryDialog(context, category);
                              } else if (value == 'delete') {
                                _confirmDeleteCategory(context, category);
                              }
                            },
                          ),
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
                if (nameController.text.isNotEmpty) {
                  final category = EventCategory(
                    name: nameController.text,
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

  void _showEditCategoryDialog(BuildContext context, EventCategory category) {
    // Similar to create dialog but with pre-filled values
    _showCreateCategoryDialog(context);
  }

  void _confirmDeleteCategory(BuildContext context, EventCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Add delete functionality
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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
