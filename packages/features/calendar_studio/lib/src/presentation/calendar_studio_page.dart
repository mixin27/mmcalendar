import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart'
    show CupertinoActivityIndicator, CupertinoAlertDialog;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart'
    show
        AppMenuAction,
        AppMenuButton,
        AppStyle,
        AppTokens,
        showAppConfirm,
        showAppActionSheet,
        showAppPrompt;

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_project_theme.dart';
import '../models/calendar_studio_types.dart';
import '../models/calendar_studio_user_template.dart';
import '../services/calendar_studio_cache.dart';
import '../services/calendar_studio_contracts.dart';
import '../services/calendar_studio_controller.dart';
import '../services/calendar_studio_export_service.dart';
import '../services/calendar_studio_image_import.dart';
import '../services/calendar_studio_preflight.dart';
import '../services/calendar_studio_project_bundle.dart';
import '../services/calendar_studio_template_bundle.dart';
import '../services/calendar_studio_transform.dart';
import '../services/calendar_studio_raster_renderer.dart';
import '../templates/calendar_studio_bindings.dart';
import '../templates/calendar_studio_templates.dart';
import '../templates/calendar_studio_user_templates.dart';
import '../theme/calendar_studio_font_catalog.dart';
import '../theme/calendar_studio_theme.dart';
import '../widgets/calendar_studio_scene.dart';
import 'calendar_studio_export_flow.dart';
import 'calendar_studio_strings.dart';
import 'editor/calendar_studio_add_panel.dart';
import 'editor/calendar_studio_contextual_bar.dart';
import 'editor/calendar_studio_project_settings.dart';
import 'editor/inspector/studio_inspector_controls.dart';
import 'editor/inspector/calendar_studio_inspector.dart';
import 'editor/inspector/studio_inspector_host.dart';
import 'calendar_studio_shimmer.dart';
import 'calendar_studio_template_sheets.dart';
import 'calendar_studio_toast.dart';

// Layout breakpoints, the same as the app's ResponsiveUtils (600 / 1024).
// Calendar Studio is standalone, so it keeps its own copy.
const double _tabletWidth = 600;
const double _desktopWidth = 1024;

class CalendarStudioWorkspace extends StatefulWidget {
  const CalendarStudioWorkspace({required this.configuration, super.key});
  final CalendarStudioConfiguration configuration;
  @override
  State<CalendarStudioWorkspace> createState() => _CalendarStudioThemeState();
}

/// Applies Studio's theme above the workspace, so every sheet and dialog the
/// workspace opens (they capture the theme of the context that opens them)
/// looks like Studio rather than the host app.
class _CalendarStudioThemeState extends State<CalendarStudioWorkspace> {
  ThemeData? _theme;
  CalendarStudioTokens? _themeTokens;
  Brightness? _themeBrightness;
  CalendarStudioChrome? _themeChrome;

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
        _themeBrightness != brightness ||
        _themeChrome != widget.configuration.chrome) {
      _themeTokens = tokens;
      _themeBrightness = brightness;
      _themeChrome = widget.configuration.chrome;
      final base = CalendarStudioTheme.fromTokens(
        tokens,
        brightness: brightness,
        chrome: widget.configuration.chrome,
        fontFamily: widget.configuration.fontFamily,
        fontFamilyFallback: widget.configuration.fontFamilyFallback,
      );
      // The app's menus, sheets and alerts read AppTokens; give them Studio's
      // colours in the app style Studio was opened with.
      _theme = base.copyWith(
        extensions: [
          ...base.extensions.values,
          AppTokens.resolve(
            style: widget.configuration.chrome == CalendarStudioChrome.clear
                ? AppStyle.clear
                : AppStyle.material,
            scheme: base.colorScheme,
          ),
        ],
      );
    }
    return Theme(
      data: _theme!,
      child: _CalendarStudioBody(configuration: widget.configuration),
    );
  }
}

class _CalendarStudioBody extends StatefulWidget {
  const _CalendarStudioBody({required this.configuration});
  final CalendarStudioConfiguration configuration;
  @override
  State<_CalendarStudioBody> createState() => _CalendarStudioPageState();
}

enum _View { dashboard, project, templates, editor, preview }

class _CalendarStudioPageState extends State<_CalendarStudioBody> {
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
  var _projectsAsList = false;
  var _galleryQuery = '';
  var _galleryPlace = 'All';
  String? _galleryMood;
  String? _selectedPresetId;
  String? _detailId;
  var _canRemoveBackground = false;
  var _canSuggestText = false;
  var _textFieldRevision = 0;
  PageController? _previewPages;
  final _templatePreviews =
      <(String, CalendarStudioSource), CalendarStudioProject>{};
  var view = _View.dashboard;
  var projects = <CalendarStudioProject>[];
  var _userTemplates = <CalendarStudioUserTemplate>[];
  var loading = true;
  late var source = CalendarStudioSource(
    year: DateTime.now().year + 1,
    language: widget.configuration.defaultLanguage,
  );
  var safeArea = true;
  var showBleed = false;
  var showPreviewGrid = false;
  var snapToGrid = true;
  var projectFilter = 'All';
  var canvasZoom = 1.0;
  var calendarInspectorTab = 0;
  var _inspectorVisible = false;

  /// The text block being typed into on the page, if any.
  String? _editingTextId;
  String? _lastTapId;
  DateTime? _lastTapAt;
  var _canvasPointerCount = 0;
  var _canvasPinching = false;

