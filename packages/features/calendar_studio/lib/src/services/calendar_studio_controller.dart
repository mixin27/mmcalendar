import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_project_theme.dart';
import '../models/calendar_studio_types.dart';
import '../models/calendar_studio_user_template.dart';
import '../templates/calendar_studio_templates.dart';
import 'calendar_studio_arrange.dart';
import 'calendar_studio_contracts.dart';

enum CalendarStudioSaveState { saved, saving, failed }

class CalendarStudioController extends ChangeNotifier {
  CalendarStudioController(this.configuration);
  final CalendarStudioConfiguration configuration;
  CalendarStudioProject? _project;
  CalendarStudioProject? get project => _project;
  CalendarStudioSaveState saveState = CalendarStudioSaveState.saved;
  int pageIndex = 0;

  /// Selected block ids in the order they were picked; the last is the
  /// primary selection that the toolbar and inspector edit.
  List<String> _selection = const [];
  List<String> get selectedBlockIds => _selection;
  String? get selectedBlockId => _selection.isEmpty ? null : _selection.last;
  set selectedBlockId(String? id) => _selection = id == null ? const [] : [id];
  bool isSelected(String id) => _selection.contains(id);

  /// The selected blocks on the current page, in page order.
  List<CalendarStudioBlock> get selectedBlocks {
    if (_project == null || _selection.isEmpty) return const [];
    return [
      for (final block in currentPage.blocks)
        if (_selection.contains(block.id)) block,
    ];
  }

  /// The user's saved templates, as gallery entries; set by the workspace.
  List<CalendarStudioTemplate> userTemplates = const [];

  /// The built-in or user template with [id]; null when a user template was
  /// deleted after projects were made from it.
  CalendarStudioTemplate? templateOf(String id) {
    for (final template in userTemplates) {
      if (template.id == id) return template;
    }
    if (CalendarStudioUserTemplate.isUserTemplateId(id)) return null;
    return CalendarStudioTemplates.byId(id);
  }

  final List<CalendarStudioProject> _undo = [];
  final List<CalendarStudioProject> _redo = [];
  CalendarStudioProject? _interactionStart;
  final _canvasRevision = ValueNotifier<int>(0);
  Timer? _saveTimer;

  /// Maximum undo steps kept; each step is a full project snapshot.
  static const historyLimit = 100;

  /// Notifies on every live transform frame. Only the canvas listens to this,
  /// so a drag does not rebuild the inspector, layers panel or app bar; those
  /// refresh once through [notifyListeners] when the interaction ends.
  late final Listenable canvasChanges = Listenable.merge([
    this,
    _canvasRevision,
  ]);

  bool get isInteracting => _interactionStart != null;

  /// The block as it was when the current interaction began, so snapping can
  /// be applied to raw gesture output instead of compounding per frame.
  CalendarStudioBlock? interactionStartBlock(String id) {
    final start = _interactionStart;
    if (start == null || pageIndex >= start.pages.length) return null;
    for (final block in start.pages[pageIndex].blocks) {
      if (block.id == id) return block;
    }
    return null;
  }

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  CalendarStudioPage get currentPage => _project!.pages[pageIndex];

  Future<void> open(CalendarStudioProject project) async {
    _project = project;
    pageIndex = 0;
    selectedBlockId = null;
    notifyListeners();
  }

  Future<CalendarStudioProject> create(
    String templateId,
    CalendarStudioSource source,
  ) async {
    final now = configuration.now?.call() ?? DateTime.now();
    final template =
        templateOf(templateId) ?? CalendarStudioTemplates.byId('blank');
    final project = template.create(
      id: now.microsecondsSinceEpoch.toString(),
      source: source,
      now: now,
    );
    await configuration.projects.save(project);
    await open(project);
    return project;
  }

  void select(String? id) {
    selectedBlockId = id;
    notifyListeners();
  }

