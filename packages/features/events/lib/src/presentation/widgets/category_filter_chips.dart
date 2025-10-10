import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../bloc/events_state.dart';

class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventsBloc, EventsState>(
      builder: (context, state) {
        if (state is! EventsLoaded) {
          return const SizedBox.shrink();
        }

        if (state.categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // All filter
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: state.currentCategory == null,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<EventsBloc>().add(const LoadAllEvents());
                    }
                  },
                ),
              ),

              // Category filters
              ...state.categories.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.name),
                    avatar: Icon(
                      _getIconData(category.iconName),
                      size: 18,
                      color: Color(category.colorCode),
                    ),
                    selected: state.currentCategory == category.name,
                    onSelected: (selected) {
                      if (selected) {
                        context.read<EventsBloc>().add(
                          LoadEventsByCategory(category.name),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    // Map icon names to IconData
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
