import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../domain/entities/calendar_generation_mode.dart';
import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_generation_template.dart';
import '../../domain/entities/calendar_page_model.dart';
import 'calendar_generation_preview_page.dart';

class CalendarTemplatePreviewData {
  const CalendarTemplatePreviewData({
    required this.request,
    required this.model,
  });

  final CalendarGenerationRequest request;
  final CalendarPageModel model;
}

class CalendarTemplateGridCard extends StatelessWidget {
  const CalendarTemplateGridCard({
    required this.template,
    required this.preview,
    required this.isSelected,
    required this.onApply,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  final CalendarGenerationTemplate template;
  final CalendarTemplatePreviewData? preview;
  final bool isSelected;
  final VoidCallback onApply;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onApply,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isSelected ? 1.6 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _TemplatePreviewCanvas(preview: preview)),
              const SizedBox(height: 8),
              Text(
                template.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${template.language.name.capitalize} • ${_modeLabel(template.mode)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onApply,
                      child: const Text('Apply'),
                    ),
                  ),
                  PopupMenuButton<_TemplateAction>(
                    tooltip: 'Template actions',
                    onSelected: (action) {
                      switch (action) {
                        case _TemplateAction.rename:
                          onRename();
                          break;
                        case _TemplateAction.delete:
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<_TemplateAction>(
                        value: _TemplateAction.rename,
                        child: Text('Rename'),
                      ),
                      PopupMenuItem<_TemplateAction>(
                        value: _TemplateAction.delete,
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _modeLabel(CalendarGenerationMode mode) {
    return switch (mode) {
      CalendarGenerationMode.month => 'Month',
      CalendarGenerationMode.year => 'Year',
    };
  }
}

class _TemplatePreviewCanvas extends StatelessWidget {
  const _TemplatePreviewCanvas({required this.preview});

  final CalendarTemplatePreviewData? preview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (preview == null) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.calendar_view_month,
          color: colorScheme.onSurfaceVariant,
          size: 28,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AbsorbPointer(
          child: CalendarGenerationPreviewPage(
            model: preview!.model,
            request: preview!.request,
            margin: EdgeInsets.zero,
            elevation: 0,
            contentPadding: const EdgeInsets.all(6),
            compact: true,
          ),
        ),
      ),
    );
  }
}

enum _TemplateAction { rename, delete }