  /// Adds [id] to the selection, or removes it when already selected
  /// (Shift-click, or long-press then tap on touch).
  void toggleSelection(String id) {
    _selection = _selection.contains(id)
        ? [..._selection.where((value) => value != id)]
        : [..._selection, id];
    notifyListeners();
  }

  /// Replaces the selection, for marquee drags and Select all.
  void selectMany(Iterable<String> ids) {
    _selection = [...ids];
    notifyListeners();
  }

  void selectAll() => selectMany([
    for (final block in currentPage.blocks)
      if (block.visible && !block.locked) block.id,
  ]);

  int _groupDepth = 0;
  bool _groupRecorded = false;

  /// Edits between [beginEditGroup] and [endEditGroup] (a typing session,
  /// a run of stepper taps) share one undo step.
  void beginEditGroup() {
    if (_groupDepth++ == 0) _groupRecorded = false;
  }

  void endEditGroup() {
    if (_groupDepth == 0) return;
    _groupDepth--;
  }

  void setPage(int index) {
    pageIndex = index.clamp(0, _project!.pages.length - 1);
    selectedBlockId = null;
    notifyListeners();
  }

  void updateSource(CalendarStudioSource source) {
    final value = _project;
    if (value == null || value.source == source) return;
    _pushUndo(value);
    _project = value.copyWith(
      source: source,
      updatedAt: configuration.now?.call() ?? DateTime.now(),
    );
    notifyListeners();
    _scheduleSave();
  }

  /// The theme the project uses now (stored, or derived for older projects).
  CalendarStudioProjectTheme? get theme {
    final value = _project;
    return value == null ? null : CalendarStudioProjectThemes.of(value);
  }

  /// Recolours every page from the current theme to [next] as one undo step.
  void applyTheme(CalendarStudioProjectTheme next) {
    final value = _project;
    if (value == null) return;
    final current = CalendarStudioProjectThemes.of(value);
    if (current == next && value.theme == next) return;
    _pushUndo(value);
    _project = CalendarStudioRetheme.apply(
      value,
      current,
      next,
    ).copyWith(updatedAt: configuration.now?.call() ?? DateTime.now());
    notifyListeners();
    _scheduleSave();
  }

  /// Applies project-level calendar settings and refreshes template-owned
  /// data without discarding user-added or customized layers.
  void updateConfiguration(CalendarStudioSource source) {
    final value = _project;
    if (value == null || value.source == source) return;
    final template = templateOf(value.templateId);
    if (template == null) {
      // The template is gone, so its pages can't be regenerated; keep the
      // design and change only the calendar settings.
      updateSource(source);
      return;
    }
    final now = configuration.now?.call() ?? DateTime.now();
    final previousDefaults = template.create(
      id: value.id,
      source: value.source,
      now: value.createdAt,
    );
    final refreshed = template.create(
      id: value.id,
      source: source,
      now: value.createdAt,
    );
    final pages = <CalendarStudioPage>[];
    for (var index = 0; index < refreshed.pages.length; index++) {
      final freshPage = refreshed.pages[index];
      final oldPage = index < value.pages.length ? value.pages[index] : null;
      final oldDefaults = index < previousDefaults.pages.length
          ? previousDefaults.pages[index]
          : null;
      if (oldPage == null || oldDefaults == null) {
        pages.add(freshPage);
        continue;
      }
      final defaultIds = oldDefaults.blocks.map((block) => block.id).toSet();
      final oldById = {for (final block in oldPage.blocks) block.id: block};
      final oldDefaultById = {
        for (final block in oldDefaults.blocks) block.id: block,
      };
      final templateBlocks = <CalendarStudioBlock>[
        for (final freshBlock in freshPage.blocks)
          if (oldById[freshBlock.id] case final oldBlock?)
            oldBlock.copyWith(
              content:
                  mapEquals(
                    oldBlock.content,
                    oldDefaultById[freshBlock.id]?.content,
                  )
                  ? freshBlock.content
                  : oldBlock.content,
            )
          else
            freshBlock,
      ];
      pages.add(
        freshPage.copyWith(
          canvas: oldPage.canvas,
          blocks: [
            ...templateBlocks,
            ...oldPage.blocks.where((block) => !defaultIds.contains(block.id)),
          ],
        ),
      );
    }
    _pushUndo(value);
    _project = value.copyWith(
      name: value.name == previousDefaults.name ? refreshed.name : value.name,
      source: source,
      pages: pages,
      updatedAt: now,
    );
    pageIndex = pageIndex.clamp(0, pages.length - 1);
    selectedBlockId = null;
    notifyListeners();
    _scheduleSave();
  }

