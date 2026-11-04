import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import 'day_note.dart';
import 'day_notes_repository.dart';

/// The note colour, for the row icon and the calendar's note mark.
const dayNoteColor = Color(0xFFE0A21B);

/// [date]'s note as a row, "Add a note" when there is none; tapping it
/// opens the editor. Nothing when notes aren't set up.
class DayNoteGroup extends StatelessWidget {
  const DayNoteGroup({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final notes = dayNotes;
    if (notes == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<DayNote?>(
      stream: notes.watchDay(date),
      builder: (context, snapshot) {
        final note = snapshot.data;
        return AppGroup(
          children: [
            note == null
                ? AppRow(
                    key: const ValueKey('day-note'),
                    icon: Icons.sticky_note_2_outlined,
                    iconColor: dayNoteColor,
                    title: l10n.noteAdd,
                    tone: AppRowTone.accent,
                    onTap: () => showDayNoteEditor(context, date),
                  )
                : AppRow(
                    key: const ValueKey('day-note'),
                    icon: Icons.sticky_note_2_outlined,
                    iconColor: dayNoteColor,
                    title: l10n.noteTitle,
                    subtitle: note.preview,
                    chevron: true,
                    onTap: () => showDayNoteEditor(context, date),
                  ),
          ],
        );
      },
    );
  }
}

/// Opens [date]'s note for writing. It saves when the sheet closes, and a
/// blank note is deleted.
Future<void> showDayNoteEditor(BuildContext context, DateTime date) async {
  final notes = dayNotes;
  if (notes == null) return;
  final existing = await notes.watchDay(date).first;
  if (!context.mounted) return;
  await showAppSheet<void>(
    context: context,
    title:
        '${context.calendarFormat.weekday(date, short: true)} '
        '${context.calendarFormat.dayMonth(date)}',
    cancelLabel: MaterialLocalizations.of(context).closeButtonLabel,
    // Above the tab bar, so the whole editor shows.
    useRootNavigator: true,
    builder: (_) => _NoteEditor(
      notes: notes,
      date: date,
      initialText: existing?.text ?? '',
    ),
  );
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({
    required this.notes,
    required this.date,
    required this.initialText,
  });

  final DayNotesRepository notes;
  final DateTime date;
  final String initialText;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    final text = _controller.text;
    if (text.trim() != widget.initialText.trim()) {
      widget.notes.save(widget.date, text);
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final yes = await showAppConfirm(
      context: context,
      title: l10n.noteDeleteQuestion,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!yes || !mounted) return;
    _controller.clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.tokens;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('day-note-field'),
            controller: _controller,
            autofocus: widget.initialText.isEmpty,
            minLines: 6,
            maxLines: 14,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: t.label, fontSize: 16, height: 1.4),
            decoration: InputDecoration(
              hintText: l10n.noteHint,
              filled: true,
              fillColor: t.fill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (widget.initialText.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppGroup(
              children: [
                AppRow(
                  key: const ValueKey('day-note-delete'),
                  title: l10n.noteDelete,
                  tone: AppRowTone.destructive,
                  onTap: _delete,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Builds with the days of [month] that have a note, watching them while
/// the month stays the same; an empty set when notes aren't set up.
class MonthNoteDays extends StatefulWidget {
  const MonthNoteDays({super.key, required this.month, required this.builder});

  final DateTime month;
  final Widget Function(BuildContext context, Set<DateTime> days) builder;

  @override
  State<MonthNoteDays> createState() => _MonthNoteDaysState();
}

class _MonthNoteDaysState extends State<MonthNoteDays> {
  Stream<Set<DateTime>>? _stream;
  Set<DateTime> _last = const {};

  @override
  void initState() {
    super.initState();
    _watch();
  }

  @override
  void didUpdateWidget(MonthNoteDays old) {
    super.didUpdateWidget(old);
    if (old.month.year != widget.month.year ||
        old.month.month != widget.month.month) {
      _watch();
    }
  }

  void _watch() {
    final m = widget.month;
    // The grid shows a few days either side of the month.
    _stream = dayNotes?.watchDays(
      DateTime(m.year, m.month - 1, 20),
      DateTime(m.year, m.month + 1, 12),
    );
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Set<DateTime>>(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasData) _last = snapshot.data!;
      return widget.builder(context, _last);
    },
  );
}
