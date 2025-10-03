import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/views_bloc.dart';
import '../bloc/views_event.dart';

class ViewsSelectorPage extends StatelessWidget {
  const ViewsSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Views'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Select Calendar View',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Year View Card
            // _ViewCard(
            //   icon: Icons.calendar_view_month,
            //   title: 'Year View',
            //   description: 'See all 12 months of the year at a glance',
            //   color: Colors.blue,
            //   onTap: () {
            //     context.read<ViewsBloc>().add(
            //       LoadYearView(DateTime.now().year),
            //     );
            //     GoRouter.of(context).push(RoutePaths.yearView);
            //   },
            // ),

            // const SizedBox(height: 16),

            // Week View Card
            _ViewCard(
              icon: Icons.calendar_view_week,
              title: 'Week View',
              description: 'View a detailed week with all days',
              color: Colors.green,
              onTap: () {
                context.read<ViewsBloc>().add(LoadWeekView(DateTime.now()));
                GoRouter.of(context).push(RoutePaths.weekView);
              },
            ),

            const SizedBox(height: 16),

            // Day View Card
            _ViewCard(
              icon: Icons.calendar_today,
              title: 'Day View',
              description: 'See comprehensive information for a single day',
              color: Colors.orange,
              onTap: () {
                context.read<ViewsBloc>().add(LoadDayView(DateTime.now()));
                GoRouter.of(context).push(RoutePaths.dayView);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ViewCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
