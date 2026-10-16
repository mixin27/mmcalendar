import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../services/calendar_studio_cache.dart';
import '../services/calendar_studio_contracts.dart';
import '../services/calendar_studio_controller.dart';
import '../services/calendar_studio_export_service.dart';
import '../services/calendar_studio_image_import.dart';
import '../services/calendar_studio_preflight.dart';
import '../services/calendar_studio_project_bundle.dart';
import '../services/calendar_studio_transform.dart';
import '../services/calendar_studio_raster_renderer.dart';
import '../templates/calendar_studio_templates.dart';
import '../theme/calendar_studio_theme.dart';
import '../widgets/calendar_studio_scene.dart';
import 'calendar_studio_export_flow.dart';

class CalendarStudioWorkspace extends StatefulWidget {
  const CalendarStudioWorkspace({required this.configuration, super.key});
  final CalendarStudioConfiguration configuration;
  @override
  State<CalendarStudioWorkspace> createState() => _CalendarStudioPageState();
}

enum _View { dashboard, templates, editor, preview }

class _CalendarStudioPageState extends State<CalendarStudioWorkspace> {
  static const _minCanvasZoom = .5;
  static const _maxCanvasZoom = 4.0;
  late final CalendarStudioController controller;
  late final TransformationController canvasController;
  late final CalendarStudioDataProvider? _calendarData =
      switch (widget.configuration.calendarData) {
        final provider? => CachedCalendarStudioDataProvider(provider),
        null => null,
      };
  late final CalendarStudioAssetStore? _assets =
      switch (widget.configuration.assets) {
        final store? => CachedCalendarStudioAssetStore(store),
        null => null,
      };
  final _guides = ValueNotifier<List<StudioGuide>>(const []);
  late final Listenable _canvasListenable = Listenable.merge([
    controller.canvasChanges,
    _guides,
  ]);
  double? _lastSnappedRotation;
  final _editorFocus = FocusNode(debugLabel: 'Calendar Studio editor');
  var _spacePanning = false;
  var _canRemoveBackground = false;
  var _canSuggestText = false;
  var _textFieldRevision = 0;
  PageController? _previewPages;
  ThemeData? _theme;
  CalendarStudioTokens? _themeTokens;
  Brightness? _themeBrightness;
  final _templatePreviews =
      <(String, CalendarStudioSource), CalendarStudioProject>{};
  var view = _View.dashboard;
  var projects = <CalendarStudioProject>[];
  var loading = true;
  var source = CalendarStudioSource(year: DateTime.now().year + 1);
  var safeArea = true;
  var showBleed = false;
  var showPreviewGrid = false;
  var snapToGrid = true;
  var projectFilter = 'All';
  var canvasZoom = 1.0;
  var calendarInspectorTab = 0;
  var _inspectorVisible = false;
  var _canvasPointerCount = 0;
  var _canvasPinching = false;

  @override
  void initState() {
    super.initState();
    controller = CalendarStudioController(widget.configuration)
      ..addListener(_refresh);
    canvasController = TransformationController()
      ..addListener(_onCanvasTransformChanged);
    _load();
    _resolveAi();
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
    await _warmCalendar(project);
    setState(() => view = _View.editor);
  }

  Future<void> _create(String template) async {
    final project = await controller.create(template, source);
    await _warmCalendar(project);
    await _load();
    setState(() => view = _View.editor);
  }

  /// Resolves every month the project shows before the editor paints, so
  /// grids render synchronously from the cache instead of flickering.
  Future<void> _warmCalendar(CalendarStudioProject project) async {
    final provider = _calendarData;
    if (provider is! CachedCalendarStudioDataProvider) return;
    final requests = <(CalendarStudioSource, int)>{
      for (final page in project.pages)
        for (final block in page.blocks)
          if (block.type == CalendarStudioBlockType.calendarGrid)
            (
              project.source.copyWith(
                year: page.year,
                month: block.content['month'] as int? ?? page.month,
              ),
              block.content['month'] as int? ?? page.month,
            ),
    };
    try {
      await Future.wait([
        for (final (source, month) in requests)
          provider.daysFor(source, month: month),
      ]);
    } catch (_) {
      // Grids fall back to loading on demand.
    }
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
    _guides.dispose();
    _editorFocus.dispose();
    _previewPages?.dispose();
    canvasController
      ..removeListener(_onCanvasTransformChanged)
      ..dispose();
    super.dispose();
  }

  void _onCanvasTransformChanged() {
    final zoom = canvasController.value.getMaxScaleOnAxis();
    if (!mounted || (zoom - canvasZoom).abs() < .01) return;
    setState(() => canvasZoom = zoom);
  }

  void _setCanvasZoom(double value) {
    final zoom = value.clamp(_minCanvasZoom, _maxCanvasZoom).toDouble();
    canvasController.value = Matrix4.diagonal3Values(zoom, zoom, 1);
  }

  void _fitCanvas() => _setCanvasZoom(1);

  void _canvasPointerDown(PointerDownEvent event) {
    _canvasPointerCount++;
    if (_canvasPointerCount < 2) return;
    _canvasPinching = true;
    controller.cancelBlockInteraction();
    _guides.value = const [];
  }

  void _canvasPointerFinished(PointerEvent event) {
    _canvasPointerCount = (_canvasPointerCount - 1).clamp(0, 10);
    if (_canvasPointerCount == 0) _canvasPinching = false;
  }

  void _changePage(int index) {
    controller.setPage(index);
    _inspectorVisible = false;
    _fitCanvas();
  }

  void _selectBlock(CalendarStudioBlock? block) {
    controller.select(block?.id);
    // Canvas taps take keyboard focus back from inspector fields.
    if (!_editorFocus.hasPrimaryFocus) _editorFocus.requestFocus();
    if (block == null && _inspectorVisible) {
      setState(() => _inspectorVisible = false);
    }
  }

  void _openInspector({int? tab}) {
    setState(() {
      if (tab != null) calendarInspectorTab = tab;
      _inspectorVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = switch (widget.configuration.appearance) {
      CalendarStudioAppearance.light => Brightness.light,
      CalendarStudioAppearance.dark => Brightness.dark,
      CalendarStudioAppearance.system => MediaQuery.platformBrightnessOf(
        context,
      ),
    };
    final tokens = brightness == Brightness.dark
        ? widget.configuration.darkTokens
        : widget.configuration.lightTokens;
    if (_theme == null ||
        _themeTokens != tokens ||
        _themeBrightness != brightness) {
      _themeTokens = tokens;
      _themeBrightness = brightness;
      _theme = CalendarStudioTheme.fromTokens(tokens, brightness: brightness);
    }
    return Theme(
      data: _theme!,
      child: Builder(
        builder: (studioContext) => _buildWorkspace(studioContext),
      ),
    );
  }

  Widget _buildWorkspace(BuildContext context) => PopScope(
    canPop: view == _View.dashboard,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      if (view == _View.editor || view == _View.preview) {
        await controller.saveNow();
        await _load();
      }
      if (!mounted) return;
      setState(
        () => view = view == _View.preview ? _View.editor : _View.dashboard,
      );
    },
    child: switch (view) {
      _View.dashboard => _dashboard(context),
      _View.templates => _templates(context),
      _View.editor => Focus(
        focusNode: _editorFocus,
        autofocus: true,
        onKeyEvent: _handleEditorKey,
        child: _editor(context),
      ),
      _View.preview => _preview(context),
    },
  );

  Widget _dashboard(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.configuration.featureName),
      actions: [
        IconButton(
          tooltip: 'Import project',
          onPressed: _importProject,
          icon: const Icon(Icons.file_open_outlined),
        ),
      ],
    ),
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
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _importProject,
                    child: const Text('Import a project file'),
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
              dataProvider: _calendarData,
              assetStore: _assets,
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
                      dataProvider: _calendarData,
                      assetStore: _assets,
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
                        PopupMenuItem(
                          value: 'save-file',
                          child: Text('Save project file'),
                        ),
                        PopupMenuItem(
                          value: 'share-file',
                          child: Text('Share project file'),
                        ),
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
      case 'save-file':
        await _exportProjectFile(project, CalendarStudioExportDestination.save);
        return;
      case 'share-file':
        await _exportProjectFile(
          project,
          CalendarStudioExportDestination.share,
        );
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

