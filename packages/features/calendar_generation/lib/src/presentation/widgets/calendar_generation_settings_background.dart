import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_preview_theme.dart';
import '../bloc/calendar_generation_bloc.dart';
import '../bloc/calendar_generation_event.dart';
import 'calendar_generation_ui_sections.dart';

class CalendarBackgroundSettingsContent extends StatelessWidget {
  const CalendarBackgroundSettingsContent({
    required this.request,
    required this.selectedMonth,
    required this.selectedImage,
    required this.imageUrlController,
    required this.imageUrlFocusNode,
    required this.onMonthChanged,
    required this.onSubmittedUrl,
    required this.onPickImage,
    required this.onClear,
    required this.onApplyUrl,
    required this.showPickedImageHint,
    super.key,
  });

  final CalendarGenerationRequest request;
  final int? selectedMonth;
  final String selectedImage;
  final TextEditingController imageUrlController;
  final FocusNode imageUrlFocusNode;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<String> onSubmittedUrl;
  final VoidCallback onPickImage;
  final VoidCallback onClear;
  final VoidCallback onApplyUrl;
  final bool showPickedImageHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: 'Scope',
          description:
              'Choose whether image applies to all months or one month.',
          child: DropdownButtonFormField<int?>(
            initialValue: selectedMonth,
            decoration: const InputDecoration(
              labelText: 'Image Scope',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Default (All months)'),
              ),
              ...List<DropdownMenuItem<int?>>.generate(
                12,
                (index) => DropdownMenuItem<int?>(
                  value: index + 1,
                  child: Text('Month ${index + 1}'),
                ),
              ),
            ],
            onChanged: onMonthChanged,
          ),
        ),
        const SizedBox(height: 10),
        SettingsSection(
          title: 'Placement',
          description: 'Control image fit, alignment, and opacity.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<CalendarBackgroundImageFit>(
                initialValue: request.theme.backgroundImageFit,
                decoration: const InputDecoration(
                  labelText: 'Image Fit',
                  border: OutlineInputBorder(),
                ),
                items: CalendarBackgroundImageFit.values
                    .map(
                      (fit) => DropdownMenuItem<CalendarBackgroundImageFit>(
                        value: fit,
                        child: Text(fit.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  context.read<CalendarGenerationBloc>().add(
                    ChangeBackgroundImageFit(value),
                  );
                },
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<CalendarBackgroundImageAlignment>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<CalendarBackgroundImageAlignment>(
                      value: CalendarBackgroundImageAlignment.top,
                      label: Text('Top'),
                    ),
                    ButtonSegment<CalendarBackgroundImageAlignment>(
                      value: CalendarBackgroundImageAlignment.center,
                      label: Text('Center'),
                    ),
                    ButtonSegment<CalendarBackgroundImageAlignment>(
                      value: CalendarBackgroundImageAlignment.bottom,
                      label: Text('Bottom'),
                    ),
                  ],
                  selected: <CalendarBackgroundImageAlignment>{
                    request.theme.backgroundImageAlignment,
                  },
                  onSelectionChanged: (selection) {
                    context.read<CalendarGenerationBloc>().add(
                      ChangeBackgroundImageAlignment(selection.first),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Image Opacity (${(request.theme.backgroundImageOpacity * 100).round()}%)',
              ),
              Slider(
                value: request.theme.backgroundImageOpacity.clamp(0.0, 1.0),
                min: 0,
                max: 1,
                divisions: 20,
                onChanged: (value) {
                  context.read<CalendarGenerationBloc>().add(
                    ChangeBackgroundImageOpacity(value),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SettingsSection(
          title: 'Image Source',
          description: 'Use device picker or provide image URL/path.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: imageUrlController,
                focusNode: imageUrlFocusNode,
                decoration: InputDecoration(
                  labelText: selectedMonth == null
                      ? 'Background Image URL (optional)'
                      : 'Month ${selectedMonth!} Image URL (optional)',
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: onSubmittedUrl,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onPickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Pick Image'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onApplyUrl,
                    icon: const Icon(Icons.check),
                    label: const Text('Apply URL'),
                  ),
                ],
              ),
              if (showPickedImageHint)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Using picked image from device for this scope.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (!showPickedImageHint && selectedImage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    selectedImage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
