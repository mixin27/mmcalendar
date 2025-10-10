import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/event.dart';
import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../bloc/events_state.dart';
import '../widgets/category_selector_field.dart';
import '../widgets/priority_selector.dart';

class EventFormPage extends StatefulWidget {
  final int? eventId; // null for create, value for edit

  const EventFormPage({super.key, this.eventId});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isAllDay = true;
  String _selectedCategory = 'Personal';
  int? _selectedCategoryId;
  int _priority = 0;
  List<String> _tags = [];

  bool _isLoading = false;
  // ignore: unused_field
  Event? _existingEvent;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      // Load existing event for editing
      context.read<EventsBloc>().add(LoadEventById(widget.eventId!));
    } else {
      // Load categories for new event
      context.read<EventsBloc>().add(const LoadCategories());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _populateFormWithEvent(Event event) {
    setState(() {
      _existingEvent = event;
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _locationController.text = event.location ?? '';
      _selectedDate = event.eventDate;
      if (event.eventTime != null) {
        _selectedTime = TimeOfDay.fromDateTime(event.eventTime!);
      }
      _isAllDay = event.isAllDay;
      _selectedCategory = event.category;
      _selectedCategoryId = event.categoryId;
      _priority = event.priority;
      _tags = event.tags ?? [];
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    DateTime? eventTime;
    if (!_isAllDay && _selectedTime != null) {
      eventTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    if (widget.eventId == null) {
      // Create new event
      context.read<EventsBloc>().add(
        CreateEvent(
          title: title,
          description: description.isEmpty ? null : description,
          eventDate: _selectedDate,
          eventTime: eventTime,
          isAllDay: _isAllDay,
          category: _selectedCategory,
          categoryId: _selectedCategoryId,
          location: location.isEmpty ? null : location,
          priority: _priority,
          tags: _tags.isEmpty ? null : _tags,
        ),
      );
    } else {
      // Update existing event
      context.read<EventsBloc>().add(
        UpdateEvent(
          eventId: widget.eventId!,
          title: title,
          description: description.isEmpty ? null : description,
          eventDate: _selectedDate,
          eventTime: eventTime,
          isAllDay: _isAllDay,
          category: _selectedCategory,
          categoryId: _selectedCategoryId,
          location: location.isEmpty ? null : location,
          priority: _priority,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventId == null ? 'New Event' : 'Edit Event'),
        actions: [
          if (widget.eventId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
              tooltip: 'Delete',
            ),
          TextButton(
            onPressed: _isLoading ? null : _saveEvent,
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: BlocConsumer<EventsBloc, EventsState>(
        listener: (context, state) {
          if (state is EventDetailLoaded) {
            _populateFormWithEvent(state.event);
          } else if (state is EventCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event created successfully')),
            );
            context.pop();
          } else if (state is EventUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event updated successfully')),
            );
            context.pop();
          } else if (state is EventDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event deleted successfully')),
            );
            context.pop();
          } else if (state is EventsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }

          setState(() {
            _isLoading = state is EventsLoading;
          });
        },
        builder: (context, state) {
          if (_isLoading && widget.eventId != null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title *',
                      hintText: 'Enter event title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter event title';
                      }
                      if (value.trim().length > 200) {
                        return 'Title too long (max 200 characters)';
                      }
                      return null;
                    },
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),

                  // Date field
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // All day toggle
                  SwitchListTile(
                    title: const Text('All Day Event'),
                    subtitle: const Text('Event lasts the entire day'),
                    value: _isAllDay,
                    onChanged: (value) {
                      setState(() {
                        _isAllDay = value;
                        if (value) {
                          _selectedTime = null;
                        }
                      });
                    },
                  ),

                  // Time field (only if not all day)
                  if (!_isAllDay) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Select time',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Category selector
                  CategorySelectorField(
                    selectedCategory: _selectedCategory,
                    selectedCategoryId: _selectedCategoryId,
                    categories: state is EventDetailLoaded
                        ? state.categories
                        : state is CategoriesLoaded
                        ? state.categories
                        : [],
                    onCategoryChanged: (category, categoryId) {
                      setState(() {
                        _selectedCategory = category;
                        _selectedCategoryId = categoryId;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Priority selector
                  PrioritySelector(
                    priority: _priority,
                    onPriorityChanged: (priority) {
                      setState(() {
                        _priority = priority;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location field
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'Enter location',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter event description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    maxLength: 1000,
                  ),
                  const SizedBox(height: 24),

                  // Save button (mobile)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _saveEvent,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        widget.eventId == null
                            ? 'Create Event'
                            : 'Update Event',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<EventsBloc>().add(DeleteEvent(widget.eventId!));
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
