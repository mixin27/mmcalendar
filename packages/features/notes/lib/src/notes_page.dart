import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import 'day_note.dart';
import 'day_notes_repository.dart';

/// Every day note, latest first and grouped by month, with search. A note
/// opens its day.
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  var _query = '';

  static bool _matches(DayNote note, String query) =>
      query.isEmpty || note.text.toLowerCase().contains(query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notes = dayNotes;
    final format = context.calendarFormat;
    final t = context.tokens;
    return StreamBuilder<List<DayNote>>(
      stream: notes?.watchAll(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <DayNote>[];
        final shown = all.where((n) => _matches(n, _query.trim())).toList();
        final months = <DateTime, List<DayNote>>{};
        for (final note in shown) {
          months
              .putIfAbsent(DateTime(note.date.year, note.date.month), () => [])
              .add(note);
        }
        Widget message(String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: t.secondaryLabel, fontSize: 15),
          ),
        );
        return AppPage(
          title: l10n.notesTitle,
          previousTitle: l10n.views,
          children: [
            if (all.isNotEmpty)
              AppSearchField(
                key: const ValueKey('notes-search'),
                placeholder: l10n.notesSearch,
                onChanged: (q) => setState(() => _query = q),
              ),
            if (snapshot.hasData && all.isEmpty)
              message(l10n.notesEmpty)
            else if (all.isNotEmpty && shown.isEmpty)
              message(l10n.notesNoMatches),
            for (final MapEntry(key: month, value: monthNotes)
                in months.entries)
              AppGroup(
                label: format.monthYear(month),
                children: [
                  for (final note in monthNotes)
                    AppRow(
                      key: ValueKey(
                        'note-${DayNotesRepository.keyOf(note.date)}',
                      ),
                      title:
                          '${format.weekday(note.date, short: true)} '
                          '${format.dayMonth(note.date)}',
                      value: format.myanmar(
                        MyanmarCalendar.getCompleteDateFor(
                          note.date.year,
                          note.date.month,
                          note.date.day,
                        ).myanmar,
                        '&M &P &f',
                      ),
                      subtitle: note.preview,
                      chevron: true,
                      onTap: () => GoRouter.of(context).push(
                        '${RoutePaths.views}/${RoutePaths.dayView}',
                        extra: note.date,
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
