import 'dart:typed_data';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:pro_image_editor/pro_image_editor.dart';

/// Calendar Studio's "Edit image" backed by `pro_image_editor`.
///
/// Only photo tools that suit a print calendar are offered (crop & rotate,
/// tune, filters, blur); drawing, text, emoji and stickers stay in Studio's
/// own structured blocks. The edit history is returned as JSON so Studio can
/// reopen the original with the same edits applied.
class AppCalendarStudioImageEditor implements CalendarStudioImageEditor {
  const AppCalendarStudioImageEditor();

  @override
  Future<CalendarStudioEditedImage?> edit(
    BuildContext context, {
    required Uint8List original,
    String? editorState,
    required int maxDimension,
  }) => Navigator.of(context).push<CalendarStudioEditedImage>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _StudioImageEditorPage(
        original: original,
        editorState: editorState,
        maxDimension: maxDimension,
      ),
    ),
  );
}

class _StudioImageEditorPage extends StatefulWidget {
  const _StudioImageEditorPage({
    required this.original,
    required this.editorState,
    required this.maxDimension,
  });
  final Uint8List original;
  final String? editorState;
  final int maxDimension;

  @override
  State<_StudioImageEditorPage> createState() => _StudioImageEditorPageState();
}

class _StudioImageEditorPageState extends State<_StudioImageEditorPage> {
  final _editorKey = GlobalKey<ProImageEditorState>();
  late final bool _keepAlpha = CalendarStudioImageImport.mayHaveAlpha(
    widget.original,
  );
  late final ImportStateHistory? _history = _decodeHistory();
  CalendarStudioEditedImage? _result;

  ImportStateHistory? _decodeHistory() {
    final state = widget.editorState;
    if (state == null || state.isEmpty) return null;
    try {
      return ImportStateHistory.fromJson(state);
    } catch (_) {
      // Unreadable history (e.g. from an older editor) starts fresh.
      return null;
    }
  }

  Future<void> _complete(Uint8List bytes) async {
    String? state;
    try {
      final history = await _editorKey.currentState!.exportStateHistory(
        configs: const ExportEditorConfigs(
          historySpan: ExportHistorySpan.current,
          maxDecimalPlaces: 4,
        ),
      );
      state = await history.toJson();
    } catch (_) {
      // The image is still saved; it just can't be re-edited step by step.
    }
    _result = CalendarStudioEditedImage(bytes: bytes, editorState: state);
  }

  material_ui.ThemeData _theme(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return material_ui.ThemeData(
      useMaterial3: true,
      colorScheme: material_ui.ColorScheme.fromSeed(
        seedColor: const Color(0xFF0E6B5C),
        brightness: colors.brightness,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final limit = widget.maxDimension.toDouble();
    return ProImageEditor.memory(
      widget.original,
      key: _editorKey,
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: _complete,
        onCloseEditor: (_) {
          if (mounted) Navigator.of(context).pop(_result);
        },
      ),
      configs: ProImageEditorConfigs(
        theme: _theme(context),
        mainEditor: const MainEditorConfigs(
          tools: [
            SubEditorMode.cropRotate,
            SubEditorMode.tune,
            SubEditorMode.filter,
            SubEditorMode.blur,
          ],
        ),
        imageGeneration: ImageGenerationConfigs(
          // The default 2000 px cap would soften A4/A3 prints.
          maxOutputSize: Size(limit, limit),
          outputFormat: _keepAlpha ? OutputFormat.png : OutputFormat.jpg,
          jpegQuality: 92,
        ),
        stateHistory: StateHistoryConfigs(initStateHistory: _history),
      ),
    );
  }
}
