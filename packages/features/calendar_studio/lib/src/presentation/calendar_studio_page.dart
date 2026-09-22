import 'package:flutter/material.dart';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../services/calendar_studio_contracts.dart';
import '../services/calendar_studio_controller.dart';
import '../services/calendar_studio_preflight.dart';
import '../services/calendar_studio_pdf_exporter.dart';
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
                  Text(
                    'Your projects',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: projects.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      childAspectRatio: .72,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (_, index) =>
                        _projectCard(context, projects[index]),
                  ),
                ],
              );
            },
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
                    PopupMenuButton(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await widget.configuration.projects.delete(
                            project.id,
                          );
                          await _load();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
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
                selectedBlockId: controller.selectedBlockId,
                showSafeArea: safeArea,
                onSelect: (block) => controller.select(block?.id),
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
                onPressed: () => controller.addBlock(type),
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
                onPressed: controller.deleteSelected,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const Divider(),
          if (block.type == CalendarStudioBlockType.text)
            TextFormField(
              initialValue: block.content['text'] as String? ?? '',
              decoration: const InputDecoration(labelText: 'Text'),
              onChanged: (value) => controller.updateBlock(
                block.copyWith(content: {...block.content, 'text': value}),
              ),
            ),
          if (block.type == CalendarStudioBlockType.calendarGrid)
            const ListTile(
              title: Text('Dates come from the app calendar'),
              subtitle: Text('Calendar data is locked to preserve accuracy.'),
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
        ],
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
              controller.addBlock(type);
              Navigator.pop(context);
            },
          ),
      ],
    ),
  );
  void _showPageOptions(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (_, setSheet) => SwitchListTile(
        value: safeArea,
        onChanged: (value) {
          setState(() => safeArea = value);
          setSheet(() {});
        },
        title: const Text('Show safe area'),
      ),
    ),
  );

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
  void _showExport(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Export', style: Theme.of(context).textTheme.titleLarge),
          const ListTile(
            title: Text('A4 print'),
            subtitle: Text('PDF · 300 dpi'),
          ),
          const ListTile(
            title: Text('Square social'),
            subtitle: Text('PNG · 144 dpi'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final delivery = widget.configuration.exportDelivery;
              if (delivery != null) {
                final bytes = await CalendarStudioPdfExporter(
                  dataProvider: widget.configuration.calendarData,
                ).export(controller.project!);
                await delivery.deliver(
                  CalendarStudioExportArtifact(
                    name: 'my-calendar.pdf',
                    mimeType: 'application/pdf',
                    bytes: bytes,
                  ),
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export PDF'),
          ),
        ],
      ),
    ),
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
