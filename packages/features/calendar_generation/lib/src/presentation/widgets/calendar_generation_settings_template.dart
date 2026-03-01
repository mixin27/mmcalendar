import 'package:flutter/material.dart';

import '../../domain/entities/calendar_generation_template.dart';
import 'calendar_generation_template_grid.dart';
import 'calendar_generation_ui_sections.dart';

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
