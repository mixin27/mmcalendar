import 'package:flutter/material.dart';

import '../../../models/calendar_studio_document.dart';
import '../../../templates/calendar_studio_bindings.dart';
import '../../../templates/calendar_studio_text_styles.dart';
import '../../../theme/calendar_studio_theme.dart';
import 'studio_inspector_controls.dart';
import 'studio_inspector_host.dart';
import '../../calendar_studio_strings.dart';

/// Text: Content, Style (tabs 0 and 1; Layout is shared).
class StudioTextInspector extends StatelessWidget {
  const StudioTextInspector({
    required this.block,
    required this.host,
    required this.tab,
    super.key,
  });
  final CalendarStudioBlock block;
  final StudioInspectorHost host;
  final int tab;

  static const _weights = [
    (300, 'Light'),
    (400, 'Regular'),
    (500, 'Medium'),
    (600, 'Semibold'),
    (700, 'Bold'),
    (900, 'Black'),
  ];

  static const _bindings = [
    (null, 'Your text'),
    (CalendarStudioBinding.monthTitle, 'Month name'),
    (CalendarStudioBinding.yearTitle, 'Year'),
    (CalendarStudioBinding.monthYear, 'Month and year'),
    (CalendarStudioBinding.eraLine, 'Myanmar months and era'),
  ];

  @override
  Widget build(BuildContext context) =>
      tab == 0 ? _content(context) : _style(context);

  /// Typed text replaces any month binding, so it stays as written.
  void _setText(String text) {
    final content = {
      for (final entry in block.content.entries)
        if (entry.key != CalendarStudioBindings.key) entry.key: entry.value,
      'text': text,
    };
    host.update(block.copyWith(content: content));
  }

  void _bind(CalendarStudioBinding? binding) {
    final controller = host.controller;
    if (binding == null) {
      host.update(
        block.copyWith(
          content: {
            for (final entry in block.content.entries)
              if (entry.key != CalendarStudioBindings.key)
                entry.key: entry.value,
          },
        ),
      );
      return;
    }
    final page = controller.currentPage;
    final bound = block.copyWith(
      content: {...block.content, CalendarStudioBindings.key: binding.name},
    );
    host.update(
      CalendarStudioBindings.apply(
        bound,
        language: controller.project!.source.language,
        year: page.year,
        month: page.month,
      ),
    );
  }

