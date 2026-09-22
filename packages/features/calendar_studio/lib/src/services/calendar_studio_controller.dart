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

  void updateBlock(CalendarStudioBlock block) => _edit(
    (page) => page.copyWith(
      blocks: [
        for (final value in page.blocks)
          if (value.id == block.id) block else value,
      ],
    ),
  );
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

  void addBlock(CalendarStudioBlockType type) {
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
