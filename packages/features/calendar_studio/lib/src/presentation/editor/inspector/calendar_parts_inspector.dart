import 'package:flutter/material.dart';

import '../../../models/calendar_studio_document.dart';
import '../../../models/calendar_studio_types.dart';
import '../../../widgets/calendar_studio_theme_blocks.dart';
import '../../calendar_studio_strings.dart';
import 'studio_inspector_controls.dart';
import 'studio_inspector_host.dart';

/// One colour key of a calendar part, with its label.
typedef _ColorKey = (String key, String label);

List<Widget> _colors(
  CalendarStudioBlock block,
  StudioInspectorHost host,
  List<_ColorKey> keys,
) {
  final page = host.pageColors(host.controller.currentPage);
  return [
    for (final (key, label) in keys)
      StudioColorField(
        id: key,
        label: label,
        value: block.style[key] as int?,
        host: host,
        pageColors: page,
        onChanged: (value) => host.setStyle(block, key, value),
      ),
  ];
}

Widget? _applyAll(CalendarStudioBlock block, StudioInspectorHost host) {
  final apply = host.applyToAllPages;
  if (apply == null) return null;
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: OutlinedButton.icon(
      key: const ValueKey('studio-apply-style-all'),
      onPressed: () => apply(block),
      icon: const Icon(Icons.library_add_check_outlined),
      label: const Text(StudioStrings.applyToAllMonths),
    ),
  );
}

/// Calendar grid: Data (what days show) and Style.
class StudioGridInspector extends StatelessWidget {
  const StudioGridInspector({
    required this.block,
    required this.host,
    required this.tab,
    super.key,
  });
  final CalendarStudioBlock block;
  final StudioInspectorHost host;
  final int tab;

  @override
  Widget build(BuildContext context) =>
      tab == 0 ? _data(context) : _style(context);

