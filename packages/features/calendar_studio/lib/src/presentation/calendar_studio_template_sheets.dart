import 'package:flutter/material.dart';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../models/calendar_studio_user_template.dart';
import '../services/calendar_studio_contracts.dart';
import '../services/calendar_studio_template_bundle.dart';
import '../templates/calendar_studio_bindings.dart';
import '../templates/calendar_studio_user_templates.dart';
import '../theme/calendar_studio_theme.dart';
import '../widgets/calendar_studio_scene.dart';

/// What the user chose in [CalendarStudioSaveTemplateSheet].
class CalendarStudioSaveTemplateRequest {
  const CalendarStudioSaveTemplateRequest({
    required this.name,
    required this.author,
    required this.pageIndex,
    required this.blocks,
    required this.keepPhotos,
    required this.moods,
  });
  final String name;
  final String author;
  final int pageIndex;

  /// The page's blocks with the chosen titles bound.
  final List<CalendarStudioBlock> blocks;
  final bool keepPhotos;
  final List<String> moods;
}

/// "Save as template": name, which page to use, the titles that update every
/// month, Keep photos and moods, with a live preview of what is saved.
class CalendarStudioSaveTemplateSheet extends StatefulWidget {
  const CalendarStudioSaveTemplateSheet({
    super.key,
    required this.project,
    required this.initialPage,
    this.moodOptions = const [],
    this.dataProvider,
    this.assetStore,
  });

  final CalendarStudioProject project;
  final int initialPage;
  final List<String> moodOptions;
  final CalendarStudioDataProvider? dataProvider;
  final CalendarStudioAssetStore? assetStore;

  @override
  State<CalendarStudioSaveTemplateSheet> createState() =>
      _CalendarStudioSaveTemplateSheetState();
}

