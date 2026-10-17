import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../models/calendar_studio_user_template.dart';
import '../templates/calendar_studio_templates.dart';
import 'calendar_studio_contracts.dart';

enum CalendarStudioSaveState { saved, saving, failed }

class CalendarStudioController extends ChangeNotifier {
  CalendarStudioController(this.configuration);
  final CalendarStudioConfiguration configuration;
  CalendarStudioProject? _project;
  CalendarStudioProject? get project => _project;
  CalendarStudioSaveState saveState = CalendarStudioSaveState.saved;
  String? selectedBlockId;
  int pageIndex = 0;

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
    final id = selectedBlockId;
    if (id == null) return;
    _edit(
      (page) => page.copyWith(
        blocks: page.blocks.where((block) => block.id != id).toList(),
      ),
    );
    selectedBlockId = null;
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
    final selected = _selectedBlock;
    if (selected == null) return;
    final id = '${selected.type.name}-${DateTime.now().microsecondsSinceEpoch}';
    final bounds = selected.bounds;
    final copy = CalendarStudioBlock(
      id: id,
      type: selected.type,
      name: '${selected.name} copy',
      bounds: bounds.copyWith(
        left: (bounds.left + .02).clamp(0, 1 - bounds.width),
        top: (bounds.top + .02).clamp(0, 1 - bounds.height),
      ),
      rotation: selected.rotation,
      zIndex: currentPage.blocks.length,
      visible: selected.visible,
      locked: false,
      style: selected.style,
      content: selected.content,
    );
    _edit((page) => page.copyWith(blocks: [...page.blocks, copy]));
    selectedBlockId = id;
    notifyListeners();
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
