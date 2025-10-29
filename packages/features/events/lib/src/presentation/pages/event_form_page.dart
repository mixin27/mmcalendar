import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/notification_setting.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../bloc/event_categories_bloc.dart';
import '../bloc/event_categories_event.dart';
import '../bloc/event_categories_state.dart';
import '../bloc/event_form_bloc.dart';
import '../bloc/event_form_event.dart';
import '../bloc/event_form_state.dart';
import '../widgets/category_chip.dart';

class EventFormPage extends StatefulWidget {
  final int? eventId;
  final DateTime? initialDate;

  const EventFormPage({super.key, this.eventId, this.initialDate});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.eventId != null) {
      context.read<EventFormBloc>().add(LoadEventForEdit(widget.eventId!));
    } else {
      context.read<EventFormBloc>().add(
        InitializeNewEvent(initialDate: widget.initialDate),
      );
    }

    // Load categories
    context.read<EventCategoriesBloc>().add(const LoadEventCategories());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventId == null ? 'New Event' : 'Edit Event'),
        actions: [
          BlocBuilder<EventFormBloc, EventFormState>(
            builder: (context, state) {
              if (state is! EventFormEditing) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.check),
                onPressed: state.isValid
                    ? () {
                        context.read<EventFormBloc>().add(
                          const SubmitEventForm(),
                        );
                      }
                    : null,
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<EventFormBloc, EventFormState>(
        listener: (context, state) {
          if (state is EventFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isNew ? 'Event created!' : 'Event updated!',
                ),
              ),
            );
            context.pop();
          } else if (state is EventFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EventFormSubmitting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! EventFormEditing) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildForm(state);
        },
      ),
    );
  }

  Widget _buildForm(EventFormEditing state) {
    // Update controllers if needed
    if (_titleController.text != state.title) {
      _titleController.text = state.title;
    }
    if (_descriptionController.text != state.description) {
      _descriptionController.text = state.description;
    }
    if (_locationController.text != state.location) {
      _locationController.text = state.location;
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title field
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Event Title *',
              hintText: 'Enter event title',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: state.errorMessage,
            ),
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              context.read<EventFormBloc>().add(UpdateEventTitle(value));
            },
          ),
          const SizedBox(height: 16),

          // Description field
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Add more details (optional)',
              prefixIcon: const Icon(Icons.description),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            onChanged: (value) {
              context.read<EventFormBloc>().add(UpdateEventDescription(value));
            },
          ),
          const SizedBox(height: 16),

          // Date and time section
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Date & Time',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date picker
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('Date'),
                    subtitle: Text(
                      DateFormat('EEEE, MMM d, yyyy').format(state.eventDate),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _selectDate(context, state.eventDate),
                  ),

                  // All day toggle
                  SwitchListTile(
                    secondary: const Icon(Icons.all_inclusive),
                    title: const Text('All day'),
                    value: state.isAllDay,
                    onChanged: (value) {
                      context.read<EventFormBloc>().add(const ToggleAllDay());
                    },
                  ),

                  // Time picker (if not all day)
                  if (!state.isAllDay)
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Time'),
                      subtitle: Text(
                        state.eventTime != null
                            ? TimeOfDay.fromDateTime(
                                state.eventTime!,
                              ).format(context)
                            : 'Select time',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _selectTime(context, state.eventTime),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category selection
          _buildCategorySection(state),
          const SizedBox(height: 16),

          // Priority selection
          _buildPrioritySection(state),
          const SizedBox(height: 16),

          // Location field
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Location',
              hintText: 'Add location (optional)',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              context.read<EventFormBloc>().add(UpdateEventLocation(value));
            },
          ),
          const SizedBox(height: 16),

          // Recurrence section
          _buildRecurrenceSection(state),
          const SizedBox(height: 16),

          // Notifications section
          _buildNotificationsSection(state),
          const SizedBox(height: 16),

          // Tags section
          _buildTagsSection(state),
          const SizedBox(height: 16),

          // Color picker
          _buildColorSection(state),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCategorySection(EventFormEditing state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Category',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            BlocBuilder<EventCategoriesBloc, EventCategoriesState>(
              builder: (context, categoriesState) {
                if (categoriesState is EventCategoriesLoaded) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categoriesState.categories.map((category) {
                      return CategoryChip(
                        category: category,
                        selected: category.id == state.category.id,
                        onTap: () {
                          context.read<EventFormBloc>().add(
                            UpdateEventCategory(category),
                          );
                        },
                      );
                    }).toList(),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySection(EventFormEditing state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Priority',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EventPriority.values.map((priority) {
                final isSelected = priority == state.priority;
                return FilterChip(
                  label: Text(priority.displayName),
                  selected: isSelected,
                  onSelected: (_) {
                    context.read<EventFormBloc>().add(
                      UpdateEventPriority(priority),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceSection(EventFormEditing state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.repeat, size: 20),
                const SizedBox(width: 8),
                Text('Repeat', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                state.recurrenceRule?.type.displayName ?? 'Does not repeat',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showRecurrencePicker(context, state.recurrenceRule),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(EventFormEditing state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  onPressed: () => _showNotificationPicker(context),
                ),
              ],
            ),
            if (state.notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No notifications'),
              )
            else
              ...state.notifications.asMap().entries.map((entry) {
                final index = entry.key;
                final notification = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm),
                  title: Text(notification.displayName),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      context.read<EventFormBloc>().add(
                        RemoveNotification(index),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(EventFormEditing state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.label, size: 20),
                const SizedBox(width: 8),
                Text('Tags', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Add tag',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        context.read<EventFormBloc>().add(AddTag(value));
                        _tagController.clear();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_tagController.text.isNotEmpty) {
                      context.read<EventFormBloc>().add(
                        AddTag(_tagController.text),
                      );
                      _tagController.clear();
                    }
                  },
                ),
              ],
            ),
            if (state.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      context.read<EventFormBloc>().add(RemoveTag(tag));
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColorSection(EventFormEditing state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: state.colorCode != null
                ? Color(state.colorCode!)
                : Color(state.category.colorCode),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        title: const Text('Custom Color'),
        subtitle: const Text('Override category color'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showColorPicker(context, state.colorCode),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && context.mounted) {
      context.read<EventFormBloc>().add(UpdateEventDate(picked));
    }
  }

  Future<void> _selectTime(BuildContext context, DateTime? currentTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime != null
          ? TimeOfDay.fromDateTime(currentTime)
          : TimeOfDay.now(),
    );

    if (picked != null && context.mounted) {
      final now = DateTime.now();
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      context.read<EventFormBloc>().add(UpdateEventTime(dateTime));
    }
  }

  void _showRecurrencePicker(BuildContext context, RecurrenceRule? current) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: RecurrenceType.values.map((type) {
            return ListTile(
              title: Text(type.displayName),
              trailing: current?.type == type ? const Icon(Icons.check) : null,
              onTap: () {
                final rule = type == RecurrenceType.none
                    ? null
                    : RecurrenceRule(type: type);
                this.context.read<EventFormBloc>().add(
                  UpdateRecurrenceRule(rule),
                );
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showNotificationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: NotificationSetting.defaultSettings.map((setting) {
            return ListTile(
              leading: const Icon(Icons.alarm),
              title: Text(setting.displayName),
              onTap: () {
                this.context.read<EventFormBloc>().add(
                  AddNotification(setting),
                );
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, int? currentColor) {
    Color pickerColor = currentColor != null
        ? Color(currentColor)
        : Colors.blue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Clear'),
            onPressed: () {
              this.context.read<EventFormBloc>().add(
                const UpdateEventColor(null),
              );
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Select'),
            onPressed: () {
              this.context.read<EventFormBloc>().add(
                UpdateEventColor(pickerColor.toARGB32()),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
