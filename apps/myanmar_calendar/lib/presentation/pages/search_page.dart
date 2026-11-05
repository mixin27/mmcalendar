import 'package:events/events.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:holidays/holidays.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:notes/notes.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

/// Search across the app: a date written in Western or Myanmar form,
/// holidays, events and day notes.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.today, this.searchEvents});

  /// Today, for dates without a year and upcoming holidays; now when null.
  final DateTime? today;

  /// Finds events by text; the app's events when null.
  final Future<List<Event>> Function(String query)? searchEvents;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const _maxHolidays = 6;
  static const _maxEvents = 8;
  static const _maxNotes = 8;

  var _query = '';
  var _generation = 0;
  List<Event> _events = const [];
  List<DayNote> _notes = const [];

  DateTime get _today {
    final t = widget.today ?? DateTime.now();
    return DateTime(t.year, t.month, t.day);
  }

  Future<List<Event>> _findEvents(String q) async {
    final search = widget.searchEvents;
    if (search != null) return search(q);
    if (!GetIt.instance.isRegistered<SearchUserEvents>()) return const [];
    final result = await GetIt.instance<SearchUserEvents>()(
      SearchUserEventsParams(q),
    );
    return result.fold((_) => const [], (events) => events);
  }

  Future<void> _changed(String value) async {
    setState(() => _query = value);
    final generation = ++_generation;
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _events = const [];
        _notes = const [];
      });
      return;
    }
    final results = await Future.wait([
      _findEvents(q),
      dayNotes?.search(q) ?? Future.value(const <DayNote>[]),
    ]);
    if (!mounted || generation != _generation) return;
    setState(() {
      _events = results[0] as List<Event>;
      _notes = results[1] as List<DayNote>;
    });
  }

  /// The holidays on [date], then the next occurrence of each holiday
  /// whose name matches, soonest first.
  List<HolidayOccurrence> _holidays(
    AppLocalizations l10n,
    Language language,
    DateTime? date,
  ) {
    final q = _query.trim();
    if (q.isEmpty) return const [];
    final byId = <String, HolidayOccurrence>{};
    if (date != null) {
      for (final o in HolidayYears.of(date.year, language)) {
        if (o.contains(date)) byId[o.entry.id] = o;
      }
    }
    for (final year in [_today.year, _today.year + 1]) {
      for (final o in HolidayYears.of(year, language)) {
        if (o.end.isBefore(_today) || byId.containsKey(o.entry.id)) continue;
        if (HolidaySearch.match(o, q, titles: [o.entry.title(l10n)]) != null) {
          byId[o.entry.id] = o;
        }
      }
    }
    return (byId.values.toList()..sort((a, b) => a.start.compareTo(b.start)))
        .take(_maxHolidays)
        .toList();
  }

  void _openDay(DateTime date) =>
      GoRouter.of(context).push(RoutePaths.dayDetailsInHome(date));

  String _westernDay(CalendarFormat format, DateTime d) =>
      '${format.weekday(d, short: true)} ${format.dayMonth(d)} '
      '${format.westernNumber(d.year)}';

  String _myanmarDay(CalendarFormat format, DateTime d) => format.myanmar(
    MyanmarCalendar.getCompleteDateFor(d.year, d.month, d.day).myanmar,
    '&y &M &P &f',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = context.calendarFormat;
    final t = context.tokens;
    final q = _query.trim();
    final date = q.isEmpty ? null : DateQueryParser.parse(q, today: _today);
    final holidays = _holidays(l10n, context.calendarLanguage, date?.date);
    final events = _events.take(_maxEvents).toList();
    final notes = _notes.take(_maxNotes).toList();
    final nothing =
        q.isNotEmpty &&
        date == null &&
        holidays.isEmpty &&
        events.isEmpty &&
        notes.isEmpty;

    Widget message(String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: t.secondaryLabel, fontSize: 15, height: 1.4),
      ),
    );

    return AppPage(
      title: l10n.searchTitle,
      previousTitle: l10n.home,
      largeTitle: false,
      children: [
        AppSearchField(
          key: const ValueKey('search-field'),
          placeholder: l10n.searchPlaceholder,
          autofocus: true,
          onChanged: _changed,
        ),
        if (q.isEmpty) message(l10n.searchHint),
        if (nothing) message(l10n.searchNoResults(q)),
        if (date != null)
          AppGroup(
            label: l10n.searchDate,
            children: [
              AppRow(
                key: const ValueKey('search-date'),
                icon: Icons.today_rounded,
                iconColor: t.accent,
                title: _westernDay(format, date.date),
                subtitle: _myanmarDay(format, date.date),
                chevron: true,
                onTap: () => _openDay(date.date),
              ),
            ],
          ),
        if (holidays.isNotEmpty)
          AppGroup(
            label: l10n.holidays,
            children: [
              for (final o in holidays)
                AppRow(
                  key: ValueKey('search-holiday-${o.entry.id}'),
                  icon: Icons.star_rounded,
                  iconColor: t.holiday,
                  title: o.entry.title(l10n),
                  subtitle: o.start.year == _today.year
                      ? format.holidayRange(o)
                      : '${format.holidayRange(o)} '
                            '${format.westernNumber(o.start.year)}',
                  chevron: true,
                  onTap: () => GoRouter.of(
                    context,
                  ).push(RoutePaths.holidayInHome(o.entry.id, o.start.year)),
                ),
            ],
          ),
        if (events.isNotEmpty)
          AppGroup(
            label: l10n.events,
            children: [
              for (final e in events)
                AppRow(
                  key: ValueKey('search-event-${e.id}'),
                  icon: Icons.event_outlined,
                  iconColor: Color(e.colorCode ?? e.category.colorCode),
                  title: e.title,
                  subtitle: _westernDay(format, e.eventDate),
                  chevron: true,
                  onTap: () => e.id == null
                      ? _openDay(e.eventDate)
                      : GoRouter.of(
                          context,
                        ).push(RoutePaths.eventsDetail(e.id!)),
                ),
            ],
          ),
        if (notes.isNotEmpty)
          AppGroup(
            label: l10n.notesTitle,
            children: [
              for (final n in notes)
                AppRow(
                  key: ValueKey(
                    'search-note-${DayNotesRepository.keyOf(n.date)}',
                  ),
                  icon: Icons.sticky_note_2_outlined,
                  iconColor: dayNoteColor,
                  title: _westernDay(format, n.date),
                  subtitle: n.preview,
                  chevron: true,
                  onTap: () => _openDay(n.date),
                ),
            ],
          ),
      ],
    );
  }
}
