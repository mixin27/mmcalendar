import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart'
    show CalendarLanguageContext, showAppMyanmarDatePicker;
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' hide ContextExtension;
import '../../domain/entities/event.dart';
import '../../domain/entities/notification_setting.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../bloc/event_categories_bloc.dart';
import '../bloc/event_categories_event.dart';
import '../bloc/event_categories_state.dart';
import '../bloc/event_form_bloc.dart';
import '../bloc/event_form_event.dart';
import '../bloc/event_form_state.dart';
import '../widgets/form_field_row.dart';

class EventFormPage extends StatefulWidget {
  final int? eventId;
  final DateTime? initialDate;

  const EventFormPage({super.key, this.eventId, this.initialDate});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
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
    final t = context.tokens;
    final isNew = widget.eventId == null;
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<EventFormBloc, EventFormState>(
      listener: (context, state) {
        if (state is EventFormSuccess) {
          context.showToast(
            state.isNew
                ? (l10n?.eventsEventCreated ?? 'Event created')
                : (l10n?.eventsEventUpdated ?? 'Event updated'),
            kind: AppToastKind.success,
          );
          context.pop();
        } else if (state is EventFormError) {
          context.showToast(state.failure.message, kind: AppToastKind.error);
        }
      },
      builder: (context, state) {
        final editing = state is EventFormEditing ? state : null;
        final submitting = state is EventFormSubmitting;
        final canSave = editing != null && editing.isValid && !submitting;
        return AppPage(
          title: isNew
              ? (l10n?.newEvent ?? 'New Event')
              : (l10n?.eventsEditEventTitle ?? 'Edit Event'),
          largeTitle: false,
          previousTitle: l10n?.cancel ?? 'Cancel',
          actions: [
            if (t.isClear)
              TextButton(
                onPressed: canSave ? _submitForm : null,
                child: Text(
                  isNew ? (l10n?.add ?? 'Add') : (l10n?.save ?? 'Save'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
          children: editing == null
              ? const [
                  Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ]
              : [
                  ..._formGroups(editing),
                  if (!t.isClear)
                    AppButton(
                      label: submitting
                          ? (l10n?.eventsSaving ?? 'Saving…')
                          : (isNew
                                ? (l10n?.eventsCreateEvent ?? 'Create Event')
                                : (l10n?.eventsSaveChanges ?? 'Save Changes')),
                      icon: Icons.check,
                      onPressed: canSave ? _submitForm : null,
                    ),
                ],
        );
      },
    );
  }

  List<Widget> _formGroups(EventFormEditing state) {
    final t = context.tokens;
    final bloc = context.read<EventFormBloc>();
    final l10n = AppLocalizations.of(context);
    if (_titleController.text != state.title) {
      _titleController.text = state.title;
    }
    if (_descriptionController.text != state.description) {
      _descriptionController.text = state.description;
    }
    if (_locationController.text != state.location) {
      _locationController.text = state.location;
    }
    final color = Color(state.colorCode ?? state.category.colorCode);

    return [
      AppGroup(
        footer: state.errorMessage,
        children: [
          FormFieldRow(
            controller: _titleController,
            hint: l10n?.title ?? 'Title',
            autofocus: widget.eventId == null,
            onChanged: (v) => bloc.add(UpdateEventTitle(v)),
          ),
          FormFieldRow(
            controller: _descriptionController,
            hint: l10n?.description ?? 'Description',
            maxLines: 4,
            onChanged: (v) => bloc.add(UpdateEventDescription(v)),
          ),
        ],
      ),
      AppGroup(
        children: [
          AppRow(
            icon: Icons.event,
            iconColor: t.holiday,
            title: l10n?.date ?? 'Date',
            value:
                '${context.calendarFormat.shortDate(state.eventDate)} '
                '${context.calendarFormat.number(state.eventDate.year)}',
            chevron: true,
            onTap: () => _selectDate(context, state.eventDate),
          ),
          AppRow.toggle(
            icon: Icons.schedule,
            iconColor: t.accent,
            title: l10n?.allDay ?? 'All day',
            value: state.isAllDay,
            onChanged: (_) => bloc.add(const ToggleAllDay()),
          ),
          if (!state.isAllDay)
            AppRow(
              icon: Icons.access_time,
              iconColor: t.accent,
              title: l10n?.time ?? 'Time',
              value: state.eventTime != null
                  ? TimeOfDay.fromDateTime(state.eventTime!).format(context)
                  : (l10n?.select ?? 'Select'),
              chevron: true,
              onTap: () =>
                  _selectTime(context, state.eventTime, state.eventDate),
            ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppGroupLabel(l10n?.category ?? 'Category'),
          BlocBuilder<EventCategoriesBloc, EventCategoriesState>(
            builder: (context, categories) =>
                categories is EventCategoriesLoaded
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in categories.categories)
                        AppChip(
                          label: category.name,
                          icon: Icons.circle,
                          selected: category.id == state.category.id,
                          onSelected: (_) =>
                              bloc.add(UpdateEventCategory(category)),
                        ),
                    ],
                  )
                : const LinearProgressIndicator(minHeight: 2),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppGroupLabel(l10n?.priority ?? 'Priority'),
          AppSegmented<EventPriority>(
            segments: {for (final p in EventPriority.values) p: p.displayName},
            value: state.priority,
            onChanged: (p) => bloc.add(UpdateEventPriority(p)),
          ),
        ],
      ),
      AppGroup(
        children: [
          FormFieldRow(
            controller: _locationController,
            hint: l10n?.location ?? 'Location',
            icon: Icons.location_on_outlined,
            onChanged: (v) => bloc.add(UpdateEventLocation(v)),
          ),
          AppRow(
            icon: Icons.repeat,
            iconColor: const Color(0xFF8E8E93),
            title: l10n?.repeat ?? 'Repeat',
            value:
                state.recurrenceRule?.type.displayName ??
                (l10n?.never ?? 'Never'),
            chevron: true,
            onTap: () => _showRecurrencePicker(context, state.recurrenceRule),
          ),
        ],
      ),
      AppGroup(
        label: l10n?.reminders ?? 'Reminders',
        children: [
          for (final (index, notification) in state.notifications.indexed)
            AppRow(
              icon: Icons.notifications_none_rounded,
              iconColor: t.holiday,
              title: notification.displayName,
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: t.holiday,
                tooltip: l10n?.eventsRemoveReminder ?? 'Remove reminder',
                onPressed: () => bloc.add(RemoveNotification(index)),
              ),
            ),
          AppRow(
            title: l10n?.eventsAddReminder ?? 'Add reminder',
            tone: AppRowTone.accent,
            onTap: () => _showNotificationPicker(context),
          ),
        ],
      ),
      AppGroup(
        label: l10n?.tags ?? 'Tags',
        children: [
          FormFieldRow(
            controller: _tagController,
            hint: l10n?.eventsAddTagHint ?? 'Add a tag and press return',
            icon: Icons.sell_outlined,
            onSubmitted: (value) {
              if (value.trim().isEmpty) return;
              bloc.add(AddTag(value.trim()));
              _tagController.clear();
            },
          ),
          if (state.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in state.tags)
                    InputChip(
                      label: Text(tag),
                      onDeleted: () => bloc.add(RemoveTag(tag)),
                    ),
                ],
              ),
            ),
        ],
      ),
      AppGroup(
        children: [
          AppRow(
            leading: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: t.separator),
              ),
            ),
            title: l10n?.colour ?? 'Colour',
            value: state.colorCode == null
                ? (l10n?.eventsCategoryColour ?? 'Category colour')
                : (l10n?.custom ?? 'Custom'),
            chevron: true,
            onTap: () => _showColorPicker(context, state.colorCode),
          ),
        ],
      ),
    ];
  }

  Future<void> _selectDate(BuildContext context, DateTime currentDate) async {
    final picked = await showAppMyanmarDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && context.mounted) {
      context.read<EventFormBloc>().add(UpdateEventDate(picked));
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    DateTime? currentTime,
    DateTime selectedDate,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime != null
          ? TimeOfDay.fromDateTime(currentTime)
          : TimeOfDay.now(),
    );

    if (picked != null && context.mounted) {
      final dateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        picked.hour,
        picked.minute,
      );
      context.read<EventFormBloc>().add(UpdateEventTime(dateTime));
    }
  }

  void _submitForm() {
    final currentState = context.read<EventFormBloc>().state;
    if (currentState is! EventFormEditing) return;

    if (!currentState.isValid) {
      context.showToast(
        currentState.errorMessage ??
            (AppLocalizations.of(context)?.eventsFillRequiredFields ??
                'Please fill in required fields'),
        kind: AppToastKind.error,
      );
      return;
    }

    context.read<EventFormBloc>().add(const SubmitEventForm());
  }

  void _showRecurrencePicker(BuildContext context, RecurrenceRule? current) {
    final bloc = context.read<EventFormBloc>();
    final l10n = AppLocalizations.of(context);
    showAppSheet<void>(
      context: context,
      title: l10n?.repeat ?? 'Repeat',
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: AppGroup(
          children: [
            for (final type in RecurrenceType.values)
              AppRow(
                title: type == RecurrenceType.none
                    ? (l10n?.never ?? 'Never')
                    : type.displayName,
                selected: (current?.type ?? RecurrenceType.none) == type,
                onTap: () {
                  bloc.add(
                    UpdateRecurrenceRule(
                      type == RecurrenceType.none
                          ? null
                          : RecurrenceRule(type: type),
                    ),
                  );
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showNotificationPicker(BuildContext context) {
    final bloc = context.read<EventFormBloc>();
    showAppSheet<void>(
      context: context,
      title: AppLocalizations.of(context)?.eventsAddReminder ?? 'Add reminder',
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: AppGroup(
          children: [
            for (final setting in NotificationSetting.defaultSettings)
              AppRow(
                title: setting.displayName,
                onTap: () {
                  bloc.add(AddNotification(setting));
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, int? currentColor) {
    Color pickerColor = currentColor != null
        ? Color(currentColor)
        : Colors.blue;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.eventsPickAColor ?? 'Pick a color'),
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
            child: Text(l10n?.clear ?? 'Clear'),
            onPressed: () {
              this.context.read<EventFormBloc>().add(
                const UpdateEventColor(null),
              );
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(l10n?.cancel ?? 'Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(l10n?.select ?? 'Select'),
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
