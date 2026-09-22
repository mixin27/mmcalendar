import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
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
  final List<CalendarStudioProject> _undo = [];
  final List<CalendarStudioProject> _redo = [];
  CalendarStudioProject? _interactionStart;
  Timer? _saveTimer;
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
    final template = CalendarStudioTemplates.byId(templateId);
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
    _undo.add(value);
    _redo.clear();
    _project = value.copyWith(
      source: source,
      updatedAt: configuration.now?.call() ?? DateTime.now(),
    );
    notifyListeners();
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

  void updateBlockDuringInteraction(CalendarStudioBlock block) {
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
      updatedAt: configuration.now?.call() ?? DateTime.now(),
    );
    notifyListeners();
  }

  void endBlockInteraction() {
    final start = _interactionStart;
    _interactionStart = null;
    if (start == null || start == _project) return;
    _undo.add(start);
    _redo.clear();
    _scheduleSave();
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

  String addBlock(CalendarStudioBlockType type) {
    final id = '${type.name}-${DateTime.now().microsecondsSinceEpoch}';
    _edit(
      (page) => page.copyWith(
        blocks: [
          ...page.blocks,
          CalendarStudioBlock(
            id: id,
            type: type,
            name: _label(type),
            bounds: const StudioRect(
              left: .15,
              top: .15,
              width: .7,
              height: .16,
            ),
            zIndex: page.blocks.length,
            content: type == CalendarStudioBlockType.text
                ? const {'text': 'New text'}
                : const {},
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
    _undo.add(value);
    _redo.clear();
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
