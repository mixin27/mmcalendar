import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../services/calendar_studio_contracts.dart';
import '../services/calendar_studio_controller.dart';
import '../services/calendar_studio_export_service.dart';
import '../services/calendar_studio_preflight.dart';
import '../services/calendar_studio_raster_renderer.dart';
import '../templates/calendar_studio_templates.dart';
import '../widgets/calendar_studio_scene.dart';

class CalendarStudioWorkspace extends StatefulWidget {
  const CalendarStudioWorkspace({required this.configuration, super.key});
  final CalendarStudioConfiguration configuration;
  @override
  State<CalendarStudioWorkspace> createState() => _CalendarStudioPageState();
}

enum _View { dashboard, templates, editor, preview }

class _CalendarStudioPageState extends State<CalendarStudioWorkspace> {
  late final CalendarStudioController controller;
  var view = _View.dashboard;
  var projects = <CalendarStudioProject>[];
  var loading = true;
  var source = CalendarStudioSource(year: DateTime.now().year + 1);
  var safeArea = true;
  var snapToGrid = true;
  var projectFilter = 'All';

  @override
  void initState() {
    super.initState();
    controller = CalendarStudioController(widget.configuration)
      ..addListener(_refresh);
    _load();
  }

  Future<void> _load() async {
    projects = await widget.configuration.projects.list();
    if (mounted) setState(() => loading = false);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _open(CalendarStudioProject project) async {
    await controller.open(project);
    setState(() => view = _View.editor);
  }

  Future<void> _create(String template) async {
    await controller.create(template, source);
    await _load();
    setState(() => view = _View.editor);
  }

  List<CalendarStudioProject> get _filteredProjects => projectFilter == 'All'
      ? projects
      : projects
            .where((project) => _projectCategory(project) == projectFilter)
            .toList();

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (view) {
    _View.dashboard => _dashboard(context),
    _View.templates => _templates(context),
    _View.editor => _editor(context),
    _View.preview => _preview(context),
  };

  Widget _dashboard(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.configuration.featureName)),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => setState(() => view = _View.templates),
      icon: const Icon(Icons.add),
      label: const Text('New calendar'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : projects.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 80),
                  const SizedBox(height: 14),
                  Text(
                    'Design your first calendar',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start from a template, add photos and events, then export for print or sharing.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() => view = _View.templates),
                    child: const Text('Browse templates'),
                  ),
                ],
              ),
            ),
          )
        : LayoutBuilder(
            builder: (context, box) {
              final count = box.maxWidth >= 900 ? 4 : 2;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _continueCard(context, projects.first),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in const [
                          'All',
                          'Wall',
                          'Desk',
                          'Social',
                          'Print',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: projectFilter == filter,
                              onSelected: (_) =>
                                  setState(() => projectFilter = filter),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your projects',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredProjects.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      childAspectRatio: .72,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (_, index) =>
                        _projectCard(context, _filteredProjects[index]),
                  ),
                ],
              );
            },
          ),
  );

  Widget _continueCard(
    BuildContext context,
    CalendarStudioProject project,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            height: 84,
            child: CalendarStudioScene(
              page: project.pages.first,
              source: project.source,
              dataProvider: widget.configuration.calendarData,
              assetStore: widget.configuration.assets,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue editing',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  project.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${project.pages.length} pages · ${_projectCategory(project)}',
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => _open(project),
            child: const Text('Resume'),
          ),
        ],
      ),
    ),
  );

  Widget _projectCard(BuildContext context, CalendarStudioProject project) =>
      Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(project),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: CalendarStudioScene(
                      page: project.pages.first,
                      source: project.source,
                      dataProvider: widget.configuration.calendarData,
                      assetStore: widget.configuration.assets,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) => _projectAction(value, project),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Text('Duplicate'),
                        ),
                        PopupMenuItem(value: 'export', child: Text('Export…')),
                        PopupMenuDivider(),
                        PopupMenuItem(value: 'delete', child: Text('Delete…')),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  '${project.pages.length} pages · ${project.templateId}',
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _projectAction(
    String action,
    CalendarStudioProject project,
  ) async {
    switch (action) {
      case 'rename':
        await _renameProject(project);
        return;
      case 'duplicate':
        await _duplicateProject(project);
        return;
      case 'export':
        await _exportProject(project);
        return;
      case 'delete':
        await _deleteProject(project);
        return;
    }
  }

  Future<void> _renameProject(CalendarStudioProject project) async {
    final field = TextEditingController(text: project.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename project'),
        content: TextField(
          controller: field,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Project name'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, field.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    field.dispose();
    if (name == null || name.isEmpty || name == project.name) return;
    await widget.configuration.projects.save(
      project.copyWith(name: name, updatedAt: DateTime.now()),
    );
    await _load();
  }

  Future<void> _duplicateProject(CalendarStudioProject project) async {
    final now = DateTime.now();
    final duplicate = CalendarStudioProject(
      id: now.microsecondsSinceEpoch.toString(),
      name: '${project.name} copy',
      templateId: project.templateId,
      schemaVersion: project.schemaVersion,
      source: project.source,
      pages: project.pages,
      createdAt: now,
      updatedAt: now,
      defaultExportPreset: project.defaultExportPreset,
    );
    await widget.configuration.projects.save(duplicate);
    await _load();
  }

  Future<void> _exportProject(CalendarStudioProject project) async {
    await _runExport(
      project,
      project.defaultExportPreset.copyWith(
        fileName: _safeFileName(project.name),
      ),
      CalendarStudioExportDestination.save,
    );
  }

  Future<void> _deleteProject(CalendarStudioProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete “${project.name}”?'),
        content: Text(
          'This removes the project and its ${project.pages.length} pages from this device. '
          'Images used only by this project are removed too. Files you already exported are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.configuration.projects.delete(project.id);
    final remaining = await widget.configuration.projects.list();
    final usedAssets = <String>{
      for (final item in remaining)
        for (final page in item.pages)
          for (final block in page.blocks)
            if (block.content['assetId'] case final String id) id,
    };
    await widget.configuration.assets?.deleteUnusedAssets(usedAssets);
    await _load();
  }

  String _projectCategory(CalendarStudioProject project) =>
      switch (project.templateId) {
        'jade-wall' => 'Wall',
        'ledger-desk' => 'Desk',
        'square' || 'story' => 'Social',
        _ => 'Print',
      };

  String _safeFileName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    return normalized.isEmpty ? 'calendar' : normalized;
  }

  Widget _templates(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(
        onPressed: () => setState(() => view = _View.dashboard),
      ),
      title: const Text('Choose a template'),
    ),
    body: LayoutBuilder(
      builder: (context, box) {
        final count = box.maxWidth >= 900 ? 4 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: CalendarStudioTemplates.all.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            childAspectRatio: .72,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (_, index) {
            final template = CalendarStudioTemplates.all[index];
            return Card(
              child: InkWell(
                onTap: () => _showSetup(context, template),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        margin: const EdgeInsets.all(8),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: template.canvas.aspectRatio,
                            child: const ColoredBox(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
                      child: Text(
                        template.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: Text(template.category),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );

  void _showSetup(BuildContext context, CalendarStudioTemplate template) {
    var draft = source;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set up ${template.name}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(template.category),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<CalendarStudioPeriod>(
                  segments: const [
                    ButtonSegment(
                      value: CalendarStudioPeriod.month,
                      label: Text('Month'),
                    ),
                    ButtonSegment(
                      value: CalendarStudioPeriod.year,
                      label: Text('Year'),
                    ),
                  ],
                  selected: {draft.period},
                  onSelectionChanged: (value) => setSheet(
                    () => draft = draft.copyWith(period: value.first),
                  ),
                ),
                DropdownButtonFormField<int>(
                  initialValue: draft.year,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items: List.generate(
                    5,
                    (i) => DropdownMenuItem(
                      value: DateTime.now().year + i,
                      child: Text('${DateTime.now().year + i}'),
                    ),
                  ),
                  onChanged: (value) =>
                      setSheet(() => draft = draft.copyWith(year: value)),
                ),
                SwitchListTile(
                  value: draft.showMyanmarDate,
                  onChanged: (value) => setSheet(
                    () => draft = draft.copyWith(showMyanmarDate: value),
                  ),
                  title: const Text('Myanmar date'),
                ),
                SwitchListTile(
                  value: draft.showHolidays,
                  onChanged: (value) => setSheet(
                    () => draft = draft.copyWith(showHolidays: value),
                  ),
                  title: const Text('Holidays'),
                ),
                SwitchListTile(
                  value: draft.weekStartsMonday,
                  onChanged: (value) => setSheet(
                    () => draft = draft.copyWith(weekStartsMonday: value),
                  ),
                  title: const Text('Week starts on Monday'),
                ),
                FilledButton(
                  onPressed: () {
                    source = draft;
                    Navigator.pop(sheetContext);
                    _create(template.id);
                  },
                  child: const Text('Create project'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _editor(BuildContext context) {
    final project = controller.project!;
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 900;
        final canvas = _canvas(context, project);
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () {
                controller.saveNow();
                setState(() => view = _View.dashboard);
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, style: const TextStyle(fontSize: 16)),
                Text(
                  controller.saveState.name,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: controller.canUndo ? controller.undo : null,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                onPressed: controller.canRedo ? controller.redo : null,
                icon: const Icon(Icons.redo),
              ),
              FilledButton(
                onPressed: () => setState(() => view = _View.preview),
                child: const Text('Export'),
              ),
            ],
          ),
          body: wide
              ? Row(
                  children: [
                    SizedBox(width: 260, child: _layers()),
                    Expanded(child: canvas),
                    SizedBox(width: 320, child: _inspector()),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: canvas),
                    _tools(),
                    if (controller.selectedBlockId != null)
                      SizedBox(height: 240, child: _inspector()),
                  ],
                ),
        );
      },
    );
  }

  Widget _canvas(
    BuildContext context,
    CalendarStudioProject project,
  ) => Container(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: controller.pageIndex > 0
                  ? () => controller.setPage(controller.pageIndex - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${controller.currentPage.label} · ${controller.pageIndex + 1}/${project.pages.length}',
            ),
            IconButton(
              onPressed: controller.pageIndex < project.pages.length - 1
                  ? () => controller.setPage(controller.pageIndex + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: CalendarStudioScene(
                page: controller.currentPage,
                source: project.source,
                dataProvider: widget.configuration.calendarData,
                assetStore: widget.configuration.assets,
                selectedBlockId: controller.selectedBlockId,
                showSafeArea: safeArea,
                onSelect: (block) => controller.select(block?.id),
                onTransform: _updateBlockTransform,
                onTransformStart: controller.beginBlockInteraction,
                onTransformEnd: controller.endBlockInteraction,
              ),
            ),
          ),
        ),
      ],
    ),
  );
  Widget _tools() => Material(
    child: SizedBox(
      height: 62,
      child: Row(
        children: [
          for (final type in [
            CalendarStudioBlockType.text,
            CalendarStudioBlockType.image,
            CalendarStudioBlockType.calendarGrid,
            CalendarStudioBlockType.shape,
          ])
            Expanded(
              child: IconButton(
                onPressed: () => type == CalendarStudioBlockType.image
                    ? _pickAsset(type)
                    : controller.addBlock(type),
                icon: Icon(_icon(type)),
                tooltip: 'Add ${type.name}',
              ),
            ),
          IconButton(
            onPressed: () => _showLayers(context),
            icon: const Icon(Icons.layers_outlined),
          ),
          IconButton(
            onPressed: () => _showPageOptions(context),
            icon: const Icon(Icons.tune_outlined),
          ),
        ],
      ),
    ),
  );
  Widget _layers() {
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Layers',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final block in controller.currentPage.blocks.reversed)
                  ListTile(
                    selected: controller.selectedBlockId == block.id,
                    leading: Icon(_icon(block.type)),
                    title: Text(block.name),
                    subtitle: Text(
                      block.locked ? 'Locked to app data' : block.type.name,
                    ),
                    onTap: () => controller.select(block.id),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: FilledButton.icon(
              onPressed: () => _showAdd(context),
              icon: const Icon(Icons.add),
              label: const Text('Add to page'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inspector() {
    final matches = controller.currentPage.blocks.where(
      (block) => block.id == controller.selectedBlockId,
    );
    if (matches.isEmpty) {
      return const Material(
        child: Center(child: Text('Select a block to edit')),
      );
    }
    final block = matches.first;
    return Material(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(_icon(block.type)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  block.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: controller.duplicateSelected,
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Duplicate',
              ),
              IconButton(
                onPressed: controller.deleteSelected,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const Divider(),
          if (block.type == CalendarStudioBlockType.text) _textInspector(block),
          if (block.type == CalendarStudioBlockType.calendarGrid)
            _calendarGridInspector(),
          if (block.type == CalendarStudioBlockType.image ||
              block.type == CalendarStudioBlockType.logo)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(block.content['assetName'] as String? ?? 'Image'),
              subtitle: Text(
                '${block.content['pixelWidth'] ?? 0} × ${block.content['pixelHeight'] ?? 0} px',
              ),
              trailing: OutlinedButton(
                onPressed: () => _pickAsset(block.type, replace: block),
                child: const Text('Replace'),
              ),
            ),
          SwitchListTile(
            value: block.locked,
            onChanged: (value) =>
                controller.updateBlock(block.copyWith(locked: value)),
            title: const Text('Lock layer'),
          ),
          SwitchListTile(
            value: block.visible,
            onChanged: (value) =>
                controller.updateBlock(block.copyWith(visible: value)),
            title: const Text('Visible'),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => controller.moveSelectedLayer(-1),
                  icon: const Icon(Icons.flip_to_back_outlined),
                  label: const Text('Back'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => controller.moveSelectedLayer(1),
                  icon: const Icon(Icons.flip_to_front_outlined),
                  label: const Text('Forward'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textInspector(CalendarStudioBlock block) {
    final size = (block.style['fontSize'] as num?)?.toDouble() ?? 20;
    final alignment = block.style['align'] as String? ?? 'left';
    const colors = [0xFF0E6B5C, 0xFF15201D, 0xFFB8322A, 0xFFB98A25, 0xFFFFFFFF];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: block.content['text'] as String? ?? '',
          decoration: const InputDecoration(labelText: 'Text'),
          onChanged: (value) => controller.updateBlock(
            block.copyWith(content: {...block.content, 'text': value}),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Font · ${block.style['fontFamily'] as String? ?? 'Noto Sans Myanmar'}',
        ),
        Text(
          'ကခ Aa · Myanmar supported',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        Row(
          children: [
            const Text('Size'),
            Expanded(
              child: Slider(
                value: size.clamp(10, 96),
                min: 10,
                max: 96,
                divisions: 86,
                label: size.round().toString(),
                onChanged: (value) => controller.updateBlock(
                  block.copyWith(style: {...block.style, 'fontSize': value}),
                ),
              ),
            ),
            Text('${size.round()}'),
          ],
        ),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'left', icon: Icon(Icons.format_align_left)),
            ButtonSegment(
              value: 'center',
              icon: Icon(Icons.format_align_center),
            ),
            ButtonSegment(value: 'right', icon: Icon(Icons.format_align_right)),
          ],
          selected: {alignment},
          onSelectionChanged: (value) => controller.updateBlock(
            block.copyWith(style: {...block.style, 'align': value.first}),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Colour'),
        Wrap(
          spacing: 10,
          children: [
            for (final color in colors)
              InkWell(
                onTap: () => controller.updateBlock(
                  block.copyWith(style: {...block.style, 'color': color}),
                ),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: block.style['color'] == color
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      width: block.style['color'] == color ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _calendarGridInspector() {
    final current = controller.project!.source;
    return Column(
      children: [
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Dates come from the app calendar'),
          subtitle: Text('Canonical calendar data cannot be edited.'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: current.showMyanmarDate,
          onChanged: (value) =>
              controller.updateSource(current.copyWith(showMyanmarDate: value)),
          title: const Text('Myanmar date'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: current.showMoonPhases,
          onChanged: (value) =>
              controller.updateSource(current.copyWith(showMoonPhases: value)),
          title: const Text('Moon phases'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: current.showHolidays,
          onChanged: (value) =>
              controller.updateSource(current.copyWith(showHolidays: value)),
          title: const Text('Public holidays'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: current.showAstrology,
          onChanged: (value) =>
              controller.updateSource(current.copyWith(showAstrology: value)),
          title: const Text('Astrology days'),
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Sun start')),
            ButtonSegment(value: true, label: Text('Mon start')),
          ],
          selected: {current.weekStartsMonday},
          onSelectionChanged: (value) => controller.updateSource(
            current.copyWith(weekStartsMonday: value.first),
          ),
        ),
      ],
    );
  }

  void _updateBlockTransform(CalendarStudioBlock block) {
    if (!snapToGrid) {
      controller.updateBlockDuringInteraction(block);
      return;
    }
    double snap(double value) => (value * 100).round() / 100;
    controller.updateBlockDuringInteraction(
      block.copyWith(
        bounds: block.bounds.copyWith(
          left: snap(block.bounds.left),
          top: snap(block.bounds.top),
          width: snap(block.bounds.width),
          height: snap(block.bounds.height),
        ),
      ),
    );
  }

  void _showLayers(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (_) => SizedBox(height: 480, child: _layers()),
  );
  void _showAdd(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (_) => GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(20),
      children: [
        for (final type in CalendarStudioBlockType.values)
          ListTile(
            leading: Icon(_icon(type)),
            title: Text(type.name),
            onTap: () {
              Navigator.pop(context);
              if (type == CalendarStudioBlockType.image ||
                  type == CalendarStudioBlockType.logo) {
                _pickAsset(type);
              } else {
                controller.addBlock(type);
              }
            },
          ),
      ],
    ),
  );
  void _showPageOptions(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => StatefulBuilder(
      builder: (_, setSheet) {
        final canvas = controller.currentPage.canvas;
        const backgrounds = [
          0xFFFFFFFF,
          0xFFF3EBD8,
          0xFFE4F2EE,
          0xFF151B3F,
          0xFFF4F7F5,
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Page and theme',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                ),
                Text(
                  'Page size · ${canvas.width.round()} × ${canvas.height.round()}',
                ),
                const SizedBox(height: 14),
                const Text('Page background'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    for (final color in backgrounds)
                      InkWell(
                        onTap: () {
                          controller.updateCurrentCanvas(
                            canvas.copyWith(backgroundColor: color),
                          );
                          setSheet(() {});
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: canvas.backgroundColor == color
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                              width: canvas.backgroundColor == color ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: safeArea,
                  onChanged: (value) {
                    setState(() => safeArea = value);
                    setSheet(() {});
                  },
                  title: const Text('Show safe area'),
                  subtitle: const Text(
                    'Keep important content inside the guide',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: canvas.bleed > 0,
                  onChanged: (value) {
                    controller.updateCurrentCanvas(
                      canvas.copyWith(bleed: value ? 3 : 0),
                    );
                    setSheet(() {});
                  },
                  title: const Text('Show bleed'),
                  subtitle: const Text('3 mm extra edge for print'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: snapToGrid,
                  onChanged: (value) {
                    setState(() => snapToGrid = value);
                    setSheet(() {});
                  },
                  title: const Text('Snap to grid'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Future<void> _pickAsset(
    CalendarStudioBlockType type, {
    CalendarStudioBlock? replace,
  }) async {
    final store = widget.configuration.assets;
    if (store == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image storage is not configured.')),
        );
      }
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    final decoded = image_lib.decodeImage(bytes);
    final asset = await store.importAsset(
      CalendarStudioAssetInput(
        name: file.name,
        bytes: bytes,
        width: decoded?.width ?? 0,
        height: decoded?.height ?? 0,
      ),
    );
    final id = replace?.id ?? controller.addBlock(type);
    final block = controller.currentPage.blocks.firstWhere(
      (value) => value.id == id,
    );
    controller.updateBlock(
      block.copyWith(
        content: {
          ...block.content,
          'assetId': asset.id,
          'assetName': asset.name,
          'pixelWidth': asset.width,
          'pixelHeight': asset.height,
        },
      ),
    );
  }

  Widget _preview(BuildContext context) {
    final project = controller.project!;
    final issues = CalendarStudioPreflight.check(project);
    final errors = issues
        .where((issue) => issue.severity == CalendarStudioIssueSeverity.error)
        .length;
    final preview = Column(
      children: [
        FilterChip(
          label: const Text('Safe area'),
          selected: safeArea,
          onSelected: (value) => setState(() => safeArea = value),
        ),
        Expanded(
          child: PageView.builder(
            itemCount: project.pages.length,
            onPageChanged: controller.setPage,
            itemBuilder: (_, index) => Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: CalendarStudioScene(
                  page: project.pages[index],
                  source: project.source,
                  dataProvider: widget.configuration.calendarData,
                  assetStore: widget.configuration.assets,
                  showSafeArea: safeArea,
                ),
              ),
            ),
          ),
        ),
        Text(
          '${controller.currentPage.label} · Page ${controller.pageIndex + 1} of ${project.pages.length}',
        ),
      ],
    );
    final flight = _preflight(issues, errors);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => setState(() => view = _View.editor),
        ),
        title: const Text('Preview'),
        actions: [
          FilledButton(
            onPressed: errors > 0 ? null : () => _showExport(context),
            child: const Text('Export…'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) => box.maxWidth >= 900
            ? Row(
                children: [
                  Expanded(child: preview),
                  SizedBox(width: 340, child: flight),
                ],
              )
            : Column(
                children: [
                  Expanded(child: preview),
                  SizedBox(height: 220, child: flight),
                ],
              ),
      ),
    );
  }

  Widget _preflight(List<CalendarStudioIssue> issues, int errors) => Material(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Preflight check',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(
          '$errors errors · ${issues.where((issue) => issue.severity == CalendarStudioIssueSeverity.warning).length} warnings',
        ),
        for (final issue in issues)
          ListTile(
            leading: Icon(
              issue.severity == CalendarStudioIssueSeverity.error
                  ? Icons.error_outline
                  : Icons.warning_amber_outlined,
            ),
            title: Text(issue.title),
            subtitle: Text(issue.detail),
            trailing: issue.blockId == null
                ? null
                : TextButton(
                    onPressed: () {
                      controller.setPage(
                        controller.project!.pages.indexWhere(
                          (page) => page.id == issue.pageId,
                        ),
                      );
                      controller.select(issue.blockId);
                      setState(() => view = _View.editor);
                    },
                    child: const Text('Fix'),
                  ),
          ),
        const Text(
          'Warnings never block export. Errors do.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
  Future<void> _showExport(BuildContext context) async {
    final project = controller.project!;
    final request = await showModalBottomSheet<_ExportRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExportSheet(
        initialPreset: project.defaultExportPreset.copyWith(
          fileName: _safeFileName(project.name),
        ),
        pageCount: project.pages.length,
      ),
    );
    if (request != null && mounted) {
      await _runExport(project, request.preset, request.destination);
    }
  }

  Future<void> _runExport(
    CalendarStudioProject project,
    CalendarStudioExportPreset preset,
    CalendarStudioExportDestination destination,
  ) async {
    final delivery = widget.configuration.exportDelivery;
    if (delivery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No export destination is configured.')),
      );
      return;
    }
    final token = CalendarStudioExportCancellationToken();
    final progress = ValueNotifier(
      CalendarStudioExportProgress(completed: 0, total: project.pages.length),
    );
    var dialogOpen = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _ExportProgressDialog(
          format: preset.format,
          progress: progress,
          onCancel: token.cancel,
        ),
      ).whenComplete(() => dialogOpen = false),
    );
    try {
      final artifact =
          await CalendarStudioExportService(
            renderer: CalendarStudioRasterRenderer(
              dataProvider: widget.configuration.calendarData,
              assetStore: widget.configuration.assets,
            ),
          ).export(
            project: project,
            preset: preset,
            cancellationToken: token,
            onProgress: (value) => progress.value = value,
          );
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      await delivery.deliver(artifact, destination: destination);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${artifact.name} is ready.')));
      }
    } on CalendarStudioExportCancelled {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (error) {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
      }
    } finally {
      progress.dispose();
    }
  }
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.initialPreset, required this.pageCount});
  final CalendarStudioExportPreset initialPreset;
  final int pageCount;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  late CalendarStudioExportPreset preset = widget.initialPreset;
  var destination = CalendarStudioExportDestination.save;
  late final TextEditingController nameController = TextEditingController(
    text: widget.initialPreset.fileName,
  );

  static const presets = [
    CalendarStudioExportPreset.screenPng,
    CalendarStudioExportPreset.a4Pdf,
    CalendarStudioExportPreset.highQualityPng,
    CalendarStudioExportPreset.a3Pdf,
    CalendarStudioExportPreset.squarePng,
    CalendarStudioExportPreset.storyPng,
  ];

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extension = switch (preset.format) {
      CalendarStudioExportFormat.pdf => '.pdf',
      CalendarStudioExportFormat.png => widget.pageCount > 1 ? '.zip' : '.png',
      CalendarStudioExportFormat.jpeg => widget.pageCount > 1 ? '.zip' : '.jpg',
      CalendarStudioExportFormat.zip => '.zip',
    };
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Export',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text('Preset'),
              const SizedBox(height: 8),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: presets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final value = presets[index];
                    return ChoiceChip(
                      selected: preset.id == value.id,
                      onSelected: (_) => setState(
                        () => preset = value.copyWith(
                          fileName: nameController.text,
                        ),
                      ),
                      label: SizedBox(
                        width: 112,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(value.label),
                            Text(
                              '${value.width} × ${value.height}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text('Format'),
              const SizedBox(height: 6),
              SegmentedButton<CalendarStudioExportFormat>(
                segments: const [
                  ButtonSegment(
                    value: CalendarStudioExportFormat.pdf,
                    label: Text('PDF'),
                  ),
                  ButtonSegment(
                    value: CalendarStudioExportFormat.png,
                    label: Text('PNG'),
                  ),
                  ButtonSegment(
                    value: CalendarStudioExportFormat.jpeg,
                    label: Text('JPEG'),
                  ),
                  ButtonSegment(
                    value: CalendarStudioExportFormat.zip,
                    label: Text('ZIP'),
                  ),
                ],
                selected: {preset.format},
                onSelectionChanged: (values) => setState(
                  () => preset = preset.copyWith(format: values.first),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'File name',
                  suffixText: extension,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${preset.width} × ${preset.height} px · ${preset.dpi} dpi · '
                '${widget.pageCount} page${widget.pageCount == 1 ? '' : 's'}\n'
                'Myanmar text is shaped by Flutter for reliable PDF output.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              const Text('After exporting'),
              const SizedBox(height: 6),
              SegmentedButton<CalendarStudioExportDestination>(
                segments: const [
                  ButtonSegment(
                    value: CalendarStudioExportDestination.save,
                    icon: Icon(Icons.save_alt_outlined),
                    label: Text('Save'),
                  ),
                  ButtonSegment(
                    value: CalendarStudioExportDestination.share,
                    icon: Icon(Icons.share_outlined),
                    label: Text('Share'),
                  ),
                  ButtonSegment(
                    value: CalendarStudioExportDestination.print,
                    icon: Icon(Icons.print_outlined),
                    label: Text('Print'),
                  ),
                ],
                selected: {destination},
                onSelectionChanged: (values) => setState(() {
                  destination = values.first;
                  if (destination == CalendarStudioExportDestination.print) {
                    preset = preset.copyWith(
                      format: CalendarStudioExportFormat.pdf,
                    );
                  }
                }),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(
                  context,
                  _ExportRequest(
                    preset: preset.copyWith(fileName: nameController.text),
                    destination: destination,
                  ),
                ),
                icon: const Icon(Icons.download_outlined),
                label: Text('Export ${preset.format.name.toUpperCase()}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportRequest {
  const _ExportRequest({required this.preset, required this.destination});
  final CalendarStudioExportPreset preset;
  final CalendarStudioExportDestination destination;
}

class _ExportProgressDialog extends StatelessWidget {
  const _ExportProgressDialog({
    required this.format,
    required this.progress,
    required this.onCancel,
  });
  final CalendarStudioExportFormat format;
  final ValueListenable<CalendarStudioExportProgress> progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Exporting ${format.name.toUpperCase()}'),
    content: ValueListenableBuilder<CalendarStudioExportProgress>(
      valueListenable: progress,
      builder: (_, value, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rendering page ${value.completed >= value.total ? value.total : value.completed + 1} '
            'of ${value.total}',
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: value.total == 0 ? 0 : value.completed / value.total,
          ),
          const SizedBox(height: 12),
          const Text(
            'Pages are rendered one at a time so long calendars remain responsive.',
          ),
        ],
      ),
    ),
    actions: [OutlinedButton(onPressed: onCancel, child: const Text('Cancel'))],
  );
}

IconData _icon(CalendarStudioBlockType type) => switch (type) {
  CalendarStudioBlockType.text => Icons.text_fields,
  CalendarStudioBlockType.image ||
  CalendarStudioBlockType.logo => Icons.image_outlined,
  CalendarStudioBlockType.calendarGrid => Icons.calendar_month_outlined,
  CalendarStudioBlockType.eventList => Icons.event_outlined,
  CalendarStudioBlockType.holidayLegend => Icons.local_offer_outlined,
  _ => Icons.interests_outlined,
};