  @override
  void initState() {
    super.initState();
    controller = CalendarStudioController(widget.configuration)
      ..addListener(_refresh);
    canvasController = TransformationController()
      ..addListener(_onCanvasTransformChanged);
    // Load once the page has slid in, so the transition stays smooth.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _routeSettled();
      if (mounted) await _load();
    });
    _resolveAi();
  }

  /// Completes when this page's push transition has finished.
  Future<void> _routeSettled() {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) return Future.value();
    final done = Completer<void>();
    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed && !done.isCompleted) {
        animation.removeStatusListener(listener);
        done.complete();
      }
    }

    animation.addStatusListener(listener);
    // Never wait forever (e.g. a route that is not animated).
    return done.future.timeout(
      const Duration(milliseconds: 600),
      onTimeout: () => animation.removeStatusListener(listener),
    );
  }

  Future<void> _load() async {
    final (loaded, _) = await (
      widget.configuration.projects.list(),
      _loadTemplates(),
    ).wait;
    projects = loaded;
    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadTemplates() async {
    final store = widget.configuration.templates;
    if (store == null) return;
    try {
      _userTemplates = await store.list();
    } catch (_) {
      _userTemplates = const [];
    }
    controller.userTemplates = [
      for (final template in _userTemplates)
        CalendarStudioUserTemplates.toTemplate(template),
    ];
  }

  /// The user's templates, then the built-in ones.
  List<CalendarStudioTemplate> get _allTemplates => [
    ...controller.userTemplates,
    ...CalendarStudioTemplates.all,
  ];

  /// Built-in or user template; a placeholder when a user template behind
  /// some projects was deleted.
  CalendarStudioTemplate _templateById(String id) =>
      controller.templateOf(id) ??
      () {
        final blank = CalendarStudioTemplates.byId('blank');
        return CalendarStudioTemplate(
          id: id,
          name: 'Deleted template',
          category: 'Custom',
          canvas: blank.canvas,
          monthly: true,
          create: blank.create,
        );
      }();

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
    _endTextEdit();
    controller.setPage(index);
    _inspectorVisible = false;
    _fitCanvas();
  }

  void _selectBlock(CalendarStudioBlock? block) {
    // A second tap on a selected text block within half a second types
    // into it on the page.
    final now = DateTime.now();
    final lastTapAt = _lastTapAt;
    final again =
        block != null &&
        block.id == _lastTapId &&
        lastTapAt != null &&
        now.difference(lastTapAt) < const Duration(milliseconds: 500);
    _lastTapId = block?.id;
    _lastTapAt = now;
    if (block?.id != _editingTextId) _endTextEdit();
    if (again &&
        block.type == CalendarStudioBlockType.text &&
        !block.locked &&
        controller.selectedBlockId == block.id &&
        controller.selectedBlockIds.length == 1) {
      _startTextEdit(block);
      return;
    }
    controller.select(block?.id);
    // Canvas taps take keyboard focus back from inspector fields.
    if (!_editorFocus.hasPrimaryFocus) _editorFocus.requestFocus();
    if (block == null && _inspectorVisible) {
      setState(() => _inspectorVisible = false);
    }
  }

  void _startTextEdit(CalendarStudioBlock block) {
    if (block.type != CalendarStudioBlockType.text || block.locked) return;
    if (_editingTextId == block.id) return;
    _endTextEdit();
    controller
      ..select(block.id)
      // Typing is one undo step, however many characters.
      ..beginEditGroup();
    setState(() {
      _editingTextId = block.id;
      _inspectorVisible = false;
    });
  }

  void _endTextEdit() {
    if (_editingTextId == null) return;
    controller.endEditGroup();
    _editingTextId = null;
    if (mounted) {
      setState(() {});
      if (!_editorFocus.hasPrimaryFocus) _editorFocus.requestFocus();
    }
  }

  void _typeText(String text) {
    final block = controller.currentPage.blocks
        .where((value) => value.id == _editingTextId)
        .firstOrNull;
    if (block == null) return;
    // Typed text replaces a month binding, so it stays as written.
    controller.updateBlock(
      block.copyWith(
        content: {
          for (final entry in block.content.entries)
            if (entry.key != CalendarStudioBindings.key) entry.key: entry.value,
          'text': text,
        },
      ),
    );
  }

  void _undo() {
    _endTextEdit();
    controller.undo();
  }

  /// Moves every selected block by the drag's travel from where each was
  /// when the drag began.
  void _moveSelection(Offset delta) {
    final size = CalendarStudioScene.designSizeFor(
      controller.currentPage.canvas,
    );
    controller.updateBlocksDuringInteraction([
      for (final id in controller.selectedBlockIds)
        if (controller.interactionStartBlock(id) case final start?
            when !start.locked)
          start.copyWith(
            bounds: CalendarStudioTransform.move(start.bounds, delta, size),
          ),
    ]);
  }

  /// Selects the blocks a marquee touches, leaving out ones it sits inside
  /// (full-page backgrounds would otherwise always join).
  void _selectInRect(Rect area) {
    _endTextEdit();
    final ordered = [...controller.currentPage.blocks]
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    controller.selectMany([
      for (final block in ordered)
        if (block.visible && !block.locked)
          if (Rect.fromLTWH(
                block.bounds.left,
                block.bounds.top,
                block.bounds.width,
                block.bounds.height,
              )
              case final rect
              when rect.overlaps(area) &&
                  !(rect.contains(area.topLeft) &&
                      rect.contains(area.bottomRight)))
            block.id,
    ]);
  }

  void _applyToAllPages(CalendarStudioBlock block, {bool layout = false}) {
    final changed = controller.applyToAllPages(block, layout: layout);
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    if (changed == 0) {
      messenger.toast(StudioStrings.alreadyMatches);
    } else {
      messenger.toast(
        StudioStrings.appliedToMonths(changed),
        actionLabel: 'Undo',
        onAction: controller.undo,
      );
    }
  }

  void _openInspector({int? tab}) {
    _endTextEdit();
    setState(() {
      calendarInspectorTab = tab ?? 0;
      _inspectorVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) => _buildWorkspace(context);

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
      _View.project => _projectDetail(context),
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

  String _presetName(CalendarStudioProject project) =>
      _templateById(project.templateId).name;

  String _period(CalendarStudioProject project) {
    final first = project.pages.first;
    final last = project.pages.last;
    String short(CalendarStudioPage page) =>
        page.label.substring(0, math.min(3, page.label.length));
    if (project.pages.length == 1) return '${first.label} ${first.year}';
    return first.year == last.year
        ? '${short(first)}–${short(last)} ${first.year}'
        : '${short(first)} ${first.year}–${short(last)} ${last.year}';
  }

  String _ago(DateTime time) {
    final now = widget.configuration.now?.call() ?? DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} h ago';
    if (difference.inDays == 1) return 'yesterday';
    if (difference.inDays < 30) return '${difference.inDays} days ago';
    return 'on ${time.day} ${_monthName(time.month).substring(0, 3)} ${time.year}';
  }

  bool _recentlyExported(CalendarStudioProject project) {
    final record = project.lastExport;
    if (record == null) return false;
    final now = widget.configuration.now?.call() ?? DateTime.now();
    return now.difference(record.exportedAt).inDays < 30;
  }

  String _languageLabel(CalendarStudioLanguage language) => language.label;

  /// A page of [project]: its cached image, or a shimmer until the live
  /// page has its turn to build (one per frame).
  Widget _projectThumb(
    CalendarStudioProject project, {
    int page = 0,
    double displayWidth = 200,
  }) => StudioThumbnail(
    cacheKey: '${project.id}@${project.updatedAt.microsecondsSinceEpoch}#$page',
    aspectRatio: project.pages[page].canvas.aspectRatio,
    builder: (_) => IgnorePointer(
      child: CalendarStudioScene(
        page: project.pages[page],
        source: project.source,
        dataProvider: _calendarData,
        assetStore: _assets,
        displayWidth: displayWidth,
      ),
    ),
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
    floatingActionButton: projects.isEmpty
        ? null
        : FloatingActionButton.extended(
            onPressed: () => setState(() => view = _View.templates),
            icon: const Icon(Icons.add),
            label: const Text('New calendar'),
          ),
    body: AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: loading
          ? const _DashboardSkeleton(key: ValueKey('loading'))
          : projects.isEmpty
          ? KeyedSubtree(
              key: const ValueKey('empty'),
              child: _emptyDashboard(context),
            )
          : LayoutBuilder(
              key: const ValueKey('projects'),
              builder: (context, box) {
                final count = box.maxWidth >= _desktopWidth
                    ? 4
                    : (box.maxWidth >= _tabletWidth ? 3 : 2);
                final visible = _filteredProjects;
                // Slivers, so only the cards on screen are built.
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      sliver: SliverList.list(
                        children: [
                          _continueCard(context, projects.first),
                          const SizedBox(height: 16),
                          _projectFilters(),
                          const SizedBox(height: 12),
                          Text(
                            'Your projects',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    if (visible.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No ${projectFilter.toLowerCase()} projects yet.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (_projectsAsList)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        sliver: DecoratedSliver(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).cardTheme.color ??
                                Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          sliver: SliverList.builder(
                            itemCount: visible.length,
                            itemBuilder: (_, index) =>
                                _projectRow(context, visible[index]),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        sliver: SliverGrid.builder(
                          itemCount: visible.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: count,
                                childAspectRatio: .68,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                              ),
                          itemBuilder: (_, index) => RepaintBoundary(
                            child: _projectCard(context, visible[index]),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    ),
  );

  Widget _projectFilters() => Row(
    children: [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final filter in const [
                'All',
                'Wall',
                'Desk',
                'Social',
                'Print',
              ])
                ChoiceChip(
                  label: Text(filter),
                  selected: projectFilter == filter,
                  onSelected: (_) => setState(() => projectFilter = filter),
                ),
            ],
          ),
        ),
      ),
      IconButton(
        tooltip: _projectsAsList ? 'Grid view' : 'List view',
        onPressed: () => setState(() => _projectsAsList = !_projectsAsList),
        icon: Icon(
          _projectsAsList ? Icons.grid_view_outlined : Icons.view_list_outlined,
        ),
      ),
    ],
  );

  /// First visit (mockup 6): a fan of presets, then start fresh or import.
  Widget _emptyDashboard(BuildContext context) {
    final fan = [
      for (final id in const ['love_relationship', 'pagoda', 'ocean'])
        CalendarStudioTemplates.byId(id),
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 120,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < fan.length; i++)
                    Transform.translate(
                      offset: Offset((1 - i) * 8.0, i == 1 ? -8 : 0),
                      child: Transform.rotate(
                        angle: (i - 1) * .14,
                        child: SizedBox(
                          width: 74,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _templatePreview(fan[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Design your first calendar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pick a preset with Myanmar dates, moon days and holidays already '
              'in place.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => setState(() => view = _View.templates),
              child: const Text('Browse presets'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _importProject,
              child: const Text('Import a project file'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _continueCard(BuildContext context, CalendarStudioProject project) {
    final tokens = CalendarStudioTokens.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: _projectThumb(project, displayWidth: 96),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTINUE EDITING',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .7,
                      color: tokens.ink3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${_presetName(project)} · ${_period(project)} · '
                    'Saved ${_ago(project.updatedAt)}',
                    style: TextStyle(fontSize: 12, color: tokens.ink3),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => _open(project),
                    child: const Text('Resume'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The app's menu: an iOS pull-down in Clear, a Material menu otherwise.
  Widget _projectMenu(CalendarStudioProject project) => AppMenuButton(
    key: ValueKey('calendar-studio-project-menu-${project.id}'),
    tooltip: 'Project actions',
    groups: [
      [
        AppMenuAction(
          label: 'Rename',
          icon: Icons.edit_outlined,
          onSelected: () => _projectAction('rename', project),
        ),
        AppMenuAction(
          label: 'Duplicate',
          icon: Icons.copy_outlined,
          onSelected: () => _projectAction('duplicate', project),
        ),
      ],
      [
        AppMenuAction(
          label: 'Export…',
          icon: Icons.ios_share_outlined,
          onSelected: () => _projectAction('export', project),
        ),
        AppMenuAction(
          label: 'Save project file',
          icon: Icons.download_outlined,
          onSelected: () => _projectAction('save-file', project),
        ),
        AppMenuAction(
          label: 'Share project file',
          icon: Icons.share_outlined,
          onSelected: () => _projectAction('share-file', project),
        ),
      ],
      [
        AppMenuAction(
          label: 'Delete…',
          icon: Icons.delete_outline,
          destructive: true,
          onSelected: () => _projectAction('delete', project),
        ),
      ],
    ],
  );

  Widget _projectSubtitle(CalendarStudioProject project) => Text.rich(
    TextSpan(
      text: '${_presetName(project)} · ${_period(project)}',
      children: [
        if (_recentlyExported(project))
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: CalendarStudioTokens.of(context).primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Exported',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    ),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: 12,
      color: CalendarStudioTokens.of(context).ink3,
    ),
  );

  Widget _projectCard(BuildContext context, CalendarStudioProject project) =>
      Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openProjectDetail(project),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.all(14),
                  child: Center(child: _projectThumb(project)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _projectMenu(project),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _projectSubtitle(project),
              ),
            ],
          ),
        ),
      );

  Widget _projectRow(BuildContext context, CalendarStudioProject project) =>
      ListTile(
        onTap: () => _openProjectDetail(project),
        leading: SizedBox(
          width: 40,
          child: _projectThumb(project, displayWidth: 40),
        ),
        title: Text(project.name, overflow: TextOverflow.ellipsis),
        subtitle: _projectSubtitle(project),
        trailing: _projectMenu(project),
      );

  void _openProjectDetail(CalendarStudioProject project) => setState(() {
    _detailId = project.id;
    view = _View.project;
  });

  CalendarStudioProject? get _detailProject =>
      projects.where((project) => project.id == _detailId).firstOrNull;

  Future<void> _openPage(CalendarStudioProject project, int index) async {
    await _open(project);
    _changePage(index);
  }

  /// Project detail (mockup 4): actions, last export and every page.
  /// Long-press a page to export just that month.
  Widget _projectDetail(BuildContext context) {
    final project = _detailProject;
    if (project == null) return _dashboard(context);
    final tokens = CalendarStudioTokens.of(context);
    final template = _templateById(project.templateId);
    final blocked = _pagesWithErrors(project);
    final warned = {
      for (final issue in CalendarStudioPreflight.check(project))
        project.pages.indexWhere((page) => page.id == issue.pageId),
    }..remove(-1);
    final record = project.lastExport;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => setState(() => view = _View.dashboard),
        ),
        title: Text(project.name),
        actions: [_projectMenu(project)],
      ),
      body: LayoutBuilder(
        builder: (context, box) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text(
              '${template.name} · ${template.category.split(' · ').last} · '
              '${project.pages.length} page${project.pages.length == 1 ? '' : 's'} · '
              '${_languageLabel(project.source.language)}',
              style: TextStyle(color: tokens.ink3),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _open(project),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Open editor'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      _showExport(context, project: project, fromEditor: false),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Export…'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _exportProjectFile(
                    project,
                    CalendarStudioExportDestination.share,
                  ),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share file'),
                ),
                if (widget.configuration.templates != null)
                  OutlinedButton.icon(
                    key: const ValueKey('calendar-studio-save-template'),
                    onPressed: () => _saveAsTemplate(project),
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Save as template'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                title: Text(
                  record == null
                      ? 'Not exported yet'
                      : 'Last export · ${record.presetLabel} · '
                            '${record.pageCount} page${record.pageCount == 1 ? '' : 's'}',
                ),
                subtitle: record == null
                    ? const Text('Export a PDF or images when you are ready.')
                    : Text(record.fileName),
                trailing: record == null
                    ? null
                    : Text(
                        _ago(record.exportedAt),
                        style: TextStyle(color: tokens.ink3),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'PAGES',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: .7,
                color: tokens.ink3,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: project.pages.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: box.maxWidth >= _desktopWidth ? 6 : 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: .62,
              ),
              itemBuilder: (_, index) => InkWell(
                key: ValueKey('calendar-studio-detail-page-$index'),
                borderRadius: BorderRadius.circular(6),
                onTap: () => _openPage(project, index),
                onLongPress: () => _showExport(
                  context,
                  project: project,
                  currentPage: index,
                  fromEditor: false,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(child: _projectThumb(project, page: index)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.pages[index].label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        if (warned.contains(index))
                          Tooltip(
                            message: blocked.contains(index)
                                ? 'Needs fixing before export'
                                : 'Has a preflight warning',
                            child: Icon(
                              Icons.circle,
                              size: 8,
                              color: blocked.contains(index)
                                  ? tokens.error
                                  : tokens.warning,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    final name = await showAppPrompt(
      context: context,
      title: 'Rename project',
      initial: project.name,
      placeholder: 'Project name',
      confirmLabel: 'Rename',
    );
    if (name == null || name == project.name) return;
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
      messenger.toast(
        'No export destination is configured.',
        kind: StudioToastKind.error,
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
      messenger.toast('${artifact.name} is ready.');
    } catch (_) {
      messenger.toast(
        "Couldn't create the project file.",
        kind: StudioToastKind.error,
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
      messenger.toast(error.message, kind: StudioToastKind.error);
      return;
    } catch (_) {
      messenger.toast("Couldn't open that file.", kind: StudioToastKind.error);
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
      messenger.toast(
        'Imported "${project.name}".',
        actionLabel: 'Open',
        onAction: () => _open(project),
      );
    } catch (_) {
      messenger.toast(
        "Couldn't import the project.",
        kind: StudioToastKind.error,
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
    final confirmed = await showAppConfirm(
      context: context,
      title: 'Delete “${project.name}”?',
      message:
          'This removes the project and its ${project.pages.length} pages from this device. '
          'Images used only by this project are removed too. Files you already exported are not affected.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    await widget.configuration.projects.delete(project.id);
    await _deleteUnusedAssets();
    await _load();
  }

  /// Removes stored images no project or template uses any more.
  Future<void> _deleteUnusedAssets() async {
    final remaining = await widget.configuration.projects.list();
    final templates = await widget.configuration.templates?.list() ?? const [];
    final usedAssets = <String>{
      for (final item in remaining)
        ...CalendarStudioProjectBundle.referencedAssetIds(item),
      for (final template in templates) ...template.assetIds,
    };
    await _assets?.deleteUnusedAssets(usedAssets);
  }

  /// Dashboard filter for a project, from its template's category label
  /// ("Wall · A4 portrait", "Story · 9:16", …).
  String _projectCategory(CalendarStudioProject project) =>
      switch (_templateById(project.templateId).category.split(' ').first) {
        'Wall' => 'Wall',
        'Desk' => 'Desk',
        'Social' || 'Story' => 'Social',
        _ => 'Print',
      };

  Widget _templateMenu(
    CalendarStudioUserTemplate template, {
    bool compact = false,
  }) => SizedBox.square(
    dimension: compact ? 32 : 48,
    child: FittedBox(
      child: AppMenuButton(
        key: ValueKey('calendar-studio-template-menu-${template.id}'),
        tooltip: 'Template actions',
        groups: [
          [
            AppMenuAction(
              label: 'Share',
              icon: Icons.share_outlined,
              onSelected: () => _templateAction('share', template),
            ),
            AppMenuAction(
              label: 'Rename',
              icon: Icons.edit_outlined,
              onSelected: () => _templateAction('rename', template),
            ),
          ],
          [
            AppMenuAction(
              label: 'Delete…',
              icon: Icons.delete_outline,
              destructive: true,
              onSelected: () => _templateAction('delete', template),
            ),
          ],
        ],
      ),
    ),
  );

  Future<void> _templateAction(
    String action,
    CalendarStudioUserTemplate template,
  ) => switch (action) {
    'share' => _shareTemplate(template),
    'rename' => _renameTemplate(template),
    'delete' => _deleteTemplate(template),
    _ => Future.value(),
  };

  /// "Save as template" (from project detail or the editor's settings).
  Future<void> _saveAsTemplate(
    CalendarStudioProject project, {
    int page = 0,
  }) async {
    final store = widget.configuration.templates;
    if (store == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final request =
        await showModalBottomSheet<CalendarStudioSaveTemplateRequest>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => FractionallySizedBox(
            heightFactor: _sheetHeight,
            child: CalendarStudioSaveTemplateSheet(
              project: project,
              initialPage: page,
              moodOptions: _moods.take(10).toList(),
              dataProvider: _calendarData,
              assetStore: _assets,
            ),
          ),
        );
    if (request == null || !mounted) return;
    final template = CalendarStudioUserTemplates.capture(
      project,
      project.pages[request.pageIndex],
      name: request.name,
      author: request.author,
      blocks: request.blocks,
      keepPhotos: request.keepPhotos,
      moods: request.moods,
      now: widget.configuration.now?.call() ?? DateTime.now(),
    );
    try {
      await store.save(template);
    } catch (_) {
      messenger.toast(
        "Couldn't save the template.",
        kind: StudioToastKind.error,
      );
      return;
    }
    await _loadTemplates();
    if (!mounted) return;
    setState(() {});
    messenger.toast(
      'Saved “${template.name}” to My templates.',
      actionLabel: 'View',
      onAction: () => setState(() {
        _galleryQuery = '';
        _galleryMood = null;
        _galleryPlace = 'All';
        view = _View.templates;
      }),
    );
    // The preview is for sharing; render it after saving so the sheet
    // closes at once.
    unawaited(_withPreview(template, source: project.source));
  }

  /// [template] with a rendered preview, saved; falls back to [template] when
  /// rendering fails.
  Future<CalendarStudioUserTemplate> _withPreview(
    CalendarStudioUserTemplate template, {
    CalendarStudioSource? source,
  }) async {
    if (template.preview != null) return template;
    try {
      final project = CalendarStudioUserTemplates.toTemplate(template).create(
        id: 'template-preview',
        source: (source ?? this.source).copyWith(
          period: CalendarStudioPeriod.month,
        ),
        now: template.createdAt,
      );
      final page = project.pages.first;
      final png =
          await CalendarStudioRasterRenderer(
            dataProvider: _calendarData,
            assetStore: _assets,
          ).renderPage(
            project,
            page,
            width: 600,
            height: (600 * page.canvas.height / page.canvas.width).round(),
          );
      final withPreview = template.copyWith(preview: png);
      await widget.configuration.templates?.save(withPreview);
      await _loadTemplates();
      return withPreview;
    } catch (_) {
      return template;
    }
  }

  Future<void> _shareTemplate(CalendarStudioUserTemplate template) async {
    final messenger = ScaffoldMessenger.of(context);
    final delivery = widget.configuration.exportDelivery;
    if (delivery == null) {
      messenger.toast(
        'No export destination is configured.',
        kind: StudioToastKind.error,
      );
      return;
    }
    try {
      final artifact = await CalendarStudioTemplateBundle.export(
        await _withPreview(template),
        assets: _assets,
        fileName: _safeFileName(template.name),
      );
      await delivery.deliver(
        artifact,
        destination: CalendarStudioExportDestination.share,
      );
    } catch (_) {
      messenger.toast(
        "Couldn't create the template file.",
        kind: StudioToastKind.error,
      );
    }
  }

  Future<void> _renameTemplate(CalendarStudioUserTemplate template) async {
    final name = await showAppPrompt(
      context: context,
      title: 'Rename template',
      initial: template.name,
      placeholder: 'Template name',
      confirmLabel: 'Rename',
    );
    if (name == null || name == template.name) return;
    await widget.configuration.templates?.save(
      template.copyWith(
        name: name,
        updatedAt: widget.configuration.now?.call() ?? DateTime.now(),
      ),
    );
    await _loadTemplates();
    if (mounted) setState(() {});
  }

  Future<void> _deleteTemplate(CalendarStudioUserTemplate template) async {
    final confirmed = await showAppConfirm(
      context: context,
      title: 'Delete “${template.name}”?',
      message: 'Calendars you already made from it keep their design.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    await widget.configuration.templates?.delete(template.id);
    await _deleteUnusedAssets();
    await _loadTemplates();
    if (!mounted) return;
    setState(() {
      if (_selectedPresetId == template.templateId) _selectedPresetId = null;
    });
  }

  Future<void> _importTemplate() async {
    final store = widget.configuration.templates;
    if (store == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final pick =
        widget.configuration.pickTemplateFile ??
        CalendarStudioTemplateBundle.pickFile;
    final CalendarStudioTemplateFile file;
    try {
      final bytes = await pick();
      if (bytes == null) return;
      file = await CalendarStudioTemplateBundle.read(bytes);
    } on CalendarStudioProjectFileException catch (error) {
      messenger.toast(error.message, kind: StudioToastKind.error);
      return;
    } catch (_) {
      messenger.toast("Couldn't open that file.", kind: StudioToastKind.error);
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
      builder: (_) => CalendarStudioTemplateImportSummary(file: file),
    );
    if (confirmed != true || !mounted) return;
    try {
      final template = await CalendarStudioTemplateBundle.import(
        file,
        templates: store,
        assets: _assets,
        now: widget.configuration.now?.call(),
      );
      await _loadTemplates();
      if (!mounted) return;
      setState(() {
        _galleryQuery = '';
        _galleryMood = null;
        _galleryPlace = 'All';
        view = _View.templates;
      });
      messenger.toast('Added “${template.name}” to My templates.');
    } catch (_) {
      messenger.toast(
        "Couldn't import the template.",
        kind: StudioToastKind.error,
      );
    }
  }

  String _safeFileName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    return normalized.isEmpty ? 'calendar' : normalized;
  }

  static const _places = ['All', 'Wall', 'Desk', 'Social', 'Story', 'Annual'];

  /// Gallery place for a template, from its category label.
  static String _placeOf(CalendarStudioTemplate template) =>
      switch (template.category.split(' ').first) {
        'Desk' => 'Desk',
        'Social' => 'Social',
        'Story' => 'Story',
        'Annual' => 'Annual',
        'Wall' || 'Print' => 'Wall',
        _ => 'All',
      };

  List<String> get _moods {
    final counts = <String, int>{};
    for (final template in _allTemplates) {
      for (final mood in template.moods) {
        counts[mood] = (counts[mood] ?? 0) + 1;
      }
    }
    return counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  bool _matchesGallery(CalendarStudioTemplate template, {String? place}) {
    final wanted = place ?? _galleryPlace;
    if (wanted != 'All' && _placeOf(template) != wanted) return false;
    if (_galleryMood case final mood? when !template.moods.contains(mood)) {
      return false;
    }
    final query = _galleryQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    return [
      template.name,
      template.category,
      ...template.moods,
    ].any((value) => value.toLowerCase().contains(query));
  }

  Widget _palette(CalendarStudioTemplate template, {double size = 14}) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 3,
    children: [
      for (final color in template.palette)
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Color(color),
            borderRadius: BorderRadius.circular(size * .28),
            border: Border.all(color: const Color(0x1F000000)),
          ),
        ),
    ],
  );

  Widget _presetCard(
    BuildContext context,
    CalendarStudioTemplate template, {
    required bool wide,
  }) {
    final selected = wide && _selectedPresetId == template.id;
    final tokens = CalendarStudioTokens.of(context);
    return InkWell(
      key: ValueKey('calendar-studio-preset-${template.id}'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => wide
          ? setState(() => _selectedPresetId = template.id)
          : _showPresetDetail(context, template),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: tokens.surface2,
                borderRadius: BorderRadius.circular(12),
                border: selected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.5,
                      )
                    : null,
              ),
              padding: const EdgeInsets.all(10),
              child: Center(
                child: AspectRatio(
                  aspectRatio: template.canvas.aspectRatio,
                  child: _templatePreview(template),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (template.palette.isNotEmpty) _palette(template),
          const SizedBox(height: 4),
          if (template.user case final user?)
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(height: 24, child: _templateMenu(user, compact: true)),
              ],
            )
          else
            Text(
              template.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          Text(
            template.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: tokens.ink3),
          ),
        ],
      ),
    );
  }

  SliverGrid _presetGrid(
    BuildContext context,
    List<CalendarStudioTemplate> templates, {
    required int columns,
    required bool wide,
  }) => SliverGrid.builder(
    itemCount: templates.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      childAspectRatio: .62,
      mainAxisSpacing: 14,
      crossAxisSpacing: 12,
    ),
    itemBuilder: (_, index) =>
        _presetCard(context, templates[index], wide: wide),
  );

  Widget _galleryFilters(BuildContext context, {required bool vertical}) {
    final search = TextField(
      key: const ValueKey('calendar-studio-preset-search'),
      onChanged: (value) => setState(() => _galleryQuery = value),
      decoration: const InputDecoration(
        hintText: 'Search presets or moods',
        prefixIcon: Icon(Icons.search),
        isDense: true,
      ),
    );
    final places = [
      for (final place in _places)
        ChoiceChip(
          label: Text(
            place == 'All'
                ? 'All ${_allTemplates.length}'
                : '$place ${_allTemplates.where((t) => _placeOf(t) == place).length}',
          ),
          selected: _galleryPlace == place,
          onSelected: (_) => setState(() => _galleryPlace = place),
        ),
    ];
    final moods = [
      for (final mood in _moods)
        FilterChip(
          label: Text(mood),
          selected: _galleryMood == mood,
          onSelected: (on) => setState(() => _galleryMood = on ? mood : null),
        ),
    ];
    if (vertical) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          search,
          const SizedBox(height: 16),
          Text('PLACE', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: places),
          const SizedBox(height: 16),
          Text('MOOD', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: moods),
        ],
      );
    }
    Widget row(List<Widget> chips) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(spacing: 8, children: chips),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: search,
        ),
        row(places),
        const SizedBox(height: 6),
        row(moods),
      ],
    );
  }

  Widget _templates(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth >= _desktopWidth;
      final filtered = _allTemplates
          .where((template) => _matchesGallery(template))
          .toList();
      final browsing =
          _galleryQuery.trim().isEmpty &&
          _galleryMood == null &&
          _galleryPlace == 'All';
      final mine = filtered.where((t) => t.user != null).toList();
      final fresh = filtered.where((t) => t.collection != null).toList();
      final classic = filtered
          .where((t) => t.collection == null && t.user == null)
          .toList();
      final columns = wide ? 4 : (box.maxWidth >= _tabletWidth ? 3 : 2);
      Widget heading(String text, String trailing) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: .7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(trailing, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
      final grid = CustomScrollView(
        slivers: [
          if (!wide)
            SliverToBoxAdapter(
              child: _galleryFilters(context, vertical: false),
            ),
          if (filtered.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No presets match. Try another mood.')),
            )
          else if (browsing) ...[
            if (mine.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: heading(
                  'My templates',
                  '${mine.length} template${mine.length == 1 ? '' : 's'}',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _presetGrid(
                  context,
                  mine,
                  columns: columns,
                  wide: wide,
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: heading('New · Vol 1 & 2', '${fresh.length} presets'),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _presetGrid(context, fresh, columns: columns, wide: wide),
            ),
            SliverToBoxAdapter(
              child: heading('Classic', '${classic.length} templates'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: _presetGrid(
                context,
                classic,
                columns: columns,
                wide: wide,
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(child: heading('Results', '${filtered.length}')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: _presetGrid(
                context,
                filtered,
                columns: columns,
                wide: wide,
              ),
            ),
          ],
        ],
      );
      final selected = wide
          ? _allTemplates.where((t) => t.id == _selectedPresetId).firstOrNull
          : null;
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => setState(() => view = _View.dashboard),
          ),
          title: const Text('Choose a preset'),
          actions: [
            if (widget.configuration.templates != null)
              IconButton(
                tooltip: 'Import template',
                onPressed: _importTemplate,
                icon: const Icon(Icons.file_open_outlined),
              ),
          ],
        ),
        body: wide
            ? Row(
                children: [
                  SizedBox(
                    width: 240,
                    child: _galleryFilters(context, vertical: true),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: grid),
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: 320,
                    child: selected == null
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Select a preset to see its months and colours.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : _presetDetail(context, selected, panel: true),
                  ),
                ],
              )
            : grid,
      );
    },
  );

  /// The first text block's font and its Myanmar fallback, for the detail.
  String _presetFonts(CalendarStudioTemplate template) {
    final family = template
        .create(
          id: 'fonts-${template.id}',
          source: source.copyWith(period: CalendarStudioPeriod.month),
          now: DateTime(source.year),
        )
        .pages
        .first
        .blocks
        .where((block) => block.type == CalendarStudioBlockType.text)
        .map((block) => block.style['fontFamily'] as String?)
        .nonNulls
        .firstOrNull;
    if (family == null) return 'Noto Sans Myanmar';
    final serif = CalendarStudioFontCatalog.byFamily(family)?.serif ?? false;
    final myanmar = serif ? 'Noto Serif Myanmar' : 'Noto Sans Myanmar';
    return family == myanmar || family == 'Noto Sans Myanmar'
        ? family
        : '$family · $myanmar';
  }

  Widget _monthPreview(CalendarStudioTemplate template, int month) {
    final monthSource = source.copyWith(
      period: CalendarStudioPeriod.month,
      month: month,
    );
    final project = _templatePreviews.putIfAbsent(
      (template.id, monthSource),
      () => template.create(
        id: 'preview-${template.id}-$month',
        source: monthSource,
        now: DateTime(monthSource.year),
      ),
    );
    return IgnorePointer(
      child: CalendarStudioScene(
        page: project.pages.first,
        source: project.source,
        dataProvider: _calendarData,
        assetStore: _assets,
      ),
    );
  }

  /// Preset detail (mockup 2): sample months, palette, fonts and moods.
  Widget _presetDetail(
    BuildContext context,
    CalendarStudioTemplate template, {
    bool panel = false,
  }) {
    final tokens = CalendarStudioTokens.of(context);
    final months = template.monthly ? const [1, 4, 10] : const [1];
    final pages = template.monthly ? source.pageCount : 1;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, panel ? 20 : 0, 20, 20),
      children: [
        SizedBox(
          height: 260,
          child: _PresetCarousel(
            children: [
              for (final month in months)
                Center(
                  child: AspectRatio(
                    aspectRatio: template.canvas.aspectRatio,
                    child: _monthPreview(template, month),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(template.name, style: Theme.of(context).textTheme.titleLarge),
            for (final mood in template.moods.take(2))
              Chip(
                label: Text(mood),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        Text(
          '${template.category} · $pages page${pages == 1 ? '' : 's'}',
          style: TextStyle(color: tokens.ink3),
        ),
        if (template.palette.isNotEmpty) ...[
          const SizedBox(height: 10),
          _palette(template, size: 18),
        ],
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              spacing: 6,
              children: [
                for (final (label, value) in [
                  ('Fonts', _presetFonts(template)),
                  (
                    'Pages',
                    template.monthly
                        ? 'One per month'
                        : 'Whole year on one sheet',
                  ),
                  if (template.collection case final collection?)
                    ('Collection', collection),
                  if (template.user?.author case final author?) ('By', author),
                  if (template.user case final user?)
                    ('Based on', _templateById(user.basePresetId).name),
                ])
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 86,
                        child: Text(
                          label,
                          style: TextStyle(color: tokens.ink3),
                        ),
                      ),
                      Expanded(child: Text(value)),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (template.user case final user?) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _templateAction('share', user),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
              ),
              OutlinedButton.icon(
                onPressed: () => _templateAction('rename', user),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Rename'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  if (!panel) Navigator.pop(context);
                  await _templateAction('delete', user);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('calendar-studio-use-preset'),
          onPressed: () {
            if (!panel) Navigator.pop(context);
            _showSetup(this.context, template);
          },
          child: const Text('Use preset'),
        ),
      ],
    );
  }

  void _showPresetDetail(
    BuildContext context,
    CalendarStudioTemplate template,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: _sheetHeight,
      child: _presetDetail(sheetContext, template),
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
    final now = widget.configuration.now?.call() ?? DateTime.now();
    final sample = template.create(id: 'setup', source: source, now: now);
    final canvas = sample.pages.first.canvas;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .9,
        child: CalendarStudioSetupSheet(
          title: 'Set up ${template.name}',
          subtitle: template.category,
          preview: _templatePreview(template),
          initial: StudioSettingsDraft(
            source: source,
            theme: CalendarStudioProjectThemes.of(sample),
            width: canvas.width,
            height: canvas.height,
            bleed: canvas.bleed > 0,
            safeInset: canvas.safeInset,
            output: sample.defaultExportPreset,
          ),
          onCreate: (draft) async {
            source = draft.source;
            await _create(template.id);
            if (!mounted) return;
            _applySettings(draft);
          },
        ),
      ),
    );
  }

  /// Applies project settings as one undo step: calendar data, theme, page
  /// size and print margins; the output choice isn't a design edit.
  void _applySettings(StudioSettingsDraft draft) {
    _endTextEdit();
    controller
      ..beginEditGroup()
      ..updateConfiguration(draft.source);
    if (CalendarStudioProjectThemes.of(controller.project!) != draft.theme) {
      controller.applyTheme(draft.theme);
    }
    controller
      ..updateCanvases(
        (canvas) => canvas.copyWith(width: draft.width, height: draft.height),
        allPages: draft.resizeAll,
      )
      ..updateCanvases(
        (canvas) => canvas.copyWith(
          bleed: draft.bleed ? 3 : 0,
          safeInset: draft.safeInset,
        ),
      )
      ..endEditGroup()
      ..updateDefaultExportPreset(draft.output);
    _fitCanvas();
  }

  Future<void> _showProjectSettings() async {
    final project = controller.project!;
    final canvas = controller.currentPage.canvas;
    final theme = CalendarStudioProjectThemes.of(project);
    final draft = await Navigator.of(context).push<StudioSettingsDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CalendarStudioProjectSettingsPage(
          projectName: project.name,
          pageCount: project.pages.length,
          originalTheme: theme,
          initial: StudioSettingsDraft(
            source: project.source,
            theme: theme,
            width: canvas.width,
            height: canvas.height,
            bleed: canvas.bleed > 0,
            safeInset: canvas.safeInset,
            output: project.defaultExportPreset,
          ),
          onSaveFile: () => _exportProjectFile(
            controller.project!,
            CalendarStudioExportDestination.save,
          ),
          onShareFile: () => _exportProjectFile(
            controller.project!,
            CalendarStudioExportDestination.share,
          ),
          onSaveTemplate: widget.configuration.templates == null
              ? null
              : () => _saveAsTemplate(
                  controller.project!,
                  page: controller.pageIndex,
                ),
        ),
      ),
    );
    if (draft != null && mounted) _applySettings(draft);
  }

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
        final wide = box.maxWidth >= _desktopWidth;
        final canvas = _canvas(context, project);
        final workspace = wide
            ? Row(
                children: [
                  SizedBox(width: 72, child: _tools(vertical: true)),
                  const VerticalDivider(width: 1, thickness: 1),
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
                onPressed: controller.canUndo ? _undo : null,
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
              final Size(:width, :height) = _pageSizeIn(constraints);
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
                                selectedBlockIds: controller.selectedBlockIds
                                    .toSet(),
                                showSafeArea: safeArea,
                                onSelect: _selectBlock,
                                onToggleSelect: (block) {
                                  _endTextEdit();
                                  controller.toggleSelection(block.id);
                                },
                                onGroupMove: _spacePanning
                                    ? null
                                    : _moveSelection,
                                onMarquee: _spacePanning ? null : _selectInRect,
                                editingBlockId: _editingTextId,
                                onTextChanged: _typeText,
                                onTextDone: _endTextEdit,
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
        if (controller.selectedBlockIds.isNotEmpty)
          Positioned.fill(child: _contextualBar(project)),
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

  /// The page's fitted size on the board before zoom.
  Size _pageSizeIn(BoxConstraints constraints) {
    final availableWidth = (constraints.maxWidth - 56).clamp(
      120.0,
      double.infinity,
    );
    final availableHeight = (constraints.maxHeight - 76).clamp(
      120.0,
      double.infinity,
    );
    final ratio = controller.currentPage.canvas.aspectRatio;
    final width = (availableHeight * ratio).clamp(120.0, availableWidth);
    return Size(width, width / ratio);
  }

  /// The contextual bar, floating above the selection on screen (below it
  /// when there's no room), following zoom and pan. Hidden mid-drag.
  Widget _contextualBar(CalendarStudioProject project) => LayoutBuilder(
    builder: (context, constraints) => ListenableBuilder(
      listenable: Listenable.merge([canvasController, _canvasListenable]),
      builder: (context, _) {
        final selection = controller.selectedBlocks;
        if (selection.isEmpty || controller.isInteracting) {
          return const SizedBox.shrink();
        }
        final area = constraints.biggest;
        final pageSize = _pageSizeIn(constraints);
        final page = Rect.fromCenter(
          center: area.center(Offset.zero),
          width: pageSize.width,
          height: pageSize.height,
        );
        Rect? anchor;
        for (final block in selection) {
          final rect = _screenRectOf(block, page);
          anchor = anchor?.expandToInclude(rect) ?? rect;
        }
        final single = selection.length == 1;
        return CustomSingleChildLayout(
          delegate: _AnchoredBarLayout(
            anchor: MatrixUtils.transformRect(canvasController.value, anchor!),
            // Leave room for the rotate handle above a single selection.
            gap: single && !selection.single.locked ? 52 : 12,
            minTop: 60,
          ),
          child: CalendarStudioContextualBar(
            selection: selection,
            theme: CalendarStudioProjectThemes.of(project),
            editingText: _editingTextId != null,
            actions: CalendarStudioBarActions(
              update: controller.updateBlock,
              editText: () => _startTextEdit(selection.last),
              openInspector: _openInspector,
              duplicate: controller.duplicateSelected,
              delete: _deleteSelectedWithUndo,
              arrange: controller.moveSelectedLayer,
              align: controller.alignSelected,
              distribute: controller.distributeSelected,
              applyToAllPages: project.pages.length > 1
                  ? () => _applyToAllPages(selection.last)
                  : null,
            ),
          ),
        );
      },
    ),
  );

  /// [block]'s rotated bounding box on the unzoomed board.
  static Rect _screenRectOf(CalendarStudioBlock block, Rect page) {
    final b = block.bounds;
    final rect = Rect.fromLTWH(
      page.left + b.left * page.width,
      page.top + b.top * page.height,
      b.width * page.width,
      b.height * page.height,
    );
    if (block.rotation == 0) return rect;
    final cos = math.cos(block.rotation).abs();
    final sin = math.sin(block.rotation).abs();
    return Rect.fromCenter(
      center: rect.center,
      width: rect.width * cos + rect.height * sin,
      height: rect.width * sin + rect.height * cos,
    );
  }

  void _deleteSelectedWithUndo() {
    final blocks = controller.selectedBlocks;
    if (blocks.isEmpty) return;
    _endTextEdit();
    controller.deleteSelected();
    setState(() => _inspectorVisible = false);
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.toast(
      blocks.length == 1
          ? '${blocks.single.name} deleted'
          : '${blocks.length} items deleted',
      actionLabel: 'Undo',
      onAction: controller.undo,
    );
  }

  /// Add, Text, Image, Elements, Layers and Page: a bottom bar on phones
  /// and tablets, a strip down the left edge on wide screens (where the
  /// layers panel is already open, so Layers is left out).
  Widget _tools({bool vertical = false}) {
    final tools = [
      _StudioTool(
        key: const ValueKey('calendar-studio-tool-add'),
        icon: Icons.add,
        label: 'Add',
        onTap: () => _showAdd(context),
        expand: !vertical,
      ),
      _StudioTool(
        key: const ValueKey('calendar-studio-tool-text'),
        icon: Icons.text_fields,
        label: 'Text',
        onTap: () => controller.addBlock(CalendarStudioBlockType.text),
        expand: !vertical,
      ),
      _StudioTool(
        key: const ValueKey('calendar-studio-tool-image'),
        icon: Icons.image_outlined,
        label: 'Image',
        onTap: () => _pickAsset(CalendarStudioBlockType.image),
        expand: !vertical,
      ),
      _StudioTool(
        key: const ValueKey('calendar-studio-tool-elements'),
        icon: Icons.interests_outlined,
        label: 'Elements',
        onTap: () => _showElements(context),
        expand: !vertical,
      ),
      if (!vertical)
        _StudioTool(
          icon: Icons.layers_outlined,
          label: 'Layers',
          onTap: () => _showLayers(context),
        ),
      _StudioTool(
        key: const ValueKey('calendar-studio-tool-page'),
        icon: Icons.view_carousel_outlined,
        label: 'Page',
        onTap: () => _showPageOptions(context),
        expand: !vertical,
      ),
    ];
    final tokens = CalendarStudioTokens.of(context);
    if (vertical) {
      return Material(
        color: tokens.surface,
        child: Column(
          children: [
            const SizedBox(height: 8),
            for (final tool in tools) SizedBox(height: 64, child: tool),
          ],
        ),
      );
    }
    return Material(
      color: tokens.surface,
      child: SizedBox(height: 60, child: Row(children: tools)),
    );
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

  /// Colours picked in this session, newest first, offered in every colour
  /// field.
  final _recentColors = <int>[];

  StudioInspectorHost _inspectorHost(CalendarStudioProject project) =>
      StudioInspectorHost(
        controller: controller,
        theme: CalendarStudioProjectThemes.of(project),
        recentColors: List.unmodifiable(_recentColors),
        rememberColor: (color) {
          _recentColors
            ..remove(color)
            ..insert(0, color);
          if (_recentColors.length > 8) _recentColors.removeLast();
        },
        designSize: CalendarStudioScene.designSizeFor(
          controller.currentPage.canvas,
        ),
        replaceImage: (block) => _pickAsset(block.type, replace: block),
        revertImage: _revertImage,
        editImage: widget.configuration.imageEditor == null ? null : _editImage,
        removeBackground: _canRemoveBackground ? _removeBackground : null,
        suggestText: _canSuggestText ? _suggestText : null,
        textFieldRevision: _textFieldRevision,
        editOnPage: _startTextEdit,
        applyToAllPages: project.pages.length > 1
            ? (block, {layout = false}) =>
                  _applyToAllPages(block, layout: layout)
            : null,
      );

  Widget _inspector({ScrollController? scrollController, bool sheet = false}) {
    final block = controller.selectedBlocks.lastOrNull;
    if (block == null || controller.selectedBlockIds.length > 1) {
      return Material(
        child: Center(
          child: Text(
            block == null
                ? 'Select a block to edit'
                : StudioStrings.selected(controller.selectedBlockIds.length),
          ),
        ),
      );
    }
    return CalendarStudioInspector(
      key: ValueKey('calendar-studio-inspector-body-${block.id}'),
      block: block,
      host: _inspectorHost(controller.project!),
      tab: calendarInspectorTab,
      onTab: (value) => setState(() => calendarInspectorTab = value),
      onClose: () => setState(() => _inspectorVisible = false),
      onDelete: _deleteSelectedWithUndo,
      scrollController: scrollController,
      sheet: sheet,
    );
  }

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
        shift ? controller.redo() : _undo();
      } else if (key == LogicalKeyboardKey.keyY) {
        controller.redo();
      } else if (key == LogicalKeyboardKey.keyD) {
        controller.duplicateSelected();
      } else if (key == LogicalKeyboardKey.keyA) {
        controller.selectAll();
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
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final selected = controller.selectedBlocks;
      if (selected.length != 1 ||
          selected.single.type != CalendarStudioBlockType.text ||
          selected.single.locked) {
        return KeyEventResult.ignored;
      }
      _startTextEdit(selected.single);
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

  /// Items added in this session, newest first, for the Recent tab.
  final _recentAdds = <StudioAddItem>[];

  void _showAdd(BuildContext context, {StudioAddTab tab = StudioAddTab.text}) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => FractionallySizedBox(
          heightFactor: _sheetHeight,
          child: CalendarStudioAddPanel(
            theme: CalendarStudioProjectThemes.of(controller.project!),
            page: controller.currentPage,
            recent: List.unmodifiable(_recentAdds),
            initialTab: tab,
            onClose: () => Navigator.pop(sheetContext),
            onAdd: (item) {
              Navigator.pop(sheetContext);
              _addItem(item);
            },
          ),
        ),
      );

  Future<void> _showElements(BuildContext context) async =>
      _showAdd(context, tab: StudioAddTab.elements);

  void _addItem(StudioAddItem item) {
    _recentAdds
      ..removeWhere((value) => value.id == item.id)
      ..insert(0, item);
    if (_recentAdds.length > 12) _recentAdds.removeLast();
    _endTextEdit();
    if (item.pick) {
      _pickAsset(item.type);
      return;
    }
    controller.addBlock(
      item.type,
      name: item.id.startsWith('emoji-') ? 'Emoji' : item.label,
      bounds: item.bounds,
      content: item.content,
      style: item.style,
    );
  }

  /// The current page: its background, print margins and editing guides.
  /// Page size and theme live in Project settings.
  void _showPageOptions(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * _sheetHeight,
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (_, setSheet) {
        final canvas = controller.currentPage.canvas;
        final host = _inspectorHost(controller.project!);
        void edit(StudioCanvas next) {
          controller.updateCurrentCanvas(next);
          setSheet(() {});
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Page settings',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Done'),
                    ),
                  ],
                ),
                Text(
                  '${controller.currentPage.label} · '
                  '${StudioPageSize.of(canvas)?.label ?? '${canvas.width.round()} × ${canvas.height.round()}'}',
                ),
                StudioSection(
                  title: 'Background',
                  children: [
                    StudioColorField(
                      id: 'page-background',
                      label: 'Page colour',
                      value: canvas.backgroundColor,
                      host: host,
                      pageColors: host.pageColors(controller.currentPage),
                      onChanged: (color) =>
                          edit(canvas.copyWith(backgroundColor: color)),
                    ),
                  ],
                ),
                StudioSection(
                  title: 'Print',
                  children: [
                    StudioSwitch(
                      label: 'Bleed',
                      subtitle: '3 mm extra edge for trimming',
                      value: canvas.bleed > 0,
                      onChanged: (value) =>
                          edit(canvas.copyWith(bleed: value ? 3 : 0)),
                    ),
                    StudioStepper(
                      label: 'Safe margin',
                      unit: '%',
                      value: canvas.safeInset * 100,
                      max: 12,
                      onChanged: (value) =>
                          edit(canvas.copyWith(safeInset: value / 100)),
                    ),
                  ],
                ),
                StudioSection(
                  title: 'While editing',
                  children: [
                    StudioSwitch(
                      label: 'Show safe area',
                      subtitle: 'Keep important content inside the guide',
                      value: safeArea,
                      onChanged: (value) {
                        setState(() => safeArea = value);
                        setSheet(() {});
                      },
                    ),
                    StudioSwitch(
                      label: 'Snap to grid',
                      value: snapToGrid,
                      onChanged: (value) {
                        setState(() => snapToGrid = value);
                        setSheet(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const ValueKey('studio-page-project-settings'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _showProjectSettings();
                  },
                  icon: const Icon(Icons.tune),
                  label: const Text('Page size, theme and calendar'),
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
    CalendarStudioImageSource? chosen;
    await showAppActionSheet(
      context: context,
      title: 'Choose image',
      message:
          "A copy is kept inside the app, so moving or deleting the original "
          "won't change your calendar.",
      actions: [
        for (final source in sources)
          AppMenuAction(
            label: switch (source) {
              CalendarStudioImageSource.gallery => 'Gallery',
              CalendarStudioImageSource.camera => 'Camera',
              CalendarStudioImageSource.files => 'Files',
            },
            icon: switch (source) {
              CalendarStudioImageSource.gallery => Icons.photo_library_outlined,
              CalendarStudioImageSource.camera => Icons.photo_camera_outlined,
              CalendarStudioImageSource.files => Icons.folder_outlined,
            },
            onSelected: () => chosen = source,
          ),
      ],
    );
    return chosen;
  }

  Future<void> _pickAsset(
    CalendarStudioBlockType type, {
    CalendarStudioBlock? replace,
  }) async {
    final store = _assets;
    if (store == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).toast(
          'Image storage is not configured.',
          kind: StudioToastKind.error,
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
        messenger.toast(
          'Large image resized to ${prepared.width} × ${prepared.height} px '
          '— still sharp for print.',
        );
      }
    } on CalendarStudioUnsupportedImageException {
      messenger.toast(
        "That file isn't an image Studio can use.",
        kind: StudioToastKind.error,
      );
      return;
    } catch (_) {
      messenger.toast(
        "Couldn't add the image. Try again.",
        kind: StudioToastKind.error,
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
      messenger.toast(
        "The original image couldn't be found.",
        kind: StudioToastKind.error,
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
      messenger.toast(
        "Couldn't save the edited image.",
        kind: StudioToastKind.error,
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
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: widget.configuration.chrome == CalendarStudioChrome.clear
              ? const CupertinoAlertDialog(
                  content: Column(
                    children: [
                      CupertinoActivityIndicator(radius: 13),
                      SizedBox(height: 12),
                      Text('Removing background…'),
                    ],
                  ),
                )
              : const AlertDialog(
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
      messenger.toast(failure ?? '', kind: StudioToastKind.error);
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
          templateName: _templateById(project.templateId).name,
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
        builder: (context, box) => box.maxWidth >= _desktopWidth
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

  /// Export sheet for [project] (the open project by default).
  /// [currentPage] preselects "This page"; null starts with all pages.
  Future<void> _showExport(
    BuildContext context, {
    CalendarStudioProject? project,
    int? currentPage,
    bool fromEditor = true,
  }) async {
    final target = project ?? controller.project!;
    final request = await showModalBottomSheet<_ExportRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExportSheet(
        initialPreset: target.defaultExportPreset.copyWith(
          fileName: _safeFileName(target.name),
        ),
        pages: target.pages,
        currentPage: currentPage ?? (fromEditor ? controller.pageIndex : null),
        blockedPages: _pagesWithErrors(target),
      ),
    );
    if (request != null && mounted) {
      await _runExport(
        target,
        request.preset,
        request.destination,
        pageIndexes: request.pageIndexes,
      );
    }
  }

  Set<int> _pagesWithErrors(CalendarStudioProject project) => {
    for (final issue in CalendarStudioPreflight.check(project))
      if (issue.severity == CalendarStudioIssueSeverity.error)
        project.pages.indexWhere((page) => page.id == issue.pageId),
  }..remove(-1);

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
      ScaffoldMessenger.of(context).toast(
        'No export destination is configured.',
        kind: StudioToastKind.error,
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
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.expand = true,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Share a horizontal bar's width; false in the wide layout's strip.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    final button = Tooltip(
      message: label,
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
    return expand ? Expanded(child: button) : button;
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

/// Asks for a new name. Owns its text controller, so it is disposed only
/// after the dialog has finished closing.
/// Swipeable sample months with page dots (preset detail).
class _PresetCarousel extends StatefulWidget {
  const _PresetCarousel({required this.children});
  final List<Widget> children;

  @override
  State<_PresetCarousel> createState() => _PresetCarouselState();
}

class _PresetCarouselState extends State<_PresetCarousel> {
  final _controller = PageController(viewportFraction: .78);
  var _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: PageView(
          controller: _controller,
          onPageChanged: (value) => setState(() => _page = value),
          children: [
            for (final child in widget.children)
              Padding(padding: const EdgeInsets.all(6), child: child),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 6,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == _page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _page
                    ? Theme.of(context).colorScheme.primary
                    : CalendarStudioTokens.of(context).surface3,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    ],
  );
}

/// The dashboard's shape while projects load: the continue card, the
/// filters and a grid of cards, each sweeping with light.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final count = box.maxWidth >= _desktopWidth
          ? 4
          : (box.maxWidth >= _tabletWidth ? 3 : 2);
      return ExcludeSemantics(
        child: IgnorePointer(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 150, child: StudioShimmer(radius: 12)),
              const SizedBox(height: 16),
              const Row(
                spacing: 8,
                children: [
                  StudioShimmer(width: 52, height: 32, radius: 8),
                  StudioShimmer(width: 60, height: 32, radius: 8),
                  StudioShimmer(width: 60, height: 32, radius: 8),
                  StudioShimmer(width: 66, height: 32, radius: 8),
                ],
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: StudioShimmer(width: 140, height: 22, radius: 6),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: .68,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (var i = 0; i < count * 3; i++)
                    const StudioShimmer(radius: 12),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Places the contextual bar centred above [anchor], or below it when the
/// space above is taken by the page switcher, always inside the board.
class _AnchoredBarLayout extends SingleChildLayoutDelegate {
  const _AnchoredBarLayout({
    required this.anchor,
    required this.gap,
    required this.minTop,
  });
  final Rect anchor;
  final double gap;
  final double minTop;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: math.max(0, constraints.maxWidth - 16));

  @override
  Offset getPositionForChild(Size size, Size child) {
    var top = anchor.top - gap - child.height;
    if (top < minTop) top = anchor.bottom + 12;
    final maxTop = math.max(8.0, size.height - child.height - 8);
    final maxLeft = math.max(8.0, size.width - child.width - 8);
    return Offset(
      (anchor.center.dx - child.width / 2).clamp(8.0, maxLeft),
      top.clamp(8.0, maxTop),
    );
  }

  @override
  bool shouldRelayout(_AnchoredBarLayout oldDelegate) =>
      anchor != oldDelegate.anchor ||
      gap != oldDelegate.gap ||
      minTop != oldDelegate.minTop;
}