  /// Records the latest export; like export settings, not an undoable edit.
  void recordExport(CalendarStudioExportRecord record) {
    final value = _project;
    if (value == null) return;
    _project = value.copyWith(lastExport: record);
    notifyListeners();
    _scheduleSave();
  }

  /// Export settings aren't design edits, so this skips undo history.
  void updateDefaultExportPreset(CalendarStudioExportPreset preset) {
    final value = _project;
    if (value == null || value.defaultExportPreset == preset) return;
    _project = value.copyWith(defaultExportPreset: preset);
    _scheduleSave();
  }

  void updateCurrentCanvas(StudioCanvas canvas) {
    if (currentPage.canvas == canvas) return;
    _edit((page) => page.copyWith(canvas: canvas));
  }

  void updateBlock(CalendarStudioBlock block) => _edit(
    (page) => page.copyWith(
      blocks: [
        for (final value in page.blocks)
          if (value.id == block.id) block else value,
      ],
    ),
  );

  void beginBlockInteraction() {
    _interactionStart ??= _project;
  }

  /// Continuous inspector controls (sliders) record one undo step per gesture
  /// between [beginBlockInteraction] and [endBlockInteraction]. The whole
  /// workspace refreshes so the control itself tracks the value.
  void updateBlockLive(CalendarStudioBlock block) {
    if (_interactionStart == null) return updateBlock(block);
    updateBlockDuringInteraction(block, canvasOnly: false);
  }

  void updateBlockDuringInteraction(
    CalendarStudioBlock block, {
    bool canvasOnly = true,
  }) {
    final value = _project;
    if (value == null) return;
    final page = currentPage;
    final updatedPage = page.copyWith(
      blocks: [
        for (final current in page.blocks)
          if (current.id == block.id) block else current,
      ],
    );
    _project = value.copyWith(
      pages: [
        for (var i = 0; i < value.pages.length; i++)
          if (i == pageIndex) updatedPage else value.pages[i],
      ],
    );
    if (_interactionStart == null || !canvasOnly) {
      notifyListeners();
    } else {
      _canvasRevision.value++;
    }
  }

  void endBlockInteraction() {
    final start = _interactionStart;
    _interactionStart = null;
    final value = _project;
    if (start == null || value == null || start == value) return;
    _project = value.copyWith(
      updatedAt: configuration.now?.call() ?? DateTime.now(),
    );
    _pushUndo(start);
    notifyListeners();
    _scheduleSave();
  }

  void cancelBlockInteraction() {
    final start = _interactionStart;
    _interactionStart = null;
    if (start == null) return;
    _project = start;
    notifyListeners();
  }

  void deleteSelected() {
    final ids = _selection.toSet();
    if (ids.isEmpty) return;
    _edit(
      (page) => page.copyWith(
        blocks: page.blocks.where((block) => !ids.contains(block.id)).toList(),
      ),
    );
    selectedBlockId = null;
    notifyListeners();
  }

  /// Several blocks changed as one undo step (group move, align).
  void updateBlocks(Iterable<CalendarStudioBlock> blocks) {
    final byId = {for (final block in blocks) block.id: block};
    if (byId.isEmpty) return;
    _edit(
      (page) => page.copyWith(
        blocks: [for (final value in page.blocks) byId[value.id] ?? value],
      ),
    );
  }

