import 'package:flutter/material.dart';

import '../../../models/calendar_studio_document.dart';
import '../../../models/calendar_studio_types.dart';
import '../../../services/calendar_studio_controller.dart';
import '../../../theme/calendar_studio_theme.dart';
import 'calendar_parts_inspector.dart';
import 'image_inspector.dart';
import 'shape_inspector.dart';
import 'studio_inspector_host.dart';
import 'studio_layout_section.dart';
import 'text_inspector.dart';

/// The full settings for one block: a header with its actions, tabs for
/// its kind, and Layout last.
class CalendarStudioInspector extends StatelessWidget {
  const CalendarStudioInspector({
    required this.block,
    required this.host,
    required this.tab,
    required this.onTab,
    required this.onClose,
    required this.onDelete,
    this.scrollController,
    this.sheet = false,
    super.key,
  });
  final CalendarStudioBlock block;
  final StudioInspectorHost host;
  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final ScrollController? scrollController;
  final bool sheet;

  static bool _themed(CalendarStudioBlock block) => switch (block.type) {
    CalendarStudioBlockType.eventList =>
      block.content.containsKey('title') ||
          block.content.containsKey('placeholder') ||
          block.content['kind'] == 'notes',
    CalendarStudioBlockType.holidayLegend => block.content['kind'] == 'themed',
    _ => true,
  };

  /// Tab names for [block]; the last is always Layout.
  static List<String> tabsFor(
    CalendarStudioBlock block,
  ) => switch (block.type) {
    CalendarStudioBlockType.text => const ['Content', 'Style', 'Layout'],
    CalendarStudioBlockType.image ||
    CalendarStudioBlockType.logo => const ['Image', 'Layout'],
    CalendarStudioBlockType.shape ||
    CalendarStudioBlockType.decoration => const ['Style', 'Layout'],
    CalendarStudioBlockType.calendarGrid => const ['Data', 'Style', 'Layout'],
    CalendarStudioBlockType.eventList ||
    CalendarStudioBlockType.holidayLegend =>
      _themed(block) ? const ['Content', 'Style', 'Layout'] : const ['Layout'],
  };

  static IconData iconFor(CalendarStudioBlockType type) => switch (type) {
    CalendarStudioBlockType.calendarGrid => Icons.calendar_month_outlined,
    CalendarStudioBlockType.text => Icons.text_fields,
    CalendarStudioBlockType.image => Icons.image_outlined,
    CalendarStudioBlockType.logo => Icons.verified_outlined,
    CalendarStudioBlockType.eventList => Icons.event_note_outlined,
    CalendarStudioBlockType.holidayLegend => Icons.label_outline,
    CalendarStudioBlockType.shape => Icons.category_outlined,
    CalendarStudioBlockType.decoration => Icons.spa_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    final controller = host.controller;
    final tabs = tabsFor(block);
    final index = tab.clamp(0, tabs.length - 1);
    final layout = index == tabs.length - 1;
    return Material(
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(16, sheet ? 8 : 16, 16, 24),
        children: [
          if (sheet)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: tokens.ink3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Row(
            children: [
              Icon(iconFor(block.type)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (block.type == CalendarStudioBlockType.calendarGrid)
                      Text(
                        'Dates come from the app calendar',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.keyboard_arrow_down),
                tooltip: 'Close inspector',
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    controller.saveState == CalendarStudioSaveState.saving
                    ? null
                    : controller.saveNow,
                child: const Text('Save'),
              ),
              IconButton(
                onPressed: controller.duplicateSelected,
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Duplicate',
              ),
              IconButton(
                onPressed: () =>
                    host.update(block.copyWith(locked: !block.locked)),
                icon: Icon(
                  block.locked ? Icons.lock_outline : Icons.lock_open_outlined,
                ),
                tooltip: block.locked ? 'Unlock' : 'Lock',
              ),
              IconButton(
                onPressed: () =>
                    host.update(block.copyWith(visible: !block.visible)),
                icon: Icon(
                  block.visible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: block.visible ? 'Hide' : 'Show',
              ),
              IconButton(
                onPressed: onDelete,
                color: tokens.error,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
              ),
            ],
          ),
          if (tabs.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SegmentedButton<int>(
                key: const ValueKey('studio-inspector-tabs'),
                showSelectedIcon: false,
                segments: [
                  for (var i = 0; i < tabs.length; i++)
                    ButtonSegment(value: i, label: Text(tabs[i])),
                ],
                selected: {index},
                onSelectionChanged: (value) => onTab(value.first),
              ),
            ),
          if (layout)
            StudioLayoutSection(block: block, host: host)
          else
            _body(index),
        ],
      ),
    );
  }

  Widget _body(int index) => switch (block.type) {
    CalendarStudioBlockType.text => StudioTextInspector(
      block: block,
      host: host,
      tab: index,
    ),
    CalendarStudioBlockType.image || CalendarStudioBlockType.logo =>
      StudioImageInspector(block: block, host: host),
    CalendarStudioBlockType.shape => StudioShapeInspector(
      block: block,
      host: host,
    ),
    CalendarStudioBlockType.decoration => StudioDecorationInspector(
      block: block,
      host: host,
    ),
    CalendarStudioBlockType.calendarGrid => StudioGridInspector(
      block: block,
      host: host,
      tab: index,
    ),
    CalendarStudioBlockType.eventList => StudioEventListInspector(
      block: block,
      host: host,
      tab: index,
    ),
    CalendarStudioBlockType.holidayLegend => StudioLegendInspector(
      block: block,
      host: host,
      tab: index,
    ),
  };
}