  Widget _data(BuildContext context) {
    final controller = host.controller;
    final current = controller.project!.source;
    void source(CalendarStudioSource value) => controller.updateSource(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSection(
          title: 'Days show',
          children: [
            StudioSwitch(
              label: 'Myanmar dates',
              value: current.showMyanmarDate,
              onChanged: (v) => source(current.copyWith(showMyanmarDate: v)),
            ),
            StudioSwitch(
              label: 'Moon phases',
              value: current.showMoonPhases,
              onChanged: (v) => source(current.copyWith(showMoonPhases: v)),
            ),
            StudioSwitch(
              label: 'Public holidays',
              value: current.showHolidays,
              onChanged: (v) => source(current.copyWith(showHolidays: v)),
            ),
            StudioSwitch(
              label: 'Astrology days',
              value: current.showAstrology,
              onChanged: (v) => source(current.copyWith(showAstrology: v)),
            ),
            StudioSwitch(
              label: 'My events',
              value: current.showEvents,
              onChanged: (v) => source(current.copyWith(showEvents: v)),
            ),
          ],
        ),
        StudioSection(
          title: 'Weeks',
          children: [
            StudioFieldRow(
              label: 'Week starts',
              child: StudioSegmented<bool>(
                segments: const [(false, 'Sun', null), (true, 'Mon', null)],
                value: current.weekStartsMonday,
                onChanged: (v) => source(current.copyWith(weekStartsMonday: v)),
              ),
            ),
            StudioFieldRow(
              label: 'Rows',
              child: StudioSegmented<String>(
                segments: const [
                  ('fixed', 'Always 6', null),
                  ('auto', 'As needed', null),
                ],
                value: block.style['rows'] == 'auto' ? 'auto' : 'fixed',
                onChanged: (v) =>
                    host.setStyle(block, 'rows', v == 'auto' ? 'auto' : null),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _style(BuildContext context) {
    final rowHeight = (block.style['rowHeight'] as num?)?.toDouble() ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSection(
          title: 'Look',
          children: [
            StudioFieldRow(
              label: 'Day style',
              child: StudioSegmented<String>(
                segments: const [
                  ('standard', 'Standard', null),
                  ('plain', 'Plain', null),
                  ('moonlight', 'Moon', null),
                ],
                value: block.content['calendarStyle'] as String? ?? 'standard',
                onChanged: (v) => host.setContent(block, 'calendarStyle', v),
              ),
            ),
            StudioFieldRow(
              label: 'Grid lines',
              child: StudioSegmented<String>(
                segments: const [
                  ('none', 'None', null),
                  ('light', 'Light', null),
                  ('full', 'Full', null),
                  ('boxed', 'Boxed', null),
                ],
                value: block.style['gridLines'] as String? ?? 'light',
                onChanged: (v) => host.setStyle(block, 'gridLines', v),
              ),
            ),
            StudioStepper(
              label: 'Row height',
              unit: '%',
              value: rowHeight * 100,
              min: 75,
              max: 135,
              step: 5,
              onChanged: (v) => host.setStyle(block, 'rowHeight', v / 100),
            ),
          ],
        ),
        StudioSection(
          title: 'Numbers',
          children: [
            StudioFieldRow(
              label: 'Number font',
              child: StudioSegmented<String>(
                segments: const [
                  ('serif', 'Serif', null),
                  ('sans', 'Sans', null),
                ],
                value: block.style['numberFont'] as String? ?? 'serif',
                onChanged: (v) => host.setStyle(block, 'numberFont', v),
              ),
            ),
            StudioFontField(
              label: 'Numeral family',
              value: block.style['numberFamily'] as String? ?? 'Fraunces',
              onChanged: (v) => host.setStyle(block, 'numberFamily', v),
            ),
          ],
        ),
        StudioSection(
          title: 'Colours',
          children: _colors(block, host, const [
            ('inkColor', 'Day numbers'),
            ('secondaryColor', 'Myanmar dates'),
            ('mutedColor', 'Weekday second line'),
            ('headerColor', 'Weekday names'),
            ('weekendColor', 'Weekends'),
            ('holidayColor', 'Holidays'),
            ('sabbathColor', 'Sabbath'),
            ('eventColor', 'Events'),
            ('lineColor', 'Lines'),
          ]),
        ),
        ?_applyAll(block, host),
      ],
    );
  }
}

/// Event list: Content (title) and Style.
class StudioEventListInspector extends StatelessWidget {
  const StudioEventListInspector({
    required this.block,
    required this.host,
    required this.tab,
    super.key,
  });
  final CalendarStudioBlock block;
  final StudioInspectorHost host;
  final int tab;

  @override
  Widget build(BuildContext context) {
    if (tab == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioTextField(
            key: ValueKey('studio-event-title-${block.id}'),
            host: host,
            label: 'Title',
            value: block.content['title'] as String? ?? '',
            onChanged: (v) => host.setContent(block, 'title', v),
          ),
          if (block.content['kind'] != 'notes')
            StudioTextField(
              key: ValueKey('studio-event-empty-${block.id}'),
              host: host,
              label: 'When a month has no events',
              value: block.content['placeholder'] as String? ?? '',
              onChanged: (v) => host.setContent(block, 'placeholder', v),
            ),
          const SizedBox(height: 8),
          const Text(
            'Events come from the calendar data. Turn My events on or off in '
            'the calendar grid’s Data tab.',
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSection(
          title: 'Text',
          children: [
            StudioFontField(
              label: 'Font',
              value:
                  block.style['fontFamily'] as String? ?? 'Noto Sans Myanmar',
              onChanged: (v) => host.setStyle(block, 'fontFamily', v),
            ),
            StudioStepper(
              label: 'Size',
              value: (block.style['fontSize'] as num?)?.toDouble() ?? 10,
              min: 6,
              max: 60,
              onChanged: (v) => host.setStyle(block, 'fontSize', v),
            ),
          ],
        ),
        StudioSection(
          title: 'Colours',
          children: _colors(block, host, const [
            ('titleColor', 'Title'),
            ('inkColor', 'Event names'),
            ('mutedColor', 'Dates'),
            ('lineColor', 'Lines'),
          ]),
        ),
        ?_applyAll(block, host),
      ],
    );
  }
}

/// Holiday legend: Content (which marks) and Style.
class StudioLegendInspector extends StatelessWidget {
  const StudioLegendInspector({
    required this.block,
    required this.host,
    required this.tab,
    super.key,
  });
  final CalendarStudioBlock block;
  final StudioInspectorHost host;
  final int tab;

  @override
  Widget build(BuildContext context) {
    if (tab == 0) {
      final names = (block.content['items'] as List?)?.whereType<String>();
      final shown = names == null
          ? StudioLegendItem.values.toSet()
          : {
              for (final name in names)
                ?StudioLegendItem.values.asNameMap()[name],
            };
      return StudioSection(
        title: 'Shows',
        children: [
          for (final item in StudioLegendItem.values)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: shown.contains(item),
              title: Text(item.english),
              onChanged: (on) => host.setContent(block, 'items', [
                for (final value in StudioLegendItem.values)
                  if (value == item ? on == true : shown.contains(value))
                    value.name,
              ]),
            ),
          const Text('A mark only appears when the calendar shows it too.'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSection(
          title: 'Text',
          children: [
            StudioFontField(
              label: 'Font',
              value:
                  block.style['fontFamily'] as String? ?? 'Noto Sans Myanmar',
              onChanged: (v) => host.setStyle(block, 'fontFamily', v),
            ),
            StudioStepper(
              label: 'Size',
              value: (block.style['fontSize'] as num?)?.toDouble() ?? 10,
              min: 6,
              max: 40,
              onChanged: (v) => host.setStyle(block, 'fontSize', v),
            ),
            StudioFieldRow(
              label: 'Align',
              child: StudioSegmented<String>(
                segments: const [
                  ('left', null, Icons.format_align_left),
                  ('center', null, Icons.format_align_center),
                  ('right', null, Icons.format_align_right),
                ],
                value: block.style['align'] as String? ?? 'left',
                onChanged: (v) => host.setStyle(block, 'align', v),
              ),
            ),
          ],
        ),
        StudioSection(
          title: 'Colours',
          children: _colors(block, host, const [
            ('inkColor', 'Labels'),
            ('holidayColor', 'Holiday'),
            ('sabbathColor', 'Sabbath'),
            ('moonColor', 'Full moon'),
            ('eventColor', 'Events'),
          ]),
        ),
        ?_applyAll(block, host),
      ],
    );
  }
}