  /// Live frames of a group drag; pair with [beginBlockInteraction].
  void updateBlocksDuringInteraction(Iterable<CalendarStudioBlock> blocks) {
    final value = _project;
    if (value == null) return;
    final byId = {for (final block in blocks) block.id: block};
    final page = currentPage;
    _project = value.copyWith(
      pages: [
        for (var i = 0; i < value.pages.length; i++)
          if (i == pageIndex)
            page.copyWith(
              blocks: [for (final b in page.blocks) byId[b.id] ?? b],
            )
          else
            value.pages[i],
      ],
    );
    if (_interactionStart == null) {
      notifyListeners();
    } else {
      _canvasRevision.value++;
    }
  }

  void alignSelected(CalendarStudioAlign edge) {
    final blocks = selectedBlocks;
    if (blocks.isEmpty) return;
    updateBlocks(CalendarStudioArrange.align(blocks, edge));
  }

  void distributeSelected(CalendarStudioDistribute axis) {
    final blocks = selectedBlocks;
    if (blocks.length < 3) return;
    updateBlocks(CalendarStudioArrange.distribute(blocks, axis));
  }

  void renameBlock(String id, String name) {
    final trimmed = name.trim();
    final block = currentPage.blocks.where((b) => b.id == id).firstOrNull;
    if (block == null || trimmed.isEmpty || block.name == trimmed) return;
    updateBlock(block.copyWith(name: trimmed));
  }

  /// Moves block [id] to position [index] in back-to-front order, as the
  /// layers list drags it.
  void reorderLayer(String id, int index) {
    final ordered = [...currentPage.blocks]
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final from = ordered.indexWhere((block) => block.id == id);
    if (from < 0) return;
    final to = index.clamp(0, ordered.length - 1);
    if (from == to) return;
    ordered.insert(to, ordered.removeAt(from));
    _edit(
      (page) => page.copyWith(
        blocks: [
          for (var i = 0; i < ordered.length; i++)
            ordered[i].copyWith(zIndex: i),
        ],
      ),
    );
  }

  /// Copies [block]'s style (and its size and place when [layout]) to the
  /// block with the same id on every other page. Returns how many pages
  /// changed.
  int applyToAllPages(CalendarStudioBlock block, {bool layout = false}) {
    final value = _project;
    if (value == null) return 0;
    var changed = 0;
    final pages = [
      for (final page in value.pages)
        page.copyWith(
          blocks: [
            for (final b in page.blocks)
              if (b.id == block.id &&
                  (!mapEquals(b.style, block.style) ||
                      (layout && b.bounds != block.bounds)))
                () {
                  changed++;
                  return b.copyWith(
                    style: block.style,
                    bounds: layout ? block.bounds : null,
                    rotation: layout ? block.rotation : null,
                  );
                }()
              else
                b,
          ],
        ),
    ];
    if (changed == 0) return 0;
    _pushUndo(value);
    _project = value.copyWith(
      pages: pages,
      updatedAt: configuration.now?.call() ?? DateTime.now(),
    );
    notifyListeners();
    _scheduleSave();
    return changed;
  }

  String addBlock(
    CalendarStudioBlockType type, {
    String? name,
    StudioRect? bounds,
    Map<String, Object?> content = const {},
    Map<String, Object?> style = const {},
  }) {
    final id = '${type.name}-${DateTime.now().microsecondsSinceEpoch}';
    _edit(
      (page) => page.copyWith(
        blocks: [
          ...page.blocks,
          CalendarStudioBlock(
            id: id,
            type: type,
            name: name ?? _label(type),
            bounds:
                bounds ??
                const StudioRect(left: .15, top: .15, width: .7, height: .16),
            zIndex: page.blocks.length,
            content: type == CalendarStudioBlockType.text && content.isEmpty
                ? const {'text': 'New text'}
                : content,
            style: style,
          ),
        ],
      ),
    );
    selectedBlockId = id;
    notifyListeners();
    return id;
  }

