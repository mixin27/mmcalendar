import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' hide ContextExtension;

import '../../domain/entities/event_category.dart';
import '../bloc/event_categories_bloc.dart';
import '../bloc/event_categories_event.dart';
import '../bloc/event_categories_state.dart';
import '../widgets/category_icon.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventCategoriesBloc, EventCategoriesState>(
      builder: (context, state) {
        final bloc = context.read<EventCategoriesBloc>();
        if (state is EventCategoriesInitial) {
          bloc.add(const LoadEventCategories());
        }
        final categories = state is EventCategoriesLoaded
            ? state.categories
            : const <EventCategory>[];
        final defaults = categories.where((c) => c.isDefault).toList();
        final custom = categories.where((c) => !c.isDefault).toList();

        AppRow row(EventCategory category) => AppRow(
          icon: categoryIcon(category.iconName),
          iconColor: Color(category.colorCode),
          title: category.name,
          trailing: category.isDefault
              ? Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: context.tokens.tertiaryLabel,
                )
              : null,
          chevron: !category.isDefault,
          onTap: category.isDefault
              ? null
              : () => _showCategorySheet(context, category),
        );

        return AppPage(
          title: 'Categories',
          previousTitle: 'Events',
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New Category',
              onPressed: () => _showCategorySheet(context, null),
            ),
          ],
          children: switch (state) {
            EventCategoriesError(:final failure) => [
              AppGroup(
                footer: failure.message,
                children: [
                  AppRow(
                    title: 'Retry',
                    tone: AppRowTone.accent,
                    onTap: () => bloc.add(const LoadEventCategories()),
                  ),
                ],
              ),
            ],
            EventCategoriesLoaded() => [
              if (defaults.isNotEmpty)
                AppGroup(
                  label: 'Default',
                  footer: 'Built-in categories can’t be changed.',
                  children: [for (final c in defaults) row(c)],
                ),
              AppGroup(
                label: 'Custom',
                footer: custom.isEmpty
                    ? 'Create categories for the events you keep.'
                    : 'Tap a category to rename, recolour or delete it.',
                children: [
                  for (final c in custom) row(c),
                  AppRow(
                    title: 'New Category',
                    tone: AppRowTone.accent,
                    onTap: () => _showCategorySheet(context, null),
                  ),
                ],
              ),
            ],
            _ => const [
              Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
        );
      },
    );
  }

  /// Create (category null) or edit a custom category.
  Future<void> _showCategorySheet(
    BuildContext context,
    EventCategory? category,
  ) async {
    final bloc = context.read<EventCategoriesBloc>();
    // The field owns its text; a controller disposed here would still be
    // in use while the sheet animates away.
    var name = category?.name ?? '';
    var icon = category?.iconName ?? 'person';
    var color = Color(category?.colorCode ?? Colors.blue.toARGB32());
    final navigator = Navigator.of(context);

    void save() {
      final trimmed = name.trim();
      if (trimmed.isEmpty) return;
      bloc.add(
        category == null
            ? CreateCategory(
                EventCategory(
                  name: trimmed,
                  iconName: icon,
                  colorCode: color.toARGB32(),
                  createdAt: DateTime.now(),
                ),
              )
            : UpdateCategory(
                category.copyWith(
                  name: trimmed,
                  iconName: icon,
                  colorCode: color.toARGB32(),
                ),
              ),
      );
      navigator.pop();
    }

    await showAppSheet<void>(
      context: context,
      title: category == null ? 'New Category' : 'Edit Category',
      doneLabel: category == null ? 'Create' : 'Save',
      onDone: save,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) {
          final t = sheetContext.tokens;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppGroup(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextFormField(
                        initialValue: name,
                        onChanged: (value) => name = value,
                        autofocus: category == null,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => save(),
                        decoration: const InputDecoration(
                          hintText: 'Name',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const AppGroupLabel('Icon'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in _getAvailableIcons())
                      Semantics(
                        selected: icon == entry.key,
                        button: true,
                        label: entry.key,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => icon = entry.key),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: icon == entry.key ? color : t.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              entry.value,
                              color: icon == entry.key
                                  ? Colors.white
                                  : t.secondaryLabel,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const AppGroupLabel('Colour'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final swatch in _getAvailableColors())
                      Semantics(
                        selected: swatch == color,
                        button: true,
                        label: 'Colour',
                        child: GestureDetector(
                          onTap: () => setState(() => color = swatch),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: swatch,
                              shape: BoxShape.circle,
                              border: swatch == color
                                  ? Border.all(color: t.label, width: 2.5)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (category?.id != null) ...[
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Delete Category',
                    kind: AppButtonKind.destructive,
                    onPressed: () async {
                      final confirmed = await showAppConfirm(
                        context: sheetContext,
                        title: 'Delete “${category!.name}”?',
                        message:
                            'Its events are kept; they just stop being linked '
                            'to this category.',
                        confirmLabel: 'Delete',
                        destructive: true,
                      );
                      if (!confirmed) return;
                      bloc.add(DeleteCategory(category.id!));
                      navigator.pop();
                    },
                  ),
                ],
              ],
            ),
          );
        },
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
