import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

import '../../domain/entities/calendar_generation_mode.dart';
import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_generation_template.dart';
import '../../domain/entities/calendar_image_quality.dart';
import '../../domain/entities/calendar_landscape_decoration_area_side.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import '../../domain/entities/calendar_paper_size.dart';
import '../../domain/entities/calendar_preview_theme.dart';
import '../bloc/calendar_generation_bloc.dart';
import '../bloc/calendar_generation_event.dart';
import 'calendar_generation_template_grid.dart';
import 'calendar_generation_ui_sections.dart';

class CalendarGeneralSettingsContent extends StatelessWidget {
  const CalendarGeneralSettingsContent({required this.request, super.key});

  final CalendarGenerationRequest request;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List<int>.generate(12, (index) => now.year - 5 + index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: 'Generation Scope',
          description:
              'Choose whether to generate a single month or full year.',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<CalendarGenerationMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<CalendarGenerationMode>(
                  value: CalendarGenerationMode.month,
                  label: Text('Month'),
                  icon: Icon(Icons.calendar_view_month),
                ),
                ButtonSegment<CalendarGenerationMode>(
                  value: CalendarGenerationMode.year,
                  label: Text('Year'),
                  icon: Icon(Icons.calendar_view_day),
                ),
              ],
              selected: <CalendarGenerationMode>{request.mode},
              onSelectionChanged: (selection) {
                context.read<CalendarGenerationBloc>().add(
                  ChangeGenerationMode(selection.first),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        SettingsSection(
          title: 'Calendar & Period',
          description: 'Set calendar language and target month/year.',
          child: Column(
            children: [
              DropdownButtonFormField<Language>(
                initialValue: request.language,
                decoration: const InputDecoration(
                  labelText: 'Calendar Language',
                  border: OutlineInputBorder(),
                ),
                items: Language.values
                    .map(
                      (language) => DropdownMenuItem<Language>(
                        value: language,
                        child: Text(language.name.capitalize),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  context.read<CalendarGenerationBloc>().add(
                    ChangeGenerationLanguage(value),
                  );
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: request.year,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                items: years
                    .map(
                      (year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text('$year'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  context.read<CalendarGenerationBloc>().add(
                    ChangeGenerationYear(value),
                  );
                },
              ),
              if (request.mode == CalendarGenerationMode.month) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: request.month,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                  ),
                  items: List<int>.generate(12, (index) => index + 1)
                      .map(
                        (month) => DropdownMenuItem<int>(
                          value: month,
                          child: Text('$month'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    context.read<CalendarGenerationBloc>().add(
                      ChangeGenerationMonth(value),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class CalendarLayoutSettingsContent extends StatelessWidget {
  const CalendarLayoutSettingsContent({required this.request, super.key});

  final CalendarGenerationRequest request;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: 'Page Setup',
          description: 'Configure canvas size and orientation.',
          child: Column(
            children: [
              DropdownButtonFormField<CalendarPaperSize>(
                initialValue: request.paperSize,
                decoration: const InputDecoration(
                  labelText: 'Paper Size',
                  border: OutlineInputBorder(),
                ),
                items: CalendarPaperSize.values
                    .map(
                      (paperSize) => DropdownMenuItem<CalendarPaperSize>(
                        value: paperSize,
                        child: Text(paperSize.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  context.read<CalendarGenerationBloc>().add(
                    ChangePaperSize(value),
                  );
                },
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<CalendarPageOrientation>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<CalendarPageOrientation>(
                      value: CalendarPageOrientation.portrait,
                      label: Text('Portrait'),
                      icon: Icon(Icons.stay_current_portrait),
                    ),
                    ButtonSegment<CalendarPageOrientation>(
                      value: CalendarPageOrientation.landscape,
                      label: Text('Landscape'),
                      icon: Icon(Icons.stay_current_landscape),
                    ),
                  ],
                  selected: <CalendarPageOrientation>{request.pageOrientation},
                  onSelectionChanged: (selection) {
                    context.read<CalendarGenerationBloc>().add(
                      ChangePageOrientation(selection.first),
                    );
                  },
                ),
              ),
              if (request.pageOrientation ==
                  CalendarPageOrientation.landscape) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Landscape custom area side',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<CalendarLandscapeDecorationAreaSide>(
                    showSelectedIcon: false,
                    segments: CalendarLandscapeDecorationAreaSide.values
                        .map(
                          (side) =>
                              ButtonSegment<
                                CalendarLandscapeDecorationAreaSide
                              >(value: side, label: Text(side.label)),
                        )
                        .toList(growable: false),
                    selected: <CalendarLandscapeDecorationAreaSide>{
                      request.landscapeDecorationAreaSide,
                    },
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) {
                        return;
                      }
                      context.read<CalendarGenerationBloc>().add(
                        ChangeLandscapeDecorationAreaSide(selection.first),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        SettingsSection(
          title: 'Output Quality',
          description: 'Higher quality gives sharper exports with larger size.',
          child: DropdownButtonFormField<CalendarImageQuality>(
            initialValue: request.imageQuality,
            decoration: const InputDecoration(
              labelText: 'Image Quality',
              border: OutlineInputBorder(),
            ),
            items: CalendarImageQuality.values
                .map(
                  (quality) => DropdownMenuItem<CalendarImageQuality>(
                    value: quality,
                    child: Text(quality.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              context.read<CalendarGenerationBloc>().add(
                ChangeImageQuality(value),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CalendarVisibilitySettingsContent extends StatelessWidget {
  const CalendarVisibilitySettingsContent({required this.request, super.key});

  final CalendarGenerationRequest request;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: 'Date Cell Visibility',
          description: 'Choose which date details to display in cells.',
          child: Column(
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Holidays'),
                value: request.showHolidays,
                onChanged: (value) {
                  context.read<CalendarGenerationBloc>().add(
                    ToggleGenerationHolidays(value),
                  );
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Astrology'),
                value: request.showAstrology,
                onChanged: (value) {
                  context.read<CalendarGenerationBloc>().add(
                    ToggleGenerationAstrology(value),
                  );
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Western Dates'),
                value: request.showWesternDates,
                onChanged: (value) {
                  context.read<CalendarGenerationBloc>().add(
                    ToggleGenerationWesternDates(value),
                  );
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Myanmar Dates'),
                value: request.showMyanmarDates,
                onChanged: (value) {
                  context.read<CalendarGenerationBloc>().add(
                    ToggleGenerationMyanmarDates(value),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CalendarThemeSettingsContent extends StatelessWidget {
  const CalendarThemeSettingsContent({
    required this.request,
    required this.presetColors,
    super.key,
  });

  final CalendarGenerationRequest request;
  final List<Color> presetColors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: 'Color Theme',
          description: 'Define your calendar palette for text and accents.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ColorSelector(
                label: 'Background',
                colors: presetColors,
                selectedValue: request.theme.backgroundColorValue,
                onColorSelected: (color) {
                  context.read<CalendarGenerationBloc>().add(
                    ChangeBackgroundColor(color.toARGB32()),
                  );
                },
              ),
              const SizedBox(height: 10),
              ColorSelector(
                label: 'Foreground',
                colors: presetColors,
                selectedValue: request.theme.foregroundColorValue,
                onColorSelected: (color) {
                  context.read<CalendarGenerationBloc>().add(
                    ChangeForegroundColor(color.toARGB32()),
                  );
                },
              ),
              const SizedBox(height: 10),
              ColorSelector(
                label: 'Accent',
                colors: presetColors,
                selectedValue: request.theme.accentColorValue,
                onColorSelected: (color) {
                  context.read<CalendarGenerationBloc>().add(
                    ChangeAccentColor(color.toARGB32()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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

class CalendarTemplateSettingsContent extends StatelessWidget {
  const CalendarTemplateSettingsContent({
    required this.templates,
    required this.templatePreviewById,
    required this.selectedTemplateId,
    required this.templateNameController,
    required this.onSaveTemplate,
    required this.onApplyTemplate,
    required this.onRenameTemplate,
    required this.onDeleteTemplate,
    super.key,
  });

  final List<CalendarGenerationTemplate> templates;
  final Map<String, CalendarTemplatePreviewData> templatePreviewById;
  final String? selectedTemplateId;
  final TextEditingController templateNameController;
  final VoidCallback onSaveTemplate;
  final ValueChanged<CalendarGenerationTemplate> onApplyTemplate;
  final ValueChanged<CalendarGenerationTemplate> onRenameTemplate;
  final ValueChanged<CalendarGenerationTemplate> onDeleteTemplate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: 'Save Current Configuration',
          description: 'Store current settings as a reusable template.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: templateNameController,
                decoration: const InputDecoration(
                  labelText: 'Template Name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => onSaveTemplate(),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onSaveTemplate,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save Current As Template'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SettingsSection(
          title: 'Saved Templates',
          description: 'Apply, rename, or delete existing templates.',
          child: templates.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('No saved templates yet.'),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 10.0;
                    final crossAxisCount = (constraints.maxWidth / 176)
                        .floor()
                        .clamp(1, 4)
                        .toInt();
                    final tileWidth =
                        (constraints.maxWidth -
                            ((crossAxisCount - 1) * spacing)) /
                        crossAxisCount;
                    final tileHeight = tileWidth * 1.42;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: templates.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        childAspectRatio: tileWidth / tileHeight,
                      ),
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return CalendarTemplateGridCard(
                          template: template,
                          preview: templatePreviewById[template.id],
                          isSelected: selectedTemplateId == template.id,
                          onApply: () => onApplyTemplate(template),
                          onRename: () => onRenameTemplate(template),
                          onDelete: () => onDeleteTemplate(template),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