  void duplicateSelected() {
    final selected = selectedBlocks;
    if (selected.isEmpty) return;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final copies = [
      for (var i = 0; i < selected.length; i++)
        _copyOf(selected[i], '${selected[i].type.name}-$stamp-$i', i),
    ];
    _edit((page) => page.copyWith(blocks: [...page.blocks, ...copies]));
    _selection = [for (final copy in copies) copy.id];
    notifyListeners();
  }

  CalendarStudioBlock _copyOf(CalendarStudioBlock block, String id, int i) {
    final bounds = block.bounds;
    return CalendarStudioBlock(
      id: id,
      type: block.type,
      name: '${block.name} copy',
      bounds: bounds.copyWith(
        left: (bounds.left + .02).clamp(0, 1 - bounds.width),
        top: (bounds.top + .02).clamp(0, 1 - bounds.height),
      ),
      rotation: block.rotation,
      zIndex: currentPage.blocks.length + i,
      visible: block.visible,
      locked: false,
      style: block.style,
      content: block.content,
    );
  }

  void moveSelectedLayer(int delta) {
    final selected = _selectedBlock;
    if (selected == null) return;
    final ordered = [...currentPage.blocks]
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final from = ordered.indexWhere((block) => block.id == selected.id);
    final to = (from + delta).clamp(0, ordered.length - 1);
    if (from == to) return;
    final moved = ordered.removeAt(from);
    ordered.insert(to, moved);
    _edit(
      (page) => page.copyWith(
        blocks: [
          for (var i = 0; i < ordered.length; i++)
            ordered[i].copyWith(zIndex: i),
        ],
      ),
    );
  }

  CalendarStudioBlock? get _selectedBlock {
    final id = selectedBlockId;
    if (id == null || _project == null) return null;
    final matches = currentPage.blocks.where((block) => block.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  void _pushUndo(CalendarStudioProject value) {
    if (_groupDepth > 0) {
      if (_groupRecorded) return;
      _groupRecorded = true;
    }
    _undo.add(value);
    if (_undo.length > historyLimit) _undo.removeAt(0);
    _redo.clear();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_project!);
    _project = _undo.removeLast();
    notifyListeners();
    _scheduleSave();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_project!);
    _project = _redo.removeLast();
    notifyListeners();
    _scheduleSave();
  }

  void _edit(CalendarStudioPage Function(CalendarStudioPage) edit) {
    final value = _project;
    if (value == null) return;
    _pushUndo(value);
    _project = value.copyWith(
      pages: [
        for (var i = 0; i < value.pages.length; i++)
          if (i == pageIndex) edit(value.pages[i]) else value.pages[i],
      ],
      updatedAt: configuration.now?.call() ?? DateTime.now(),
    );
    notifyListeners();
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    saveState = CalendarStudioSaveState.saving;
    notifyListeners();
    _saveTimer = Timer(const Duration(milliseconds: 650), saveNow);
  }

  Future<void> saveNow() async {
    final value = _project;
    if (value == null) return;
    saveState = CalendarStudioSaveState.saving;
    notifyListeners();
    try {
      await configuration.projects.save(value);
      saveState = CalendarStudioSaveState.saved;
    } catch (_) {
      saveState = CalendarStudioSaveState.failed;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _canvasRevision.dispose();
    super.dispose();
  }
}

String _label(CalendarStudioBlockType type) => switch (type) {
  CalendarStudioBlockType.calendarGrid => 'Calendar grid',
  CalendarStudioBlockType.eventList => 'Event list',
  CalendarStudioBlockType.holidayLegend => 'Holiday legend',
  CalendarStudioBlockType.decoration => 'Decoration',
  _ => type.name[0].toUpperCase() + type.name.substring(1),
};