  Widget _content(BuildContext context) {
    final binding = CalendarStudioBindings.of(block);
    final subtitle = block.content['subtitle'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioTextField(
          key: ValueKey(
            'calendar-studio-text-${block.id}-${host.textFieldRevision}',
          ),
          host: host,
          label: StudioStrings.text,
          maxLines: 5,
          value: block.content['text'] as String? ?? '',
          onChanged: _setText,
        ),
        Wrap(
          spacing: 4,
          children: [
            TextButton.icon(
              key: const ValueKey('studio-edit-on-page'),
              onPressed: () => host.editOnPage(block),
              icon: const Icon(Icons.edit_note),
              label: const Text(StudioStrings.typeOnThePage),
            ),
            if (host.suggestText case final suggest?)
              TextButton.icon(
                key: const ValueKey('calendar-studio-suggest-text'),
                onPressed: () => suggest(block),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text(StudioStrings.suggestText),
              ),
          ],
        ),
        StudioSection(
          title: StudioStrings.shows,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (value, label) in _bindings)
                  ChoiceChip(
                    key: ValueKey('studio-binding-${value?.name ?? 'custom'}'),
                    label: Text(label),
                    selected: binding == value,
                    onSelected: (_) => _bind(value),
                  ),
              ],
            ),
            if (binding != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  StudioStrings.bindingNote,
                  style: TextStyle(
                    color: CalendarStudioTokens.of(context).ink3,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        StudioSection(
          title: StudioStrings.secondLine,
          children: [
            StudioTextField(
              key: ValueKey('studio-subtitle-${block.id}'),
              host: host,
              label: StudioStrings.subtitle,
              hint: StudioStrings.subtitleHint,
              value: subtitle ?? '',
              onChanged: (value) => host.update(
                block.copyWith(
                  content: {
                    for (final entry in block.content.entries)
                      if (entry.key != 'subtitle') entry.key: entry.value,
                    if (value.isNotEmpty) 'subtitle': value,
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _style(BuildContext context) {
    final style = block.style;
    final page = host.pageColors(host.controller.currentPage);
    final family = style['fontFamily'] as String? ?? 'Noto Sans Myanmar';
    final weight = style['fontWeight'] as int? ?? 700;
    final hasSubtitle = block.content['subtitle'] != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSection(
          title: StudioStrings.textStyle,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final preset in CalendarStudioTextStyle.all)
                  ActionChip(
                    key: ValueKey('studio-text-style-${preset.id}'),
                    label: Text(preset.label),
                    onPressed: () => host.update(
                      block.copyWith(
                        style: preset.applyTo(block.style, host.theme),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        StudioSection(
          title: StudioStrings.font,
          children: [
            StudioFontField(
              label: StudioStrings.font,
              value: family,
              onChanged: (value) => host.setStyle(block, 'fontFamily', value),
            ),
            StudioFieldRow(
              label: StudioStrings.weight,
              child: DropdownButton<int>(
                key: const ValueKey('studio-font-weight'),
                value: _weights.any((w) => w.$1 == weight) ? weight : 700,
                underline: const SizedBox(),
                items: [
                  for (final (value, label) in _weights)
                    DropdownMenuItem(value: value, child: Text(label)),
                ],
                onChanged: (value) => host.setStyle(block, 'fontWeight', value),
              ),
            ),
            StudioSwitch(
              label: StudioStrings.italic,
              subtitle: StudioStrings.forLatinText,
              value: style['italic'] == true,
              onChanged: (value) => host.setStyle(block, 'italic', value),
            ),
            StudioStepper(
              label: StudioStrings.size,
              value: (style['fontSize'] as num?)?.toDouble() ?? 20,
              min: 6,
              max: 400,
              onChanged: (value) => host.setStyle(block, 'fontSize', value),
            ),
            StudioStepper(
              label: StudioStrings.lineHeight,
              value: (style['lineHeight'] as num?)?.toDouble() ?? 1.2,
              min: .8,
              max: 3,
              step: .05,
              decimals: 2,
              onChanged: (value) => host.setStyle(block, 'lineHeight', value),
            ),
            StudioStepper(
              label: StudioStrings.letterSpacing,
              value: (style['letterSpacing'] as num?)?.toDouble() ?? 0,
              min: -5,
              max: 30,
              step: .5,
              decimals: 1,
              onChanged: (value) =>
                  host.setStyle(block, 'letterSpacing', value),
            ),
          ],
        ),
        StudioSection(
          title: StudioStrings.alignment,
          children: [
            Row(
              children: [
                StudioSegmented<String>(
                  key: const ValueKey('studio-text-align'),
                  segments: const [
                    ('left', null, Icons.format_align_left),
                    ('center', null, Icons.format_align_center),
                    ('right', null, Icons.format_align_right),
                  ],
                  value: style['align'] as String? ?? 'left',
                  onChanged: (value) => host.setStyle(block, 'align', value),
                ),
                const Spacer(),
                StudioSegmented<String>(
                  segments: const [
                    ('top', null, Icons.vertical_align_top),
                    ('middle', null, Icons.vertical_align_center),
                  ],
                  value: style['vAlign'] == 'top' ? 'top' : 'middle',
                  onChanged: (value) => host.setStyle(
                    block,
                    'vAlign',
                    value == 'top' ? 'top' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
        StudioSection(
          title: StudioStrings.colour,
          children: [
            StudioColorField(
              id: 'text',
              label: StudioStrings.textColour,
              value: style['color'] as int?,
              host: host,
              pageColors: page,
              onChanged: (value) => host.setStyle(block, 'color', value),
            ),
            if (hasSubtitle) ...[
              StudioColorField(
                id: 'subtitle',
                label: StudioStrings.subtitleColour,
                value: style['subtitleColor'] as int?,
                host: host,
                pageColors: page,
                onChanged: (value) =>
                    host.setStyle(block, 'subtitleColor', value),
              ),
              StudioStepper(
                label: StudioStrings.subtitleSize,
                unit: '%',
                value:
                    ((style['subtitleScale'] as num?)?.toDouble() ?? .38) * 100,
                min: 20,
                max: 100,
                step: 2,
                onChanged: (value) =>
                    host.setStyle(block, 'subtitleScale', value / 100),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