  Future<void> _exportProjectFile(
    CalendarStudioProject project,
    CalendarStudioExportDestination destination,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final delivery = widget.configuration.exportDelivery;
    if (delivery == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No export destination is configured.')),
      );
      return;
    }
    try {
      final artifact = await CalendarStudioProjectBundle.export(
        project,
        assets: _assets,
        fileName: _safeFileName(project.name),
      );
      await delivery.deliver(artifact, destination: destination);
      messenger.showSnackBar(
        SnackBar(content: Text('${artifact.name} is ready.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't create the project file.")),
      );
    }
  }

  Future<void> _importProject() async {
    final messenger = ScaffoldMessenger.of(context);
    final pick =
        widget.configuration.pickProjectFile ??
        CalendarStudioProjectBundle.pickFile;
    final CalendarStudioProjectFile file;
    try {
      final bytes = await pick();
      if (bytes == null) return;
      file = await CalendarStudioProjectBundle.read(bytes);
    } on CalendarStudioProjectFileException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      return;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't open that file.")),
      );
      return;
    }
    if (!mounted) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _sheetHeight,
      ),
      builder: (_) => _ImportSummary(file: file),
    );
    if (confirmed != true || !mounted) return;
    try {
      final project = await CalendarStudioProjectBundle.import(
        file,
        projects: widget.configuration.projects,
        assets: _assets,
        now: widget.configuration.now?.call(),
      );
      await _load();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Imported "${project.name}".'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => _open(project),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't import the project.")),
      );
    }
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
            for (final key in const [
              'assetId',
              'originalAssetId',
              'editBaseAssetId',
            ])
              if (block.content[key] case final String id) id,
    };
    await _assets?.deleteUnusedAssets(usedAssets);
    await _load();
  }

  /// Dashboard filter for a project, from its template's category label
  /// ("Wall · A4 portrait", "Story · 9:16", …).
  String _projectCategory(CalendarStudioProject project) =>
      switch (CalendarStudioTemplates.byId(
        project.templateId,
      ).category.split(' ').first) {
        'Wall' => 'Wall',
        'Desk' => 'Desk',
        'Social' || 'Story' => 'Social',
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
                            child: _templatePreview(template),
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

  Widget _templatePreview(CalendarStudioTemplate template) {
    final previewSource = source.copyWith(period: CalendarStudioPeriod.month);
    final preview = _templatePreviews.putIfAbsent(
      (template.id, previewSource),
      () => template.create(
        id: 'preview-${template.id}',
        source: previewSource,
        now: DateTime(previewSource.year),
      ),
    );
    return IgnorePointer(
      child: CalendarStudioScene(
        page: preview.pages.first,
        source: preview.source,
        dataProvider: _calendarData,
        assetStore: _assets,
      ),
    );
  }

  void _showSetup(BuildContext context, CalendarStudioTemplate template) {
    var draft = source;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .9,
        child: StatefulBuilder(
          builder: (_, setSheet) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 52,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: CalendarStudioTokens.of(sheetContext).surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _templatePreview(template),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set up ${template.name}',
                            style: Theme.of(sheetContext).textTheme.titleLarge,
                          ),
                          Text(
                            template.category,
                            style: Theme.of(sheetContext).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionLabel('Period'),
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: draft.year,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                              ),
                              items: List.generate(
                                7,
                                (index) => DropdownMenuItem(
                                  value: source.year - 2 + index,
                                  child: Text('${source.year - 2 + index}'),
                                ),
                              ),
                              onChanged: (value) => setSheet(
                                () => draft = draft.copyWith(year: value),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: draft.month,
                              decoration: const InputDecoration(
                                labelText: 'From',
                              ),
                              items: List.generate(
                                12,
                                (index) => DropdownMenuItem(
                                  value: index + 1,
                                  child: Text(_monthName(index + 1)),
                                ),
                              ),
                              onChanged: (value) => setSheet(
                                () => draft = draft.copyWith(month: value),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionLabel('Language on the calendar'),
                      SegmentedButton<CalendarStudioLanguage>(
                        segments: const [
                          ButtonSegment(
                            value: CalendarStudioLanguage.myanmar,
                            label: Text('မြန်မာ'),
                          ),
                          ButtonSegment(
                            value: CalendarStudioLanguage.english,
                            label: Text('English'),
                          ),
                          ButtonSegment(
                            value: CalendarStudioLanguage.both,
                            label: Text('Both'),
                          ),
                        ],
                        selected: {draft.language},
                        onSelectionChanged: (value) => setSheet(
                          () => draft = draft.copyWith(language: value.first),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionLabel('Show on each day'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _setupChip(
                            'Myanmar date',
                            draft.showMyanmarDate,
                            (value) => setSheet(
                              () => draft = draft.copyWith(
                                showMyanmarDate: value,
                              ),
                            ),
                          ),
                          _setupChip(
                            'Moon phases',
                            draft.showMoonPhases,
                            (value) => setSheet(
                              () =>
                                  draft = draft.copyWith(showMoonPhases: value),
                            ),
                          ),
                          _setupChip(
                            'Holidays',
                            draft.showHolidays,
                            (value) => setSheet(
                              () => draft = draft.copyWith(showHolidays: value),
                            ),
                          ),
                          _setupChip(
                            'Astrology',
                            draft.showAstrology,
                            (value) => setSheet(
                              () =>
                                  draft = draft.copyWith(showAstrology: value),
                            ),
                          ),
                          _setupChip(
                            'My events',
                            draft.showEvents,
                            (value) => setSheet(
                              () => draft = draft.copyWith(showEvents: value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: CalendarStudioTokens.of(sheetContext).surface2,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _setupRow(
                              title: 'Week starts on',
                              trailing: SizedBox(
                                width: 150,
                                child: SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment(
                                      value: false,
                                      label: Text('Sun'),
                                    ),
                                    ButtonSegment(
                                      value: true,
                                      label: Text('Mon'),
                                    ),
                                  ],
                                  selected: {draft.weekStartsMonday},
                                  onSelectionChanged: (value) => setSheet(
                                    () => draft = draft.copyWith(
                                      weekStartsMonday: value.first,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _setupRow(
                              title: 'Time zone',
                              subtitle: draft.timeZoneLabel,
                              trailing: const Icon(Icons.chevron_right),
                            ),
                            const Divider(height: 1),
                            _setupRow(
                              title: 'Output',
                              subtitle:
                                  '${template.category} · ${draft.period == CalendarStudioPeriod.year ? '12 pages' : '1 page'}',
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: CalendarStudioTokens.of(sheetContext).surface,
                  border: Border(
                    top: BorderSide(
                      color: CalendarStudioTokens.of(sheetContext).line,
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    12 + MediaQuery.paddingOf(sheetContext).bottom,
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () {
                      source = draft;
                      Navigator.pop(sheetContext);
                      _create(template.id);
                    },
                    child: const Text('Create project'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProjectSettings() {
    final project = controller.project!;
    final template = CalendarStudioTemplates.byId(project.templateId);
    var draft = project.source;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .88,
        child: StatefulBuilder(
          builder: (_, setSheet) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.tune),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calendar settings',
                            style: Theme.of(sheetContext).textTheme.titleLarge,
                          ),
                          Text(
                            template.name,
                            style: Theme.of(sheetContext).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    _sectionLabel('Period'),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('settings-year-${draft.year}'),
                            initialValue: draft.year,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                            ),
                            items: List.generate(
                              11,
                              (index) => DropdownMenuItem(
                                value: DateTime.now().year - 5 + index,
                                child: Text(
                                  '${DateTime.now().year - 5 + index}',
                                ),
                              ),
                            ),
                            onChanged: (value) => setSheet(
                              () => draft = draft.copyWith(year: value),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('settings-month-${draft.month}'),
                            initialValue: draft.month,
                            decoration: const InputDecoration(
                              labelText: 'Starts from',
                            ),
                            items: List.generate(
                              12,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text(_monthName(index + 1)),
                              ),
                            ),
                            onChanged: (value) => setSheet(
                              () => draft = draft.copyWith(month: value),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('Language on the calendar'),
                    SegmentedButton<CalendarStudioLanguage>(
                      segments: const [
                        ButtonSegment(
                          value: CalendarStudioLanguage.myanmar,
                          label: Text('မြန်မာ'),
                        ),
                        ButtonSegment(
                          value: CalendarStudioLanguage.english,
                          label: Text('English'),
                        ),
                        ButtonSegment(
                          value: CalendarStudioLanguage.both,
                          label: Text('Both'),
                        ),
                      ],
                      selected: {draft.language},
                      onSelectionChanged: (value) => setSheet(
                        () => draft = draft.copyWith(language: value.first),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('Show on each day'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _setupChip(
                          'Myanmar date',
                          draft.showMyanmarDate,
                          (value) => setSheet(
                            () =>
                                draft = draft.copyWith(showMyanmarDate: value),
                          ),
                        ),
                        _setupChip(
                          'Moon phases',
                          draft.showMoonPhases,
                          (value) => setSheet(
                            () => draft = draft.copyWith(showMoonPhases: value),
                          ),
                        ),
                        _setupChip(
                          'Holidays',
                          draft.showHolidays,
                          (value) => setSheet(
                            () => draft = draft.copyWith(showHolidays: value),
                          ),
                        ),
                        _setupChip(
                          'Astrology',
                          draft.showAstrology,
                          (value) => setSheet(
                            () => draft = draft.copyWith(showAstrology: value),
                          ),
                        ),
                        _setupChip(
                          'My events',
                          draft.showEvents,
                          (value) => setSheet(
                            () => draft = draft.copyWith(showEvents: value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(child: Text('Week starts on')),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('Sun')),
                            ButtonSegment(value: true, label: Text('Mon')),
                          ],
                          selected: {draft.weekStartsMonday},
                          onSelectionChanged: (value) => setSheet(
                            () => draft = draft.copyWith(
                              weekStartsMonday: value.first,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Time zone'),
                      subtitle: Text(draft.timeZoneLabel),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Project file',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'A copy with its images, to move this calendar to another '
                      'device or keep a backup.',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _exportProjectFile(
                            controller.project!,
                            CalendarStudioExportDestination.save,
                          ),
                          icon: const Icon(Icons.save_alt_outlined),
                          label: const Text('Save project file'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _exportProjectFile(
                            controller.project!,
                            CalendarStudioExportDestination.share,
                          ),
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Share'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  12 + MediaQuery.paddingOf(sheetContext).bottom,
                ),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {
                    controller.updateConfiguration(draft);
                    Navigator.pop(sheetContext);
                    _fitCanvas();
                  },
                  child: const Text('Apply settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      value,
      style: TextStyle(
        color: CalendarStudioTokens.of(context).ink2,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _setupChip(
    String label,
    bool selected,
    ValueChanged<bool> onSelected,
  ) => FilterChip(
    selected: selected,
    showCheckmark: true,
    label: Text(label),
    onSelected: onSelected,
  );

  Widget _setupRow({
    required String title,
    String? subtitle,
    required Widget trailing,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: CalendarStudioTokens.of(context).ink3,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        trailing,
      ],
    ),
  );

  Widget _editor(BuildContext context) {
    final project = controller.project!;
    final saveState = controller.saveState;
    final saveLabel = switch (saveState) {
      CalendarStudioSaveState.saved => 'Saved',
      CalendarStudioSaveState.saving => 'Saving…',
      CalendarStudioSaveState.failed => 'Not saved',
    };
    final saveColor = switch (saveState) {
      CalendarStudioSaveState.saved => CalendarStudioTokens.of(context).ok,
      CalendarStudioSaveState.saving => CalendarStudioTokens.of(context).ink3,
      CalendarStudioSaveState.failed => CalendarStudioTokens.of(context).error,
    };
    final saveIcon = switch (saveState) {
      CalendarStudioSaveState.saved => Icons.check,
      CalendarStudioSaveState.saving => Icons.sync,
      CalendarStudioSaveState.failed => Icons.warning_amber_rounded,
    };
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 900;
        final canvas = _canvas(context, project);
        final workspace = wide
            ? Row(
                children: [
                  SizedBox(width: 260, child: _layers()),
                  Expanded(child: canvas),
                  SizedBox(width: 320, child: _inspector()),
                ],
              )
            : Stack(
                children: [
                  Positioned.fill(child: canvas),
                  if (controller.selectedBlockId != null && _inspectorVisible)
                    Positioned.fill(child: _inspectorSheet()),
                ],
              );
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () async {
                await controller.saveNow();
                await _load();
                if (mounted) setState(() => view = _View.dashboard);
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _showProjectSettings,
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          project.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.tune, size: 14),
                    ],
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(saveIcon, size: 14, color: saveColor),
                      const SizedBox(width: 3),
                      Text(
                        saveLabel,
                        style: TextStyle(fontSize: 12, color: saveColor),
                      ),
                    ],
                  ),
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
                onPressed: () => _openPreview(),
                child: const Text('Export'),
              ),
            ],
          ),
          body: Column(
            children: [
              if (saveState == CalendarStudioSaveState.failed)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: CalendarStudioTokens.of(context).error.withAlpha(24),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: saveColor),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Couldn’t save your changes',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text('Check storage space, then try again.'),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: controller.saveNow,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              Expanded(child: workspace),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : SafeArea(top: false, child: _tools()),
        );
      },
    );
  }

  /// Tapping the board around the page clears the selection. Taps close to
  /// the page edge are ignored so near-misses on edge handles don't deselect;
  /// taps on the page itself are handled by the scene.
  Widget _deselectArea({required Size pageSize, required Widget child}) =>
      LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          key: const ValueKey('calendar-studio-board'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final area = constraints.biggest;
            final page = Rect.fromCenter(
              center: area.center(Offset.zero),
              width: pageSize.width,
              height: pageSize.height,
            );
            if (page.inflate(24).contains(details.localPosition)) return;
            if (controller.selectedBlockId != null) _selectBlock(null);
          },
          child: child,
        ),
      );

  Widget _canvas(
    BuildContext context,
    CalendarStudioProject project,
  ) => CustomPaint(
    painter: _EditorBoardPainter(tokens: CalendarStudioTokens.of(context)),
    child: Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = (constraints.maxWidth - 56).clamp(
                120.0,
                double.infinity,
              );
              final availableHeight = (constraints.maxHeight - 76).clamp(
                120.0,
                double.infinity,
              );
              final ratio = controller.currentPage.canvas.aspectRatio;
              final width = (availableHeight * ratio).clamp(
                120.0,
                availableWidth,
              );
              final height = width / ratio;
              return InteractiveViewer(
                transformationController: canvasController,
                minScale: _minCanvasZoom,
                maxScale: _maxCanvasZoom,
                boundaryMargin: const EdgeInsets.all(240),
                panEnabled: controller.selectedBlockId == null || _spacePanning,
                scaleEnabled: true,
                trackpadScrollCausesScale: true,
                child: _deselectArea(
                  pageSize: Size(width, height),
                  child: Center(
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Material(
                        elevation: 8,
                        shadowColor: Colors.black45,
                        clipBehavior: Clip.antiAlias,
                        child: Listener(
                          onPointerDown: _canvasPointerDown,
                          onPointerUp: _canvasPointerFinished,
                          onPointerCancel: _canvasPointerFinished,
                          // Live drags notify only `canvasChanges`, so this is
                          // the only subtree that rebuilds per pointer move.
                          child: RepaintBoundary(
                            child: ListenableBuilder(
                              listenable: _canvasListenable,
                              builder: (context, _) => CalendarStudioScene(
                                page: controller.currentPage,
                                source: project.source,
                                dataProvider: _calendarData,
                                assetStore: _assets,
                                selectedBlockId: controller.selectedBlockId,
                                showSafeArea: safeArea,
                                onSelect: _selectBlock,
                                onTransform: _spacePanning
                                    ? null
                                    : _updateBlockTransform,
                                onTransformStart:
                                    controller.beginBlockInteraction,
                                onTransformEnd: _endBlockTransform,
                                guides: _guides.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: controller.pageIndex > 0
                        ? () => _changePage(controller.pageIndex - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  InkWell(
                    onTap: () => _showPages(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: Text(
                        '${controller.currentPage.label} · ${controller.pageIndex + 1}/${project.pages.length}',
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: controller.pageIndex < project.pages.length - 1
                        ? () => _changePage(controller.pageIndex + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (controller.selectedBlockId != null)
          Positioned(right: 12, top: 66, child: _selectionToolbar()),
        Positioned(
          left: 12,
          bottom: 12,
          child: Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Zoom out',
                  visualDensity: VisualDensity.compact,
                  onPressed: canvasZoom <= _minCanvasZoom
                      ? null
                      : () => _setCanvasZoom(canvasZoom / 1.2),
                  icon: const Icon(Icons.remove),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _fitCanvas,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    child: Text('${(canvasZoom * 100).round()}%'),
                  ),
                ),
                IconButton(
                  tooltip: 'Zoom in',
                  visualDensity: VisualDensity.compact,
                  onPressed: canvasZoom >= _maxCanvasZoom
                      ? null
                      : () => _setCanvasZoom(canvasZoom * 1.2),
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  tooltip: 'Fit canvas',
                  visualDensity: VisualDensity.compact,
                  onPressed: _fitCanvas,
                  icon: const Icon(Icons.fit_screen_outlined),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _selectionToolbar() {
    final block = controller.currentPage.blocks
        .where((value) => value.id == controller.selectedBlockId)
        .firstOrNull;
    if (block == null) return const SizedBox();
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(18),
      color: CalendarStudioTokens.of(context).surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _openInspector,
              icon: const Icon(Icons.tune),
              tooltip: 'Edit item',
            ),
            IconButton(
              onPressed: controller.duplicateSelected,
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Duplicate',
            ),
            IconButton(
              onPressed: () => _updateSelectedBlock(
                (value) => value.copyWith(locked: !value.locked),
              ),
              icon: Icon(
                block.locked ? Icons.lock_outline : Icons.lock_open_outlined,
              ),
              tooltip: block.locked ? 'Unlock' : 'Lock',
            ),
            IconButton(
              onPressed: () => _updateSelectedBlock(
                (value) => value.copyWith(visible: !value.visible),
              ),
              icon: Icon(
                block.visible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              tooltip: block.visible ? 'Hide' : 'Show',
            ),
            IconButton(
              onPressed: _deleteSelectedWithUndo,
              color: CalendarStudioTokens.of(context).error,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSelectedWithUndo() {
    final block = controller.currentPage.blocks
        .where((value) => value.id == controller.selectedBlockId)
        .firstOrNull;
    if (block == null) return;
    controller.deleteSelected();
    setState(() => _inspectorVisible = false);
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('${block.name} deleted'),
        action: SnackBarAction(label: 'Undo', onPressed: controller.undo),
      ),
    );
  }

  Widget _tools() => Material(
    color: CalendarStudioTokens.of(context).surface,
    child: SizedBox(
      height: 60,
      child: Row(
        children: [
          _StudioTool(
            icon: Icons.add,
            label: 'Add',
            onTap: () => _showAdd(context),
          ),
          _StudioTool(
            icon: Icons.text_fields,
            label: 'Text',
            onTap: () => controller.addBlock(CalendarStudioBlockType.text),
          ),
          _StudioTool(
            icon: Icons.image_outlined,
            label: 'Image',
            onTap: () => _pickAsset(CalendarStudioBlockType.image),
          ),
          _StudioTool(
            icon: Icons.interests_outlined,
            label: 'Elements',
            onTap: () => _showElements(context),
          ),
          _StudioTool(
            icon: Icons.layers_outlined,
            label: 'Layers',
            onTap: () => _showLayers(context),
          ),
          _StudioTool(
            icon: Icons.view_carousel_outlined,
            label: 'Page',
            onTap: () => _showPageOptions(context),
          ),
        ],
      ),
    ),
  );

  void _updateSelectedBlock(
    CalendarStudioBlock Function(CalendarStudioBlock block) update,
  ) {
    final id = controller.selectedBlockId;
    if (id == null) return;
    final matches = controller.currentPage.blocks.where(
      (block) => block.id == id,
    );
    if (matches.isNotEmpty) controller.updateBlock(update(matches.first));
  }

  Widget _layers({bool modal = false}) {
    final blocks = controller.currentPage.blocks;
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  Text('Layers', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  if (constraints.maxWidth >= 420)
                    Text(
                      '${blocks.length} on this page',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (modal) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final block in blocks.reversed)
                  ListTile(
                    selected: controller.selectedBlockId == block.id,
                    leading: Icon(_icon(block.type)),
                    title: Text(block.name),
                    subtitle: Text(
                      block.locked ? 'Locked to app data' : block.type.name,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => controller.updateBlock(
                            block.copyWith(visible: !block.visible),
                          ),
                          icon: Icon(
                            block.visible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: block.visible ? 'Hide' : 'Show',
                        ),
                        IconButton(
                          onPressed: () => controller.updateBlock(
                            block.copyWith(locked: !block.locked),
                          ),
                          icon: Icon(
                            block.locked
                                ? Icons.lock_outline
                                : Icons.lock_open_outlined,
                          ),
                          tooltip: block.locked ? 'Unlock' : 'Lock',
                        ),
                      ],
                    ),
                    onTap: () => _selectBlock(block),
                  ),
              ],
            ),
          ),
          if (controller.selectedBlockId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => controller.moveSelectedLayer(1),
                      icon: const Icon(Icons.arrow_upward),
                      label: const Text('Forward'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => controller.moveSelectedLayer(-1),
                      icon: const Icon(Icons.arrow_downward),
                      label: const Text('Back'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Phone inspector: a draggable sheet that opens at about half height,
  /// expands to nearly full screen and scrolls; dragging it down closes it.
  Widget _inspectorSheet() {
    final grid =
        controller.currentPage.blocks
            .where((block) => block.id == controller.selectedBlockId)
            .firstOrNull
            ?.type ==
        CalendarStudioBlockType.calendarGrid;
    final initial = grid ? .55 : .45;
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (notification.extent <= notification.minExtent + .01 &&
            _inspectorVisible) {
          setState(() => _inspectorVisible = false);
        }
        return false;
      },
      child: DraggableScrollableSheet(
        key: ValueKey(
          'calendar-studio-inspector-${controller.selectedBlockId}',
        ),
        initialChildSize: initial,
        minChildSize: .2,
        maxChildSize: .92,
        snap: true,
        snapSizes: [initial, .92],
        builder: (context, scrollController) => DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 16)],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: _inspector(scrollController: scrollController, sheet: true),
          ),
        ),
      ),
    );
  }

  Widget _inspector({ScrollController? scrollController, bool sheet = false}) {
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
                  color: CalendarStudioTokens.of(context).ink3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Row(
            children: [
              Icon(_icon(block.type)),
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
                onPressed: () => setState(() => _inspectorVisible = false),
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
                onPressed: () => controller.updateBlock(
                  block.copyWith(locked: !block.locked),
                ),
                icon: Icon(
                  block.locked ? Icons.lock_outline : Icons.lock_open_outlined,
                ),
                tooltip: block.locked ? 'Unlock' : 'Lock',
              ),
              IconButton(
                onPressed: () => controller.updateBlock(
                  block.copyWith(visible: !block.visible),
                ),
                icon: Icon(
                  block.visible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: block.visible ? 'Hide' : 'Show',
              ),
              IconButton(
                onPressed: _deleteSelectedWithUndo,
                color: CalendarStudioTokens.of(context).error,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
              ),
            ],
          ),
          const Divider(),
          if (block.type == CalendarStudioBlockType.text) _textInspector(block),
          if (block.type == CalendarStudioBlockType.shape)
            _shapeInspector(block),
          if (block.type == CalendarStudioBlockType.calendarGrid)
            _calendarGridInspector(block),
          if (block.type == CalendarStudioBlockType.image ||
              block.type == CalendarStudioBlockType.logo)
            _imageInspector(block),
          if (block.type != CalendarStudioBlockType.calendarGrid) ...[
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
            _layerOrderControls(),
          ],
        ],
      ),
    );
  }

  Widget _imageInspector(CalendarStudioBlock block) {
    final width = (block.content['pixelWidth'] as num?)?.toInt() ?? 0;
    final height = (block.content['pixelHeight'] as num?)?.toInt() ?? 0;
    final fit = block.style['imageFit'] as String? ?? 'crop';
    final opacity = (block.style['opacity'] as num?)?.toDouble() ?? 1;
    final requiredPixels = (block.bounds.width * 2480).clamp(1, 2480);
    final dpi = width == 0 ? 0 : (width / requiredPixels * 300).round();
    final goodQuality = dpi >= 240;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: CalendarStudioTokens.of(context).primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image_outlined),
          ),
          title: Text(block.content['assetName'] as String? ?? 'Image'),
          subtitle: Text('$width × $height px'),
          trailing: OutlinedButton(
            onPressed: () => _pickAsset(block.type, replace: block),
            child: const Text('Replace'),
          ),
        ),
        if (block.content['assetId'] != null &&
            (widget.configuration.imageEditor != null ||
                _canRemoveBackground ||
                block.content['originalAssetId'] != null))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (widget.configuration.imageEditor != null)
                  FilledButton.tonalIcon(
                    key: const ValueKey('calendar-studio-edit-image'),
                    onPressed: () => _editImage(block),
                    icon: const Icon(Icons.auto_fix_high_outlined),
                    label: const Text('Edit image'),
                  ),
                if (_canRemoveBackground)
                  FilledButton.tonalIcon(
                    key: const ValueKey('calendar-studio-remove-background'),
                    onPressed: () => _removeBackground(block),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Remove background'),
                  ),
                if (block.content['originalAssetId'] != null)
                  OutlinedButton.icon(
                    onPressed: () => _revertImage(block),
                    icon: const Icon(Icons.restore),
                    label: const Text('Revert to original'),
                  ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CalendarStudioTokens.of(context).surface2,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Print quality at A4',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                width == 0
                    ? 'Image required'
                    : goodQuality
                    ? '✓ Good · $dpi dpi'
                    : 'Check · $dpi dpi',
                style: TextStyle(
                  color: goodQuality
                      ? CalendarStudioTokens.of(context).ok
                      : CalendarStudioTokens.of(context).warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const SizedBox(width: 70, child: Text('Fit')),
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'fill', label: Text('Fill')),
                  ButtonSegment(value: 'fit', label: Text('Fit')),
                  ButtonSegment(value: 'crop', label: Text('Crop')),
                ],
                selected: {fit},
                onSelectionChanged: (value) => controller.updateBlock(
                  block.copyWith(
                    style: {...block.style, 'imageFit': value.first},
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            const SizedBox(width: 70, child: Text('Opacity')),
            Expanded(
              child: Slider(
                value: opacity.clamp(0, 1),
                onChangeStart: (_) => controller.beginBlockInteraction(),
                onChangeEnd: (_) => controller.endBlockInteraction(),
                onChanged: (value) => controller.updateBlockLive(
                  block.copyWith(style: {...block.style, 'opacity': value}),
                ),
              ),
            ),
            SizedBox(width: 46, child: Text('${(opacity * 100).round()}%')),
          ],
        ),
      ],
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
          // Re-keyed when a suggestion is applied so the field shows it.
          key: ValueKey('calendar-studio-text-${block.id}-$_textFieldRevision'),
          initialValue: block.content['text'] as String? ?? '',
          decoration: const InputDecoration(labelText: 'Text'),
          onChanged: (value) => controller.updateBlock(
            block.copyWith(content: {...block.content, 'text': value}),
          ),
        ),
        if (_canSuggestText)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('calendar-studio-suggest-text'),
              onPressed: () => _suggestText(block),
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Suggest text'),
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
                onChangeStart: (_) => controller.beginBlockInteraction(),
                onChangeEnd: (_) => controller.endBlockInteraction(),
                onChanged: (value) => controller.updateBlockLive(
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

  Widget _shapeInspector(CalendarStudioBlock block) {
    const shapes = [
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
    const colors = [
      0xFF0E6B5C,
      0xFFD9A93A,
      0xFFB8322A,
      0xFF3F51B5,
      0xFF151B19,
      0xFFFFFFFF,
    ];
    final shape = block.content['shape'] as String? ?? 'rectangle';
    final strokeWidth = (block.style['strokeWidth'] as num?)?.toDouble() ?? 0;
    final opacity = (block.style['opacity'] as num?)?.toDouble() ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Shape'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final value in shapes)
              ChoiceChip(
                label: Text(value[0].toUpperCase() + value.substring(1)),
                selected: shape == value,
                onSelected: (_) => controller.updateBlock(
                  block.copyWith(content: {...block.content, 'shape': value}),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Fill colour'),
        const SizedBox(height: 6),
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
                          ? CalendarStudioTokens.of(context).ink
                          : CalendarStudioTokens.of(context).line,
                      width: block.style['color'] == color ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Row(
          children: [
            const Text('Outline'),
            Expanded(
              child: Slider(
                min: 0,
                max: 12,
                divisions: 12,
                value: strokeWidth.clamp(0, 12),
                label: '${strokeWidth.round()} px',
                onChangeStart: (_) => controller.beginBlockInteraction(),
                onChangeEnd: (_) => controller.endBlockInteraction(),
                onChanged: (value) => controller.updateBlockLive(
                  block.copyWith(style: {...block.style, 'strokeWidth': value}),
                ),
              ),
            ),
          ],
        ),
        const Text('Outline colour'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          children: [
            for (final color in colors)
              InkWell(
                onTap: () => controller.updateBlock(
                  block.copyWith(style: {...block.style, 'strokeColor': color}),
                ),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: block.style['strokeColor'] == color
                          ? CalendarStudioTokens.of(context).ink
                          : CalendarStudioTokens.of(context).line,
                      width: block.style['strokeColor'] == color ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Row(
          children: [
            const Text('Opacity'),
            Expanded(
              child: Slider(
                min: .1,
                max: 1,
                divisions: 9,
                value: opacity.clamp(.1, 1),
                label: '${(opacity * 100).round()}%',
                onChangeStart: (_) => controller.beginBlockInteraction(),
                onChangeEnd: (_) => controller.endBlockInteraction(),
                onChanged: (value) => controller.updateBlockLive(
                  block.copyWith(style: {...block.style, 'opacity': value}),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _calendarGridInspector(CalendarStudioBlock block) {
    final current = controller.project!.source;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Data')),
            ButtonSegment(value: 1, label: Text('Style')),
            ButtonSegment(value: 2, label: Text('Layout')),
          ],
          selected: {calendarInspectorTab},
          onSelectionChanged: (value) =>
              setState(() => calendarInspectorTab = value.first),
        ),
        const SizedBox(height: 12),
        if (calendarInspectorTab == 0) _calendarDataInspector(current),
        if (calendarInspectorTab == 1) _calendarStyleInspector(block),
        if (calendarInspectorTab == 2) _calendarLayoutInspector(block),
      ],
    );
  }

  Widget _calendarDataInspector(CalendarStudioSource current) => Column(
    children: [
      _compactSwitch(
        'Myanmar dates',
        current.showMyanmarDate,
        (value) =>
            controller.updateSource(current.copyWith(showMyanmarDate: value)),
      ),
      _compactSwitch(
        'Moon phases',
        current.showMoonPhases,
        (value) =>
            controller.updateSource(current.copyWith(showMoonPhases: value)),
      ),
      _compactSwitch(
        'Public holidays',
        current.showHolidays,
        (value) =>
            controller.updateSource(current.copyWith(showHolidays: value)),
      ),
      _compactSwitch(
        'Astrology days',
        current.showAstrology,
        (value) =>
            controller.updateSource(current.copyWith(showAstrology: value)),
      ),
      _compactSwitch(
        'My events',
        current.showEvents,
        (value) => controller.updateSource(current.copyWith(showEvents: value)),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Expanded(child: Text('Week starts')),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Sun')),
              ButtonSegment(value: true, label: Text('Mon')),
            ],
            selected: {current.weekStartsMonday},
            onSelectionChanged: (value) => controller.updateSource(
              current.copyWith(weekStartsMonday: value.first),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _compactSwitch(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SwitchListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
    value: value,
    onChanged: onChanged,
    title: Text(label),
  );

  Widget _calendarStyleInspector(CalendarStudioBlock block) {
    final gridLines = block.style['gridLines'] as String? ?? 'light';
    final numberFont = block.style['numberFont'] as String? ?? 'sans';
    final holidayColor =
        block.style['holidayColor'] as int? ??
        CalendarStudioTheme.holiday.toARGB32();
    final rowHeight = (block.style['rowHeight'] as num?)?.toDouble() ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Grid lines'),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'none', label: Text('None')),
            ButtonSegment(value: 'light', label: Text('Light')),
            ButtonSegment(value: 'full', label: Text('Full')),
          ],
          selected: {gridLines},
          onSelectionChanged: (value) => controller.updateBlock(
            block.copyWith(style: {...block.style, 'gridLines': value.first}),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(child: Text('Number font')),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'serif', label: Text('Serif')),
                ButtonSegment(value: 'sans', label: Text('Sans')),
              ],
              selected: {numberFont},
              onSelectionChanged: (value) => controller.updateBlock(
                block.copyWith(
                  style: {...block.style, 'numberFont': value.first},
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(child: Text('Holiday colour')),
            for (final color in const [
              CalendarStudioTheme.holiday,
              Color(0xFF278B5D),
              Color(0xFFD79B22),
            ])
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: InkWell(
                  onTap: () => controller.updateBlock(
                    block.copyWith(
                      style: {...block.style, 'holidayColor': color.toARGB32()},
                    ),
                  ),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: holidayColor == color.toARGB32()
                            ? CalendarStudioTokens.of(context).ink
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Row(
          children: [
            const Text('Row height'),
            Expanded(
              child: Slider(
                min: .75,
                max: 1.35,
                divisions: 12,
                value: rowHeight.clamp(.75, 1.35),
                label: '${(rowHeight * 100).round()}%',
                onChangeStart: (_) => controller.beginBlockInteraction(),
                onChangeEnd: (_) => controller.endBlockInteraction(),
                onChanged: (value) => controller.updateBlockLive(
                  block.copyWith(style: {...block.style, 'rowHeight': value}),
                ),
              ),
            ),
            Text('${(rowHeight * 100).round()}%'),
          ],
        ),
      ],
    );
  }

  Widget _calendarLayoutInspector(CalendarStudioBlock block) {
    final designSize = CalendarStudioScene.designSizeFor(
      controller.currentPage.canvas,
    );
    final canvasWidth = designSize.width;
    final canvasHeight = designSize.height;
    final bounds = block.bounds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 3.15,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _layoutField('X', bounds.left * canvasWidth, (value) {
              controller.updateBlock(
                block.copyWith(
                  bounds: bounds.copyWith(
                    left: (value / canvasWidth).clamp(0, 1 - bounds.width),
                  ),
                ),
              );
            }),
            _layoutField('Y', bounds.top * canvasHeight, (value) {
              controller.updateBlock(
                block.copyWith(
                  bounds: bounds.copyWith(
                    top: (value / canvasHeight).clamp(0, 1 - bounds.height),
                  ),
                ),
              );
            }),
            _layoutField('W', bounds.width * canvasWidth, (value) {
              controller.updateBlock(
                block.copyWith(
                  bounds: bounds.copyWith(
                    width: (value / canvasWidth).clamp(.06, 1 - bounds.left),
                  ),
                ),
              );
            }),
            _layoutField('H', bounds.height * canvasHeight, (value) {
              controller.updateBlock(
                block.copyWith(
                  bounds: bounds.copyWith(
                    height: (value / canvasHeight).clamp(.04, 1 - bounds.top),
                  ),
                ),
              );
            }),
          ],
        ),
        Row(
          children: [
            const Text('Rotation'),
            Expanded(
              child: Slider(
                min: -3.141592653589793,
                max: 3.141592653589793,
                divisions: 72,
                value: block.rotation.clamp(
                  -3.141592653589793,
                  3.141592653589793,
                ),
                label: '${(block.rotation * 180 / 3.141592653589793).round()}°',
                onChangeStart: (_) => controller.beginBlockInteraction(),
                onChangeEnd: (_) => controller.endBlockInteraction(),
                onChanged: (value) =>
                    controller.updateBlockLive(block.copyWith(rotation: value)),
              ),
            ),
          ],
        ),
        const Text('Layer order'),
        const SizedBox(height: 6),
        _layerOrderControls(),
      ],
    );
  }

  Widget _layoutField(
    String label,
    double value,
    ValueChanged<double> onSubmitted,
  ) => TextFormField(
    key: ValueKey('$label-${value.round()}'),
    initialValue: value.round().toString(),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, suffixText: 'px'),
    onFieldSubmitted: (text) {
      final number = double.tryParse(text);
      if (number != null) onSubmitted(number);
    },
  );

  Widget _layerOrderControls() => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => controller.moveSelectedLayer(1),
          icon: const Icon(Icons.flip_to_front_outlined),
          label: const Text('Forward'),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => controller.moveSelectedLayer(-1),
          icon: const Icon(Icons.flip_to_back_outlined),
          label: const Text('Back'),
        ),
      ),
    ],
  );

  void _updateBlockTransform(CalendarStudioBlock block) {
    if (_canvasPinching) return;
    final start = controller.interactionStartBlock(block.id) ?? block;
    final page = controller.currentPage;
    var bounds = block.bounds;
    var rotation = block.rotation;
    var guides = const <StudioGuide>[];
    if (rotation != start.rotation) {
      rotation = CalendarStudioTransform.snapRotation(rotation);
      if (rotation != block.rotation && rotation != _lastSnappedRotation) {
        HapticFeedback.selectionClick();
      }
      _lastSnappedRotation = rotation != block.rotation ? rotation : null;
    } else if ((bounds.width - start.bounds.width).abs() < 1e-9 &&
        (bounds.height - start.bounds.height).abs() < 1e-9) {
      final snapped = CalendarStudioTransform.snapMove(
        bounds,
        others: [
          for (final other in page.blocks)
            if (other.id != block.id && other.visible) other.bounds,
        ],
        design: CalendarStudioScene.designSizeFor(page.canvas),
        safeInset: page.canvas.safeInset,
        grid: snapToGrid,
      );
      bounds = snapped.bounds;
      guides = snapped.guides;
    } else if (snapToGrid && block.rotation == 0) {
      bounds = CalendarStudioTransform.snapResizeToGrid(start.bounds, bounds);
    }
    _setGuides(guides);
    controller.updateBlockDuringInteraction(
      block.copyWith(bounds: bounds, rotation: rotation),
    );
  }

  bool get _isTyping {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    return context.widget is EditableText ||
        context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// Desktop key map from the mockup (§5): arrows nudge 1 px (Shift: 10 px),
  /// Ctrl/Cmd+D duplicate, Del delete, Ctrl/Cmd+Z/Y undo/redo,
  /// Ctrl/Cmd+] / [ layer order, Ctrl/Cmd+0 fit, Ctrl/Cmd+P preview,
  /// Space+drag pan, Esc deselect.
  KeyEventResult _handleEditorKey(FocusNode node, KeyEvent event) {
    if (view != _View.editor || _isTyping) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      final down = event is! KeyUpEvent;
      if (down != _spacePanning) setState(() => _spacePanning = down);
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    final command = keyboard.isControlPressed || keyboard.isMetaPressed;
    final shift = keyboard.isShiftPressed;
    if (command) {
      if (key == LogicalKeyboardKey.keyZ) {
        shift ? controller.redo() : controller.undo();
      } else if (key == LogicalKeyboardKey.keyY) {
        controller.redo();
      } else if (key == LogicalKeyboardKey.keyD) {
        controller.duplicateSelected();
      } else if (key == LogicalKeyboardKey.bracketRight) {
        controller.moveSelectedLayer(1);
      } else if (key == LogicalKeyboardKey.bracketLeft) {
        controller.moveSelectedLayer(-1);
      } else if (key == LogicalKeyboardKey.digit0) {
        _fitCanvas();
      } else if (key == LogicalKeyboardKey.keyP) {
        _openPreview();
      } else {
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (controller.selectedBlockId == null) return KeyEventResult.ignored;
      _selectBlock(null);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      if (controller.selectedBlockId == null) return KeyEventResult.ignored;
      _deleteSelectedWithUndo();
      return KeyEventResult.handled;
    }
    final direction = switch (key) {
      LogicalKeyboardKey.arrowLeft => const Offset(-1, 0),
      LogicalKeyboardKey.arrowRight => const Offset(1, 0),
      LogicalKeyboardKey.arrowUp => const Offset(0, -1),
      LogicalKeyboardKey.arrowDown => const Offset(0, 1),
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;
    final id = controller.selectedBlockId;
    final block = id == null
        ? null
        : controller.currentPage.blocks.where((b) => b.id == id).firstOrNull;
    if (block == null || block.locked) return KeyEventResult.ignored;
    controller.updateBlock(
      block.copyWith(
        bounds: CalendarStudioTransform.move(
          block.bounds,
          direction * (shift ? 10 : 1),
          CalendarStudioScene.designSizeFor(controller.currentPage.canvas),
        ),
      ),
    );
    return KeyEventResult.handled;
  }

  void _setGuides(List<StudioGuide> guides) {
    final previous = _guides.value;
    if (listEquals(previous, guides)) return;
    if (guides.any((guide) => !previous.contains(guide))) {
      HapticFeedback.selectionClick();
    }
    _guides.value = guides;
  }

  void _endBlockTransform() {
    _guides.value = const [];
    _lastSnappedRotation = null;
    controller.endBlockInteraction();
  }

  /// Element and page settings sheets open tall so options aren't cramped;
  /// their content scrolls inside.
  static const _sheetHeight = .9;

  void _showLayers(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: _sheetHeight,
      child: _layers(modal: true),
    ),
  );
  void _showAdd(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: _sheetHeight,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
            child: Row(
              children: [
                Text(
                  'Add to page',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.85,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                for (final type in CalendarStudioBlockType.values)
                  _addBlockTile(type),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _addBlockTile(CalendarStudioBlockType type) {
    final (title, subtitle) = switch (type) {
      CalendarStudioBlockType.text => ('Text', 'Title, note or quote'),
      CalendarStudioBlockType.image => ('Image', 'Photo from your gallery'),
      CalendarStudioBlockType.logo => ('Logo', 'Your brand mark'),
      CalendarStudioBlockType.calendarGrid => (
        'Calendar grid',
        'A month, with Myanmar dates',
      ),
      CalendarStudioBlockType.eventList => ('Event list', 'From your Events'),
      CalendarStudioBlockType.holidayLegend => (
        'Holiday legend',
        'Explains marks and colours',
      ),
      CalendarStudioBlockType.shape => ('Shape', 'Rectangle, circle, line'),
      CalendarStudioBlockType.decoration => (
        'Decoration',
        'Lotus, borders, motifs',
      ),
    };
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (type == CalendarStudioBlockType.image ||
            type == CalendarStudioBlockType.logo) {
          _pickAsset(type);
        } else if (type == CalendarStudioBlockType.shape ||
            type == CalendarStudioBlockType.decoration) {
          _showElements(context);
        } else {
          controller.addBlock(type);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: CalendarStudioTokens.of(context).line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CalendarStudioTokens.of(context).primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon(type)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showElements(BuildContext context) async {
    const shapes = [
      ('rectangle', 'Rectangle', Icons.rectangle_outlined),
      ('rounded', 'Rounded', Icons.crop_16_9_rounded),
      ('circle', 'Circle', Icons.circle_outlined),
      ('oval', 'Oval', Icons.circle_outlined),
      ('triangle', 'Triangle', Icons.change_history),
      ('diamond', 'Diamond', Icons.diamond_outlined),
      ('pentagon', 'Pentagon', Icons.pentagon_outlined),
      ('hexagon', 'Hexagon', Icons.hexagon_outlined),
      ('octagon', 'Octagon', Icons.stop_outlined),
      ('star', 'Star', Icons.star_outline),
      ('heart', 'Heart', Icons.favorite_border),
      ('arrow', 'Arrow', Icons.arrow_forward),
      ('line', 'Line', Icons.horizontal_rule),
    ];
    const emojis = [
      '😀',
      '😂',
      '🥰',
      '😍',
      '😎',
      '🤩',
      '🥳',
      '😊',
      '🙏',
      '👏',
      '👍',
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '⭐',
      '✨',
      '🔥',
      '🎉',
      '🎁',
      '🎂',
      '🏆',
      '💡',
      '🌞',
      '🌙',
      '🌕',
      '🌸',
      '🌺',
      '🌿',
      '🍀',
      '🌈',
      '🐘',
      '🦚',
      '🦋',
      '🐉',
      '🍜',
      '☕',
      '🚗',
      '✈️',
      '🏠',
      '🏯',
      '🛕',
      '📅',
      '📌',
      '✅',
      '⚠️',
      '💬',
    ];
    final customEmoji = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: _sheetHeight,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Text(
                      'Elements',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Shapes'),
                  Tab(text: 'Emojis'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                      itemCount: shapes.length,
                      itemBuilder: (_, index) {
                        final shape = shapes[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(sheetContext);
                            controller.addBlock(
                              CalendarStudioBlockType.shape,
                              name: shape.$2,
                              bounds: shape.$1 == 'line'
                                  ? const StudioRect(
                                      left: .2,
                                      top: .3,
                                      width: .6,
                                      height: .025,
                                    )
                                  : const StudioRect(
                                      left: .25,
                                      top: .2,
                                      width: .5,
                                      height: .25,
                                    ),
                              content: {'shape': shape.$1},
                              style: const {
                                'color': 0xFF0E6B5C,
                                'strokeColor': 0xFF15201D,
                                'strokeWidth': 0.0,
                                'opacity': 1.0,
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: CalendarStudioTokens.of(
                                sheetContext,
                              ).surface2,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(shape.$3, size: 34),
                                const SizedBox(height: 6),
                                Text(shape.$2),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                          child: TextField(
                            controller: customEmoji,
                            decoration: InputDecoration(
                              labelText: 'Type or paste any emoji',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  final value = customEmoji.text.trim();
                                  if (value.isEmpty) return;
                                  Navigator.pop(sheetContext);
                                  _addEmoji(value);
                                },
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ),
                            onSubmitted: (value) {
                              if (value.trim().isEmpty) return;
                              Navigator.pop(sheetContext);
                              _addEmoji(value.trim());
                            },
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                            itemCount: emojis.length,
                            itemBuilder: (_, index) => InkWell(
                              onTap: () {
                                Navigator.pop(sheetContext);
                                _addEmoji(emojis[index]);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Text(
                                  emojis[index],
                                  style: const TextStyle(fontSize: 30),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    customEmoji.dispose();
  }

  void _addEmoji(String emoji) => controller.addBlock(
    CalendarStudioBlockType.text,
    name: 'Emoji',
    bounds: const StudioRect(left: .35, top: .25, width: .3, height: .18),
    content: {'text': emoji},
    style: const {
      'fontSize': 72.0,
      'fontWeight': 400,
      'align': 'center',
      'color': 0xFF15201D,
    },
  );
  void _showPageOptions(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * _sheetHeight,
    ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Page and theme',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
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

  void _showPages(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final project = controller.project!;
      return FractionallySizedBox(
        heightFactor: _sheetHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
              child: Row(
                children: [
                  Text('Pages', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  Text(
                    '${project.pages.length} ${project.pages.length == 1 ? 'page' : 'months'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: .55,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                ),
                itemCount: project.pages.length,
                itemBuilder: (_, index) {
                  final page = project.pages[index];
                  final selected = index == controller.pageIndex;
                  return InkWell(
                    onTap: () {
                      controller.setPage(index);
                      Navigator.pop(sheetContext);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: selected
                                  ? CalendarStudioTokens.of(context).primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IgnorePointer(
                              child: CalendarStudioScene(
                                page: page,
                                source: project.source,
                                dataProvider: _calendarData,
                                assetStore: _assets,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          page.label.length > 3
                              ? page.label.substring(0, 3)
                              : page.label,
                          style: TextStyle(
                            color: selected
                                ? CalendarStudioTokens.of(context).primary
                                : CalendarStudioTokens.of(context).ink3,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );

  /// "Choose image" sheet from the mockup; skipped when the host offers a
  /// single source.
  Future<CalendarStudioImageSource?> _chooseImageSource(
    List<CalendarStudioImageSource> sources,
  ) async {
    if (sources.isEmpty) return null;
    if (sources.length == 1) return sources.single;
    return showModalBottomSheet<CalendarStudioImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Choose image',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            for (final source in sources)
              ListTile(
                minTileHeight: 56,
                leading: Icon(switch (source) {
                  CalendarStudioImageSource.gallery =>
                    Icons.photo_library_outlined,
                  CalendarStudioImageSource.camera =>
                    Icons.photo_camera_outlined,
                  CalendarStudioImageSource.files => Icons.folder_outlined,
                }),
                title: Text(switch (source) {
                  CalendarStudioImageSource.gallery => 'Gallery',
                  CalendarStudioImageSource.camera => 'Camera',
                  CalendarStudioImageSource.files => 'Files',
                }),
                subtitle: Text(switch (source) {
                  CalendarStudioImageSource.gallery => 'Photos on this device',
                  CalendarStudioImageSource.camera => 'Take a new photo',
                  CalendarStudioImageSource.files => 'Browse files',
                }),
                onTap: () => Navigator.pop(context, source),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                "A copy is kept inside the app, so moving or deleting the "
                "original won't change your calendar.",
                style: TextStyle(
                  fontSize: 12,
                  color: CalendarStudioTokens.of(context).ink3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAsset(
    CalendarStudioBlockType type, {
    CalendarStudioBlock? replace,
  }) async {
    final store = _assets;
    if (store == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image storage is not configured.')),
        );
      }
      return;
    }
    final picker =
        widget.configuration.imagePicker ??
        const CalendarStudioFileImagePicker();
    final imageSource = await _chooseImageSource(picker.sources);
    if (imageSource == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final CalendarStudioAsset asset;
    try {
      final picked = await picker.pick(
        imageSource,
        maxDimension: CalendarStudioImageImport.maxDimension,
      );
      if (picked == null) return;
      final prepared = await CalendarStudioImageImport.prepare(picked);
      asset = await store.importAsset(
        CalendarStudioAssetInput(
          name: prepared.name,
          bytes: prepared.bytes,
          width: prepared.width,
          height: prepared.height,
        ),
      );
      if (prepared.resized) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Large image resized to ${prepared.width} × ${prepared.height} px '
              '— still sharp for print.',
            ),
          ),
        );
      }
    } on CalendarStudioUnsupportedImageException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("That file isn't an image Studio can use."),
        ),
      );
      return;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't add the image. Try again.")),
      );
      return;
    }
    if (!mounted) return;
    final assetContent = {
      'assetId': asset.id,
      'assetName': asset.name,
      'pixelWidth': asset.width,
      'pixelHeight': asset.height,
    };
    if (replace == null) {
      // One undo step for "add image", not add + assign.
      controller.addBlock(type, content: assetContent);
      return;
    }
    final block = controller.currentPage.blocks.firstWhere(
      (value) => value.id == replace.id,
    );
    controller.updateBlock(
      block.copyWith(
        content: {
          for (final entry in block.content.entries)
            if (!_editKeys.contains(entry.key)) entry.key: entry.value,
          ...assetContent,
        },
      ),
    );
  }

  /// Content keys that tie an image block to an editor session.
  static const _editKeys = {
    'originalAssetId',
    'editBaseAssetId',
    'editorState',
  };

  Future<void> _editImage(CalendarStudioBlock block) async {
    final editor = widget.configuration.imageEditor;
    final store = _assets;
    final content = block.content;
    final currentId = content['assetId'] as String?;
    // Saved history re-applies to the image it was made on; otherwise edit
    // what is on the page now (e.g. a background-removed cut-out).
    final hasHistory = content['editorState'] != null;
    final baseId = hasHistory
        ? content['editBaseAssetId'] as String? ??
              content['originalAssetId'] as String? ??
              currentId
        : currentId;
    final originalId = content['originalAssetId'] as String? ?? currentId;
    if (editor == null || store == null || baseId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final raw = await store.loadBytes(baseId);
    if (raw == null || raw.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text("The original image couldn't be found.")),
      );
      return;
    }
    if (!mounted) return;
    final original = raw is Uint8List ? raw : Uint8List.fromList(raw);
    final edited = await editor.edit(
      context,
      original: original,
      editorState: hasHistory ? content['editorState'] as String? : null,
      maxDimension: CalendarStudioImageImport.maxDimension,
    );
    if (edited == null) return;
    final CalendarStudioAsset asset;
    try {
      final name = block.content['assetName'] as String? ?? 'image';
      final prepared = await CalendarStudioImageImport.prepare(
        CalendarStudioPickedImage(
          name: _derivedName(
            name,
            'edited',
            CalendarStudioImageImport.mayHaveAlpha(edited.bytes),
          ),
          bytes: edited.bytes,
        ),
      );
      asset = await store.importAsset(
        CalendarStudioAssetInput(
          name: prepared.name,
          bytes: prepared.bytes,
          width: prepared.width,
          height: prepared.height,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't save the edited image.")),
      );
      return;
    }
    if (!mounted) return;
    // The block may have moved or changed while the editor was open.
    final current = controller.currentPage.blocks
        .where((value) => value.id == block.id)
        .firstOrNull;
    if (current == null) return;
    controller.updateBlock(
      current.copyWith(
        content: {
          for (final entry in current.content.entries)
            if (!_editKeys.contains(entry.key)) entry.key: entry.value,
          'originalAssetId': ?originalId,
          'editBaseAssetId': baseId,
          'assetId': asset.id,
          'pixelWidth': asset.width,
          'pixelHeight': asset.height,
          'editorState': ?edited.editorState,
        },
      ),
    );
  }

  Future<void> _revertImage(CalendarStudioBlock block) async {
    final originalId = block.content['originalAssetId'] as String?;
    if (originalId == null) return;
    final original = await _assets?.load(originalId);
    final current = controller.currentPage.blocks
        .where((value) => value.id == block.id)
        .firstOrNull;
    if (current == null) return;
    controller.updateBlock(
      current.copyWith(
        content: {
          for (final entry in current.content.entries)
            if (!_editKeys.contains(entry.key)) entry.key: entry.value,
          'assetId': originalId,
          if (original != null) ...{
            'assetName': original.name,
            'pixelWidth': original.width,
            'pixelHeight': original.height,
          },
        },
      ),
    );
  }

  static String _derivedName(String name, String suffix, bool png) {
    final dot = name.lastIndexOf('.');
    final base = (dot > 0 ? name.substring(0, dot) : name).replaceFirst(
      RegExp(r' \((edited|cutout)\)$'),
      '',
    );
    return '$base ($suffix).${png ? 'png' : 'jpg'}';
  }

  /// AI actions appear only when the host supplied a provider and it reports
  /// itself available (platform, flags, Firebase); failures count as "no".
  Future<void> _resolveAi() async {
    Future<bool> check(Future<bool> Function()? probe) async {
      if (probe == null) return false;
      try {
        return await probe();
      } catch (_) {
        return false;
      }
    }

    final ai = widget.configuration.ai;
    final results = await Future.wait([
      check(ai.backgroundRemover?.isAvailable),
      check(ai.textSuggester?.isAvailable),
    ]);
    if (!mounted) return;
    setState(() {
      _canRemoveBackground = results[0];
      _canSuggestText = results[1];
    });
  }

  Future<void> _removeBackground(CalendarStudioBlock block) async {
    final remover = widget.configuration.ai.backgroundRemover;
    final store = _assets;
    final assetId = block.content['assetId'] as String?;
    if (remover == null || store == null || assetId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(width: 16),
                Expanded(child: Text('Removing background…')),
              ],
            ),
          ),
        ),
      ),
    );
    CalendarStudioAsset? asset;
    String? failure;
    try {
      final raw = await store.loadBytes(assetId);
      if (raw == null || raw.isEmpty) {
        failure = "The image couldn't be found.";
      } else {
        final cutout = await remover.removeBackground(
          raw is Uint8List ? raw : Uint8List.fromList(raw),
        );
        if (cutout == null) {
          failure = 'No clear subject was found in this image.';
        } else {
          final prepared = await CalendarStudioImageImport.prepare(
            CalendarStudioPickedImage(
              name: _derivedName(
                block.content['assetName'] as String? ?? 'image',
                'cutout',
                true,
              ),
              bytes: cutout,
            ),
          );
          asset = await store.importAsset(
            CalendarStudioAssetInput(
              name: prepared.name,
              bytes: prepared.bytes,
              width: prepared.width,
              height: prepared.height,
            ),
          );
        }
      }
    } catch (_) {
      failure = "Couldn't remove the background. Try again.";
    } finally {
      navigator.pop();
    }
    if (asset == null) {
      messenger.showSnackBar(SnackBar(content: Text(failure ?? '')));
      return;
    }
    if (!mounted) return;
    final current = controller.currentPage.blocks
        .where((value) => value.id == block.id)
        .firstOrNull;
    if (current == null) return;
    // Keeps the first original for "Revert"; the cut-out becomes the base
    // for any later "Edit image".
    controller.updateBlock(
      current.copyWith(
        content: {
          for (final entry in current.content.entries)
            if (!_editKeys.contains(entry.key)) entry.key: entry.value,
          'originalAssetId':
              current.content['originalAssetId'] as String? ?? assetId,
          'assetId': asset.id,
          'pixelWidth': asset.width,
          'pixelHeight': asset.height,
        },
      ),
    );
  }

  Future<void> _suggestText(CalendarStudioBlock block) async {
    final suggester = widget.configuration.ai.textSuggester;
    final project = controller.project;
    if (suggester == null || project == null) return;
    final page = controller.currentPage;
    final pageSource = project.source.copyWith(
      year: page.year,
      month: page.month,
    );
    var days = const <CalendarStudioDayData>[];
    try {
      days =
          await _calendarData?.daysFor(pageSource, month: page.month) ??
          const [];
    } catch (_) {
      // Suggestions still work without holiday context.
    }
    final fontSize = (block.style['fontSize'] as num?)?.toDouble() ?? 20;
    final currentText = block.content['text'] as String? ?? '';
    final initialKind = fontSize >= 28
        ? CalendarStudioTextKind.title
        : currentText.length > 40
        ? CalendarStudioTextKind.quote
        : CalendarStudioTextKind.caption;
    CalendarStudioTextSuggestionRequest request(CalendarStudioTextKind kind) =>
        CalendarStudioTextSuggestionRequest(
          kind: kind,
          language: project.source.language,
          year: page.year,
          month: page.month,
          pageLabel: page.label,
          templateName: CalendarStudioTemplates.byId(project.templateId).name,
          currentText: currentText,
          holidays: [
            for (final day in days)
              if (day.holidayLabel case final String label) label,
          ],
          sabbathDays: [
            for (final day in days)
              if (day.isSabbath) day.date.day,
          ],
        );
    if (!mounted) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _TextSuggestionSheet(
        initialKind: initialKind,
        load: (kind) => suggester.suggest(request(kind)),
      ),
    );
    if (chosen == null || !mounted) return;
    final current = controller.currentPage.blocks
        .where((value) => value.id == block.id)
        .firstOrNull;
    if (current == null) return;
    controller.updateBlock(
      current.copyWith(content: {...current.content, 'text': chosen}),
    );
    setState(() => _textFieldRevision++);
  }

  Widget _preview(BuildContext context) {
    final project = controller.project!;
    final issues = CalendarStudioPreflight.check(project);
    final errors = issues
        .where((issue) => issue.severity == CalendarStudioIssueSeverity.error)
        .length;
    final warnings = issues
        .where((issue) => issue.severity == CalendarStudioIssueSeverity.warning)
        .length;
    final tips = issues
        .where((issue) => issue.severity == CalendarStudioIssueSeverity.tip)
        .length;
    final preview = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                avatar: const Icon(Icons.crop_free, size: 17),
                label: const Text('Safe area'),
                selected: safeArea,
                onSelected: (value) => setState(() => safeArea = value),
              ),
              FilterChip(
                avatar: const Icon(Icons.straighten, size: 17),
                label: const Text('Bleed'),
                selected: showBleed,
                onSelected: (value) => setState(() => showBleed = value),
              ),
              FilterChip(
                avatar: const Icon(Icons.grid_view, size: 17),
                label: const Text('Grid'),
                selected: showPreviewGrid,
                onSelected: (value) => setState(() => showPreviewGrid = value),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            // Opens on the page being edited, so "This page" in the export
            // sheet means what the user is looking at.
            key: const ValueKey('calendar-studio-preview-pages'),
            controller: _previewPages ??= PageController(
              initialPage: controller.pageIndex,
            ),
            itemCount: project.pages.length,
            onPageChanged: controller.setPage,
            itemBuilder: (_, index) => Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: CalendarStudioScene(
                  page: project.pages[index],
                  source: project.source,
                  dataProvider: _calendarData,
                  assetStore: _assets,
                  showSafeArea: safeArea,
                ),
              ),
            ),
          ),
        ),
        Text(
          '${controller.currentPage.label} · Page ${controller.pageIndex + 1} of ${project.pages.length}',
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < project.pages.length; index++)
              Container(
                width: index == controller.pageIndex ? 20 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index == controller.pageIndex
                      ? CalendarStudioTokens.of(context).primary
                      : CalendarStudioTokens.of(context).line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () => _showPreflight(context, issues, errors),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CalendarStudioTokens.of(context).surface,
                border: Border.all(
                  color: CalendarStudioTokens.of(context).line,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: errors > 0
                        ? CalendarStudioTokens.of(context).error
                        : CalendarStudioTokens.of(context).warning,
                    foregroundColor: Colors.white,
                    child: Icon(
                      errors > 0
                          ? Icons.error_outline
                          : Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          errors > 0
                              ? '$errors ${errors == 1 ? 'error' : 'errors'}, $warnings warnings'
                              : '$warnings warnings, $tips ${tips == 1 ? 'tip' : 'tips'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          errors > 0
                              ? 'Pages with errors are skipped until fixed.'
                              : 'No errors. You can export now.',
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    final flight = _preflight(issues, errors);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => setState(() => view = _View.editor),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preview'),
            Text(
              '${project.name} · ${project.pages.length} pages',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showPreflight(context, issues, errors),
            icon: const Icon(Icons.info_outline),
            tooltip: 'Preflight check',
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
            : preview,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => view = _View.editor),
                child: const Text('Back to editing'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _showExport(context),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export…'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreflight(
    BuildContext context,
    List<CalendarStudioIssue> issues,
    int errors,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: _sheetHeight,
      child: _preflight(issues, errors, dismissible: true),
    ),
  );

  Widget _preflight(
    List<CalendarStudioIssue> issues,
    int errors, {
    bool dismissible = false,
  }) => Material(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Preflight check',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
              ),
            ),
            if (dismissible)
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.close),
              ),
          ],
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
        pages: project.pages,
        currentPage: controller.pageIndex,
        blockedPages: {
          for (final issue in CalendarStudioPreflight.check(project))
            if (issue.severity == CalendarStudioIssueSeverity.error)
              project.pages.indexWhere((page) => page.id == issue.pageId),
        }..remove(-1),
      ),
    );
    if (request != null && mounted) {
      await _runExport(
        project,
        request.preset,
        request.destination,
        pageIndexes: request.pageIndexes,
      );
    }
  }

  void _openPreview() {
    _previewPages?.dispose();
    _previewPages = null;
    setState(() => view = _View.preview);
  }

  /// Next export of this project starts from the preset just used.
  void _rememberExportPreset(
    CalendarStudioProject project,
    CalendarStudioExportPreset preset,
  ) {
    final current = controller.project;
    if (current == null ||
        current.id != project.id ||
        current.defaultExportPreset.id == preset.id &&
            current.defaultExportPreset.format == preset.format) {
      return;
    }
    controller.updateDefaultExportPreset(
      preset.copyWith(fileName: 'my-calendar'),
    );
  }

  Future<void> _runExport(
    CalendarStudioProject project,
    CalendarStudioExportPreset preset,
    CalendarStudioExportDestination destination, {
    List<int>? pageIndexes,
  }) async {
    final delivery = widget.configuration.exportDelivery;
    if (delivery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No export destination is configured.')),
      );
      return;
    }
    final token = CalendarStudioExportCancellationToken();
    final run = StudioExportRun(
      project: project,
      pages: CalendarStudioExportService.selectPages(project, pageIndexes),
      preset: preset,
      destination: destination,
    );
    final navigator = Navigator.of(context, rootNavigator: true);
    var open = true;
    Future<void> deliver(CalendarStudioExportDestination target) async {
      final artifact = run.artifact;
      if (artifact == null) return;
      try {
        await delivery.deliver(artifact, destination: target);
        run.done(target);
      } catch (error) {
        run.note("Couldn't ${target.name} the file: $error");
      }
    }

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => StudioExportFlow(
          run: run,
          dataProvider: _calendarData,
          assetStore: _assets,
          onCancel: token.cancel,
          onDeliver: deliver,
        ),
      ).whenComplete(() => open = false),
    );
    try {
      final artifact =
          await CalendarStudioExportService(
            renderer: CalendarStudioRasterRenderer(
              dataProvider: _calendarData,
              assetStore: _assets,
            ),
          ).export(
            project: project,
            preset: preset,
            pageIndexes: pageIndexes,
            cancellationToken: token,
            onProgress: (value) => run.progress(value.completed),
          );
      run.delivering(artifact);
      await delivery.deliver(artifact, destination: destination);
      run.done(destination);
      _rememberExportPreset(project, preset);
      await _recordExport(
        project,
        CalendarStudioExportRecord(
          exportedAt: widget.configuration.now?.call() ?? DateTime.now(),
          presetLabel: preset.label,
          format: preset.format,
          pageCount: run.pages.length,
          fileName: artifact.name,
        ),
      );
    } on CalendarStudioExportCancelled {
      if (open && mounted) navigator.pop();
    } catch (error) {
      run.failed('$error');
    }
  }

  /// Saves the export summary without touching undo history; projects not
  /// open in the editor are saved directly.
  Future<void> _recordExport(
    CalendarStudioProject project,
    CalendarStudioExportRecord record,
  ) async {
    if (controller.project?.id == project.id) {
      controller.recordExport(record);
    } else {
      await widget.configuration.projects.save(
        project.copyWith(lastExport: record),
      );
    }
    await _load();
  }
}

enum _ExportPages { all, current, choose }

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({
    required this.initialPreset,
    required this.pages,
    this.currentPage,
    this.blockedPages = const {},
  });
  final CalendarStudioExportPreset initialPreset;
  final List<CalendarStudioPage> pages;

  /// The page being edited; preselects "This month" when set.
  final int? currentPage;

  /// Pages with preflight errors; exporting them is blocked.
  final Set<int> blockedPages;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  late CalendarStudioExportPreset preset = widget.initialPreset;
  var destination = CalendarStudioExportDestination.save;
  late var mode = widget.currentPage != null && widget.pages.length > 1
      ? _ExportPages.current
      : _ExportPages.all;
  late final Set<int> chosen = {widget.currentPage ?? 0};
  late final TextEditingController nameController = TextEditingController(
    text: _suggestedName(),
  );
  var _nameEdited = false;

  static const presets = [
    CalendarStudioExportPreset.screenPng,
    CalendarStudioExportPreset.a4Pdf,
    CalendarStudioExportPreset.highQualityPng,
    CalendarStudioExportPreset.a3Pdf,
    CalendarStudioExportPreset.squarePng,
    CalendarStudioExportPreset.storyPng,
  ];

  List<int> get selection => switch (mode) {
    _ExportPages.all => [for (var i = 0; i < widget.pages.length; i++) i],
    _ExportPages.current => [widget.currentPage ?? 0],
    _ExportPages.choose => chosen.toList()..sort(),
  };

  /// `family-2027-04` for one page, `family-2027-04-to-06` for a run,
  /// `family-5-pages` for any other partial selection.
  String _suggestedName() {
    final base = widget.initialPreset.fileName;
    final pages = selection;
    if (pages.length == widget.pages.length || pages.isEmpty) return base;
    String month(int index) =>
        widget.pages[index].month.toString().padLeft(2, '0');
    final first = widget.pages[pages.first];
    if (pages.length == 1) return '$base-${first.year}-${month(pages.first)}';
    final contiguous = pages.last - pages.first == pages.length - 1;
    final last = widget.pages[pages.last];
    if (contiguous && first.year == last.year) {
      return '$base-${first.year}-${month(pages.first)}-to-${month(pages.last)}';
    }
    return '$base-${pages.length}-pages';
  }

  void _updateSelection(VoidCallback change) => setState(() {
    change();
    if (!_nameEdited) nameController.text = _suggestedName();
  });

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = selection.length;
    final blocked = selection.where(widget.blockedPages.contains).toList();
    final extension = switch (preset.format) {
      CalendarStudioExportFormat.pdf => '.pdf',
      CalendarStudioExportFormat.png => pageCount > 1 ? '.zip' : '.png',
      CalendarStudioExportFormat.jpeg => pageCount > 1 ? '.zip' : '.jpg',
      CalendarStudioExportFormat.zip => '.zip',
    };
    final multiPage = widget.pages.length > 1;
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
              if (multiPage) ...[
                const SizedBox(height: 12),
                const Text('Pages'),
                const SizedBox(height: 6),
                SegmentedButton<_ExportPages>(
                  key: const ValueKey('calendar-studio-export-pages'),
                  segments: [
                    ButtonSegment(
                      value: _ExportPages.all,
                      label: Text('All ${widget.pages.length}'),
                    ),
                    if (widget.currentPage != null)
                      const ButtonSegment(
                        value: _ExportPages.current,
                        label: Text('This page'),
                      ),
                    const ButtonSegment(
                      value: _ExportPages.choose,
                      label: Text('Choose'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (values) =>
                      _updateSelection(() => mode = values.first),
                ),
                if (mode == _ExportPages.choose) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < widget.pages.length; i++)
                        FilterChip(
                          label: Text(widget.pages[i].label),
                          selected: chosen.contains(i),
                          onSelected: (on) => _updateSelection(() {
                            if (on) {
                              chosen.add(i);
                            } else if (chosen.length > 1) {
                              chosen.remove(i);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
              ],
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
                onChanged: (_) => _nameEdited = true,
                decoration: InputDecoration(
                  labelText: 'File name',
                  suffixText: extension,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${preset.width} × ${preset.height} px · ${preset.dpi} dpi · '
                '$pageCount page${pageCount == 1 ? '' : 's'}\n'
                'Myanmar text is shaped by Flutter for reliable PDF output.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (blocked.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '${blocked.map((i) => widget.pages[i].label).join(', ')} '
                  '${blocked.length == 1 ? 'has' : 'have'} problems to fix '
                  'before exporting. Check the preview, or choose other pages.',
                  style: TextStyle(
                    color: CalendarStudioTokens.of(context).error,
                  ),
                ),
              ],
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
                key: const ValueKey('calendar-studio-export-confirm'),
                onPressed: blocked.isNotEmpty
                    ? null
                    : () => Navigator.pop(
                        context,
                        _ExportRequest(
                          preset: preset.copyWith(
                            fileName: nameController.text,
                          ),
                          destination: destination,
                          pageIndexes: pageCount == widget.pages.length
                              ? null
                              : selection,
                        ),
                      ),
                icon: const Icon(Icons.download_outlined),
                label: Text(
                  'Export ${preset.format.name.toUpperCase()} · '
                  '$pageCount page${pageCount == 1 ? '' : 's'}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportRequest {
  const _ExportRequest({
    required this.preset,
    required this.destination,
    this.pageIndexes,
  });
  final CalendarStudioExportPreset preset;
  final CalendarStudioExportDestination destination;

  /// Null exports every page.
  final List<int>? pageIndexes;
}

class _StudioTool extends StatelessWidget {
  const _StudioTool({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: tokens.ink2),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: tokens.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorBoardPainter extends CustomPainter {
  const _EditorBoardPainter({required this.tokens});
  final CalendarStudioTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tokens.surface3);
    final dotPaint = Paint()..color = tokens.ink.withValues(alpha: .16);
    const spacing = 16.0;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EditorBoardPainter oldDelegate) =>
      oldDelegate.tokens != tokens;
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

String _monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];

class _TextSuggestionSheet extends StatefulWidget {
  const _TextSuggestionSheet({required this.initialKind, required this.load});
  final CalendarStudioTextKind initialKind;
  final Future<List<String>> Function(CalendarStudioTextKind kind) load;

  @override
  State<_TextSuggestionSheet> createState() => _TextSuggestionSheetState();
}

class _TextSuggestionSheetState extends State<_TextSuggestionSheet> {
  late var _kind = widget.initialKind;
  late Future<List<String>> _suggestions = widget.load(_kind);

  void _reload([CalendarStudioTextKind? kind]) => setState(() {
    _kind = kind ?? _kind;
    _suggestions = widget.load(_kind);
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Suggest text',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SegmentedButton<CalendarStudioTextKind>(
            segments: const [
              ButtonSegment(
                value: CalendarStudioTextKind.title,
                label: Text('Title'),
              ),
              ButtonSegment(
                value: CalendarStudioTextKind.quote,
                label: Text('Quote'),
              ),
              ButtonSegment(
                value: CalendarStudioTextKind.caption,
                label: Text('Caption'),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (value) => _reload(value.single),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .6,
            ),
            child: FutureBuilder<List<String>>(
              future: _suggestions,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final items = snapshot.data ?? const <String>[];
                if (snapshot.hasError || items.isEmpty) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("Suggestions aren't available right now."),
                      ),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Try again'),
                      ),
                    ],
                  );
                }
                return ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in items)
                      ListTile(
                        minTileHeight: 48,
                        title: Text(item),
                        trailing: const Icon(Icons.north_west, size: 18),
                        onTap: () => Navigator.pop(context, item),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suggestions are written by AI. Check names and dates before '
            'printing.',
            style: TextStyle(
              fontSize: 12,
              color: CalendarStudioTokens.of(context).ink3,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Review step before a project file is saved, per the round-2 mockups.
class _ImportSummary extends StatelessWidget {
  const _ImportSummary({required this.file});
  final CalendarStudioProjectFile file;

  @override
  Widget build(BuildContext context) {
    final project = file.project;
    final page = project.pages.firstOrNull;
    final tokens = CalendarStudioTokens.of(context);
    final megabytes = (file.sizeInBytes / (1 << 20)).toStringAsFixed(1);
    final canvas = page?.canvas;
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
              'Import project',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (page != null)
                      SizedBox(
                        width: 64,
                        child: IgnorePointer(
                          child: CalendarStudioScene(
                            page: page,
                            source: project.source,
                            resolvedAssets: {
                              for (final MapEntry(:key, :value)
                                  in file.assets.entries)
                                key: value.bytes,
                            },
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
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
              '${project.pages.length}'
                  '${canvas == null ? '' : ' · ${canvas.width.round()} × ${canvas.height.round()}'}',
            ),
            row('Images', '${file.assets.length} included'),
            row('Saved as', '${project.name} (imported)'),
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
                  'in this file. Those blocks will ask for a new image.',
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
                    key: const ValueKey('calendar-studio-import-confirm'),
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
