import 'package:events/events.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:go_router/go_router.dart';

class DayDetailsPage extends StatelessWidget {
  final DateTime date;
  final List<Event> events;

  const DayDetailsPage({super.key, required this.date, this.events = const []});

  @override
  Widget build(BuildContext context) {
    final completeDate = MyanmarCalendar.getCompleteDate(date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to create event with pre-filled date
              GoRouter.of(
                context,
              ).push('/events/create?date=${date.toIso8601String()}');
            },
            tooltip: 'Add Event',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date card
            _buildDateCard(context, completeDate),

            const SizedBox(height: 16),

            // Holidays
            if (completeDate.hasHolidays)
              _buildHolidaysCard(context, completeDate),

            const SizedBox(height: 16),

            // Full astrology information
            _buildAstrologyCard(context, completeDate),

            const SizedBox(height: 16),

            // Events section
            _buildEventsSection(context, date),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection(BuildContext context, DateTime date) {
    return BlocBuilder<EventsBloc, EventsState>(
      builder: (context, state) {
        if (state is! EventsLoaded) {
          // Load events for this date
          context.read<EventsBloc>().add(LoadEventsByDate(date));
          return const SizedBox.shrink();
        }

        final events = state.events;
        if (events.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Events (${events.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...events.map(
                (event) => ListTile(
                  leading: Container(
                    width: 4,
                    color: event.colorCode != null
                        ? Color(event.colorCode!)
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(event.title),
                  subtitle: event.eventTime != null
                      ? Text(
                          TimeOfDay.fromDateTime(
                            event.eventTime!,
                          ).format(context),
                        )
                      : const Text('All day'),
                  trailing: Icon(
                    event.priority > 0 ? Icons.flag : null,
                    color: _getPriorityColor(event.priority),
                  ),
                  onTap: () {
                    GoRouter.of(context).push('/events/${event.id}/detail');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateCard(BuildContext context, CompleteDate completeDate) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              completeDate.western.toDateTime().format('EEEE, MMMM d, yyyy'),
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              completeDate.formatMyanmar(),
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidaysCard(BuildContext context, CompleteDate completeDate) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: context.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Holidays',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...completeDate.allHolidays.map((holiday) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(holiday, style: context.textTheme.bodyMedium),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAstrologyCard(BuildContext context, CompleteDate completeDate) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: context.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Astrological Information',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // All astrological details
            _buildDetailRow(context, 'Sabbath', completeDate.sabbath),
            _buildDetailRow(context, 'Yatyaza', completeDate.yatyaza),
            _buildDetailRow(context, 'Pyathada', completeDate.pyathada),
            _buildDetailRow(context, 'Nagahle', completeDate.nagahle),
            _buildDetailRow(context, 'Mahabote', completeDate.mahabote),
            _buildDetailRow(context, 'Nakhat', completeDate.nakhat),
            _buildDetailRow(context, 'Year Name', completeDate.yearName),

            if (completeDate.astrologicalDays.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Special Days:',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: completeDate.astrologicalDays.map((day) {
                  return Chip(
                    label: Text(day),
                    backgroundColor: context.colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: context.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Color? _getPriorityColor(int priority) {
    switch (priority) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.blue;
      default:
        return null;
    }
  }
}
