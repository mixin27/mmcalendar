import 'package:flutter/material.dart';

import '../../../models/calendar_studio_document.dart';
import '../../../widgets/calendar_studio_decorations.dart';
import 'studio_inspector_controls.dart';
import 'studio_inspector_host.dart';

const _shapes = [
  'rectangle',
  'rounded',
  'circle',
  'oval',
  'triangle',
  'diamond',
  'pentagon',
  'hexagon',
  'octagon',
  'star',
  'heart',
  'arrow',
  'line',
];

String _title(String value) {
  final spaced = value.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => ' ${m[0]!.toLowerCase()}',
  );
  return spaced[0].toUpperCase() + spaced.substring(1);
}

Widget _opacity(CalendarStudioBlock block, StudioInspectorHost host) {
  final opacity = (block.style['opacity'] as num?)?.toDouble() ?? 1;
  return Row(
    children: [
      const SizedBox(width: 70, child: Text('Opacity')),
      Expanded(
        child: Slider(
          min: .1,
          max: 1,
          divisions: 18,
          value: opacity.clamp(.1, 1),
          label: '${(opacity * 100).round()}%',
          onChangeStart: (_) => host.controller.beginBlockInteraction(),
          onChangeEnd: (_) => host.controller.endBlockInteraction(),
          onChanged: (value) => host.controller.updateBlockLive(
            block.copyWith(style: {...block.style, 'opacity': value}),
          ),
        ),
      ),
      SizedBox(width: 46, child: Text('${(opacity * 100).round()}%')),
    ],
  );
}

class StudioShapeInspector extends StatelessWidget {
  const StudioShapeInspector({
    required this.block,
    required this.host,
    super.key,
  });
  final CalendarStudioBlock block;
  final StudioInspectorHost host;

  @override
  Widget build(BuildContext context) {
    final shape = block.content['shape'] as String? ?? 'rectangle';
    final filled = block.style['fill'] != 'none';
    final strokeWidth = (block.style['strokeWidth'] as num?)?.toDouble() ?? 0;
    final page = host.pageColors(host.controller.currentPage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSection(
          title: 'Shape',
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final value in _shapes)
                  ChoiceChip(
                    label: Text(_title(value)),
                    selected: shape == value,
                    onSelected: (_) => host.setContent(block, 'shape', value),
                  ),
              ],
            ),
          ],
        ),
        StudioSection(
          title: 'Fill',
          children: [
            StudioSwitch(
              label: 'Filled',
              value: filled,
              onChanged: (value) => host.update(
                block.copyWith(
                  style: {
                    for (final entry in block.style.entries)
                      if (entry.key != 'fill') entry.key: entry.value,
                    if (!value) 'fill': 'none',
                    if (!value && strokeWidth <= 0) 'strokeWidth': 2,
                  },
                ),
              ),
            ),
            if (filled)
              StudioColorField(
                id: 'fill',
                label: 'Fill colour',
                value: block.style['color'] as int?,
                host: host,
                pageColors: page,
                onChanged: (value) => host.setStyle(block, 'color', value),
              ),
            _opacity(block, host),
          ],
        ),
        StudioSection(
          title: 'Outline',
          children: [
            StudioStepper(
              label: 'Width',
              unit: 'px',
              value: strokeWidth,
              max: 40,
              onChanged: (value) => host.setStyle(block, 'strokeWidth', value),
            ),
            if (strokeWidth > 0)
              StudioColorField(
                id: 'stroke',
                label: 'Outline colour',
                value: block.style['strokeColor'] as int?,
                host: host,
                pageColors: page,
                onChanged: (value) =>
                    host.setStyle(block, 'strokeColor', value),
              ),
          ],
        ),
      ],
    );
  }
}

class StudioDecorationInspector extends StatelessWidget {
  const StudioDecorationInspector({
    required this.block,
    required this.host,
    super.key,
  });
  final CalendarStudioBlock block;
  final StudioInspectorHost host;

  @override
  Widget build(BuildContext context) {
    final kind = block.content['kind'];
    final motif =
        kind is String && CalendarStudioDecorations.kinds.contains(kind);
    final page = host.pageColors(host.controller.currentPage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (motif)
          StudioSection(
            title: 'Motif',
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final value in CalendarStudioDecorations.kinds)
                    ChoiceChip(
                      label: Text(_title(value)),
                      selected: kind == value,
                      onSelected: (_) => host.setContent(block, 'kind', value),
                    ),
                ],
              ),
            ],
          ),
        StudioSection(
          title: 'Colour',
          children: [
            if (motif) ...[
              StudioColorField(
                id: 'motif',
                label: 'Main colour',
                value: block.style['color'] as int?,
                host: host,
                pageColors: page,
                onChanged: (value) => host.setStyle(block, 'color', value),
              ),
              StudioColorField(
                id: 'accent',
                label: 'Accent colour',
                value: block.style['accent'] as int?,
                host: host,
                pageColors: page,
                onChanged: (value) => host.setStyle(block, 'accent', value),
              ),
              _opacity(block, host),
            ] else
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('This artwork keeps the template’s own colours.'),
              ),
          ],
        ),
      ],
    );
  }
}