class _CalendarStudioSaveTemplateSheetState
    extends State<CalendarStudioSaveTemplateSheet> {
  late final _name = TextEditingController(text: widget.project.name);
  final _author = TextEditingController();
  late var _pageIndex = widget.initialPage.clamp(
    0,
    widget.project.pages.length - 1,
  );
  late var _detected = _detect();

  /// Ids of detected titles the user switched back to fixed text.
  final _fixed = <String>{};
  var _keepPhotos = false;
  final _moods = <String>{};

  CalendarStudioPage get _page => widget.project.pages[_pageIndex];

  List<CalendarStudioBlock> _detect() =>
      CalendarStudioUserTemplates.detectBindings(_page);

  List<CalendarStudioBlock> get _blocks => [
    for (final block in _detected)
      _fixed.contains(block.id) ? CalendarStudioBindings.unbind(block) : block,
  ];

  bool get _hasPhotos => _page.blocks.any(
    (block) => CalendarStudioUserTemplate.assetKeys.any(
      (key) => block.content[key] is String,
    ),
  );

  @override
  void dispose() {
    _name.dispose();
    _author.dispose();
    super.dispose();
  }

  void _choosePage(int index) => setState(() {
    _pageIndex = index;
    _detected = _detect();
    _fixed.clear();
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    final project = widget.project;
    final bound = [
      for (final block in _detected)
        if (CalendarStudioBindings.of(block) case final binding?)
          (block, binding),
    ];
    final preview = _page.copyWith(
      blocks: [
        for (final block in _blocks)
          _keepPhotos
              ? block
              : block.copyWith(
                  content: {
                    for (final entry in block.content.entries)
                      if (!CalendarStudioUserTemplate.assetKeys.contains(
                        entry.key,
                      ))
                        entry.key: entry.value,
                  },
                ),
      ],
    );
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: .7,
          color: tokens.ink3,
        ),
      ),
    );

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save as template',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Start new calendars from this design.',
                        style: TextStyle(color: tokens.ink3),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                SizedBox(
                  height: 220,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: preview.canvas.aspectRatio,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x29000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IgnorePointer(
                          child: CalendarStudioScene(
                            page: preview,
                            source: project.source,
                            dataProvider: widget.dataProvider,
                            assetStore: widget.assetStore,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('calendar-studio-template-name'),
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Template name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _author,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Your name (optional)',
                    helperText: 'Shown as “By …” when you share it.',
                  ),
                ),
                if (project.pages.length > 1) ...[
                  label('Layout from'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 8,
                      children: [
                        for (var i = 0; i < project.pages.length; i++)
                          ChoiceChip(
                            label: Text(project.pages[i].label),
                            selected: _pageIndex == i,
                            onSelected: (_) => _choosePage(i),
                          ),
                      ],
                    ),
                  ),
                ],
                label('Updates every month'),
                if (bound.isEmpty)
                  Text(
                    'No month or year titles on this page. Its text stays as '
                    'typed.',
                    style: TextStyle(color: tokens.ink3),
                  )
                else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (block, binding) in bound)
                        FilterChip(
                          key: ValueKey(
                            'calendar-studio-template-binding-${block.id}',
                          ),
                          label: Text(
                            '${binding.label} · '
                            '${block.content['text'] as String? ?? ''}',
                          ),
                          selected: !_fixed.contains(block.id),
                          onSelected: (on) => setState(
                            () => on
                                ? _fixed.remove(block.id)
                                : _fixed.add(block.id),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Selected titles show each page’s month and year, in the '
                    'calendar’s language.',
                    style: TextStyle(fontSize: 12, color: tokens.ink3),
                  ),
                ],
                if (_hasPhotos) ...[
                  const SizedBox(height: 10),
                  SwitchListTile(
                    key: const ValueKey('calendar-studio-template-photos'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Keep photos'),
                    subtitle: const Text(
                      'Off leaves empty photo frames to fill in.',
                    ),
                    value: _keepPhotos,
                    onChanged: (value) => setState(() => _keepPhotos = value),
                  ),
                ],
                if (widget.moodOptions.isNotEmpty) ...[
                  label('Mood'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final mood in widget.moodOptions)
                        FilterChip(
                          label: Text(mood),
                          selected: _moods.contains(mood),
                          onSelected: (on) => setState(
                            () => on ? _moods.add(mood) : _moods.remove(mood),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('calendar-studio-template-save'),
                    onPressed: _name.text.trim().isEmpty
                        ? null
                        : () => Navigator.pop(
                            context,
                            CalendarStudioSaveTemplateRequest(
                              name: _name.text.trim(),
                              author: _author.text.trim(),
                              pageIndex: _pageIndex,
                              blocks: _blocks,
                              keepPhotos: _keepPhotos,
                              moods: _moods.toList(),
                            ),
                          ),
                    child: const Text('Save template'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Review before importing a `.mmctemplate` file.
class CalendarStudioTemplateImportSummary extends StatelessWidget {
  const CalendarStudioTemplateImportSummary({super.key, required this.file});
  final CalendarStudioTemplateFile file;

  @override
  Widget build(BuildContext context) {
    final template = file.template;
    final tokens = CalendarStudioTokens.of(context);
    final megabytes = (file.sizeInBytes / (1 << 20)).toStringAsFixed(1);
    final preview = template.preview;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: tokens.ink3)),
          const SizedBox(width: 16),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Import template',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: AspectRatio(
                        aspectRatio: template.canvas.aspectRatio,
                        child: preview != null
                            ? Image.memory(preview, fit: BoxFit.contain)
                            : IgnorePointer(
                                child: CalendarStudioScene(
                                  page: CalendarStudioPage(
                                    id: 'preview',
                                    label: 'Preview',
                                    year: template.createdAt.year,
                                    month: template.createdAt.month,
                                    canvas: template.canvas,
                                    blocks: template.blocks,
                                  ),
                                  source: CalendarStudioSource(
                                    year: template.createdAt.year,
                                  ),
                                  resolvedAssets: {
                                    for (final MapEntry(:key, :value)
                                        in file.assets.entries)
                                      key: value.bytes,
                                  },
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (template.author case final author?)
                            Text(
                              'By $author',
                              style: TextStyle(color: tokens.ink3),
                            ),
                          Text(
                            '$megabytes MB',
                            style: TextStyle(color: tokens.ink3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            row(
              'Pages',
              template.monthly ? 'One per month' : 'Whole year on one sheet',
            ),
            row('Size', template.category),
            row('Images', '${file.assets.length} included'),
            row('Saved to', 'My templates'),
            if (file.missingAssetIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.warning.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${file.missingAssetIds.length} '
                  '${file.missingAssetIds.length == 1 ? 'image isn\'t' : 'images aren\'t'} '
                  'in this file. Those frames stay empty.',
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey(
                      'calendar-studio-template-import-confirm',
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Import'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
